import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../resources/routes.dart';
import '../haptics/haptics.dart';
import '../tracker_service.dart';
import 'plus_access.dart';

/// Free-week rules that can change without an app update (Supabase
/// `app_config` key `access`). Missing or wrong keys use [defaults].
///
/// ```json
/// { "free_days": 7, "start_after_install_days": 7, "gating_on": true }
/// ```
class AccessConfig {
  const AccessConfig({
    required this.freeDays,
    required this.startAfterInstallDays,
    required this.gatingOn,
  });

  /// Length of the free week.
  final int freeDays;

  /// The free week starts at the first dose, or this many days after
  /// install when no dose is logged yet (whichever comes first).
  final int startAfterInstallDays;

  /// False = everything stays open for everyone (a promo week, or if
  /// something goes wrong with purchases).
  final bool gatingOn;

  static const AccessConfig defaults = AccessConfig(
    freeDays: 7,
    startAfterInstallDays: 7,
    gatingOn: true,
  );

  factory AccessConfig.fromJson(Map<dynamic, dynamic> j) {
    int pickInt(String key, int fallback) {
      final v = j[key];
      return (v is num ? v.round() : fallback).clamp(0, 365);
    }

    final gating = j['gating_on'];
    return AccessConfig(
      freeDays: pickInt('free_days', defaults.freeDays),
      startAfterInstallDays: pickInt(
        'start_after_install_days',
        defaults.startAfterInstallDays,
      ),
      gatingOn: gating is bool ? gating : defaults.gatingOn,
    );
  }

  Map<String, dynamic> toJson() => {
    'free_days': freeDays,
    'start_after_install_days': startAfterInstallDays,
    'gating_on': gatingOn,
  };
}

/// Where the user is in the free week, and whether the app is open for
/// them ([PlusAccess.unlocked]).
///
/// Everything is worked out from data that is already backed up (the
/// dose log and the install date in the settings box), so a restore keeps
/// the same end date. The clock can't be set back to stretch the week:
/// the latest time the app has seen is remembered.
class AccessService extends GetxService with WidgetsBindingObserver {
  static const String _installKey = 'installedAt';
  static const String _seenKey = 'clockSeen';
  static const String _configKey = 'accessConfig';

  /// Debug tools only: a start date that replaces the real one.
  static const String _overrideKey = 'freeStartOverride';

  final TrackerService _tracker = Get.find<TrackerService>();
  Box<dynamic> get _settings => Hive.box<dynamic>('settings');

  final Rx<AccessConfig> config = AccessConfig.defaults.obs;

  /// When the free week started (may be in the future when nothing is
  /// logged yet) and ends.
  final Rx<DateTime> startsAt = DateTime.now().obs;
  final Rx<DateTime> endsAt = DateTime.now().obs;

  /// True once the first dose is logged (the week is running).
  final RxBool started = false.obs;

  Timer? _timer;
  Worker? _doses;

  AccessService init() {
    if (_settings.get(_installKey) is! int) {
      _settings.put(_installKey, DateTime.now().millisecondsSinceEpoch);
    }
    final cached = _settings.get(_configKey);
    if (cached is Map) config.value = AccessConfig.fromJson(cached);
    _doses = ever(_tracker.doses, (_) => refresh());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    WidgetsBinding.instance.addObserver(this);
    refresh();
    return this;
  }

  @override
  void onClose() {
    _timer?.cancel();
    _doses?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  DateTime _date(String key) {
    final v = _settings.get(key);
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : DateTime.now();
  }

  /// Now, but never earlier than the latest time already seen.
  DateTime get now {
    final real = DateTime.now();
    final seen = _settings.get(_seenKey);
    if (seen is int && seen > real.millisecondsSinceEpoch) {
      return DateTime.fromMillisecondsSinceEpoch(seen);
    }
    return real;
  }

  DateTime? get _firstDose {
    DateTime? first;
    for (final d in _tracker.doses) {
      if (first == null || d.takenAt.isBefore(first)) first = d.takenAt;
    }
    return first;
  }

  /// Re-checks the week. Called every minute, on resume, when doses change
  /// and when the config changes.
  void refresh() {
    if (_settings.get(_installKey) is! int) {
      _settings.put(_installKey, DateTime.now().millisecondsSinceEpoch);
    }
    final c = config.value;
    final t = now;
    final seen = _settings.get(_seenKey);
    if (seen is! int || t.millisecondsSinceEpoch - seen > const Duration(hours: 1).inMilliseconds) {
      _settings.put(_seenKey, t.millisecondsSinceEpoch);
    }

    final override = kDebugMode ? _settings.get(_overrideKey) : null;
    final first = _firstDose;
    final byInstall = _date(_installKey).add(Duration(days: c.startAfterInstallDays));
    final DateTime start;
    if (override is int) {
      start = DateTime.fromMillisecondsSinceEpoch(override);
    } else if (first != null && first.isBefore(byInstall)) {
      start = first;
    } else {
      start = byInstall;
    }
    startsAt.value = start;
    endsAt.value = start.add(Duration(days: c.freeDays));
    started.value = override is int || first != null || !t.isBefore(byInstall);
    PlusAccess.freeWeek.value = !c.gatingOn || t.isBefore(endsAt.value);
  }

  /// Backend JSON for the `access` key. Bad data is ignored; good data is
  /// kept for offline starts.
  void applyRemote(Object? raw) {
    if (raw is! Map || raw.isEmpty) return;
    try {
      config.value = AccessConfig.fromJson(raw);
      _settings.put(_configKey, config.value.toJson());
      refresh();
    } catch (_) {
      // Keep the current config.
    }
  }

  // ------------------------------------------------------------ reading

  bool get isPlus => PlusAccess.active.value;

  /// The free week is running or hasn't started, and there's no Plus.
  bool get inFreeWeek => !isPlus && PlusAccess.freeWeek.value;

  /// Free week over and no Plus: only the free basics work.
  bool get locked => !PlusAccess.unlocked;

  /// Whole days left, counting today (1 on the last day).
  int get daysLeft {
    final left = endsAt.value.difference(now);
    if (left.isNegative) return 0;
    return (left.inHours / 24).ceil().clamp(1, 365);
  }

  /// 0 → 1 through the week, for the strip on Today.
  double get progress {
    final total = endsAt.value.difference(startsAt.value).inMinutes;
    if (total <= 0 || !started.value) return 0;
    return (now.difference(startsAt.value).inMinutes / total).clamp(0.0, 1.0);
  }

  /// For screens that write data: true when allowed, otherwise opens the
  /// paywall and returns false.
  static bool allow() {
    if (PlusAccess.unlocked) return true;
    Haptics.instance.lightImpact();
    Get.toNamed<void>(Routes.plus);
    return false;
  }

  // ---------------------------------------------------------- debug only

  /// Starts a new free week now (debug builds).
  Future<void> debugRestart() async {
    if (!kDebugMode) return;
    await _settings.put(_overrideKey, DateTime.now().millisecondsSinceEpoch);
    await _settings.delete(_seenKey);
    refresh();
  }

  /// Ends the free week now (debug builds).
  Future<void> debugEnd() async {
    if (!kDebugMode) return;
    final start = DateTime.now().subtract(Duration(days: config.value.freeDays, minutes: 1));
    await _settings.put(_overrideKey, start.millisecondsSinceEpoch);
    refresh();
  }

  /// Back to the real dates (debug builds).
  Future<void> debugClear() async {
    if (!kDebugMode) return;
    await _settings.delete(_overrideKey);
    refresh();
  }
}

/// Sends locked routes to the paywall once the free week is over.
class PlusGate extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      PlusAccess.unlocked ? null : const RouteSettings(name: Routes.plus);
}
