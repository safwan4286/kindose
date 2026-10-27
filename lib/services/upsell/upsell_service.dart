import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../analytics/analytics.dart';
import '../plus/access_service.dart';
import '../plus/plus_access.dart';
import '../tracker_service.dart';

/// Plus prompts during the free week, changeable without an app update
/// (Supabase `app_config` key `upsell`). Missing or wrong keys use
/// [defaults].
///
/// ```json
/// {
///   "enabled": true,
///   "milestones": ["first_dose", "streak_3"],
///   "full_screen_days_left": 2
/// }
/// ```
class UpsellConfig {
  const UpsellConfig({
    required this.enabled,
    required this.milestones,
    required this.fullScreenDaysLeft,
  });

  final bool enabled;

  /// Moments that add a Plus card to the "Dose logged" screen, each shown
  /// once: 'first_dose', 'streak_3'.
  final List<String> milestones;

  /// The Plus screen opens once, after a log, when this many days (or
  /// fewer) of the free week are left. 0 = never.
  final int fullScreenDaysLeft;

  static const UpsellConfig defaults = UpsellConfig(
    enabled: true,
    milestones: ['first_dose', 'streak_3'],
    fullScreenDaysLeft: 2,
  );

  factory UpsellConfig.fromJson(Map<dynamic, dynamic> j) {
    final enabled = j['enabled'];
    final ms = j['milestones'];
    final days = j['full_screen_days_left'];
    return UpsellConfig(
      enabled: enabled is bool ? enabled : defaults.enabled,
      milestones: ms is List
          ? ms.whereType<String>().toList()
          : defaults.milestones,
      fullScreenDaysLeft: days is num
          ? days.round().clamp(0, 30)
          : defaults.fullScreenDaysLeft,
    );
  }
}

/// Decides when to show a Plus prompt in the free week, and remembers
/// what was shown (on this phone). Never more than one prompt a day,
/// never for Plus users, never on a day a severe side effect was logged.
class UpsellService extends GetxService {
  static const String _shownKey = 'upsellShown';
  static const String _lastDayKey = 'upsellLastDay';
  static const String _fullKey = 'upsellFullShown';

  final Rx<UpsellConfig> config = UpsellConfig.defaults.obs;

  Box<dynamic> get _settings => Hive.box<dynamic>('settings');
  TrackerService get _tracker => Get.find<TrackerService>();

  void applyRemote(Object? raw) {
    if (raw is! Map || raw.isEmpty) return;
    try {
      config.value = UpsellConfig.fromJson(raw);
    } catch (_) {
      // Keep the current config.
    }
  }

  List<String> get _shown =>
      (_settings.get(_shownKey) as List?)?.whereType<String>().toList() ??
      const [];

  bool get _shownToday =>
      _settings.get(_lastDayKey) == Dates.key(DateTime.now());

  /// Free week running, no Plus, prompts on, nothing shown yet today,
  /// and today wasn't a rough day.
  bool get _canPrompt {
    if (!config.value.enabled || PlusAccess.active.value) return false;
    if (!Get.isRegistered<AccessService>()) return false;
    final a = Get.find<AccessService>();
    if (!a.config.value.gatingOn || !a.inFreeWeek) return false;
    return !_shownToday && !_roughToday;
  }

  bool get _roughToday {
    final d = _tracker.today;
    return d.nausea == 2 || d.symptomLevels.values.any((l) => l >= 3);
  }

  Future<void> _mark({String? milestone}) async {
    await _settings.put(_lastDayKey, Dates.key(DateTime.now()));
    if (milestone != null) {
      await _settings.put(_shownKey, [..._shown, milestone]);
    }
  }

  /// Days of the free week left (1 on the last day).
  int get daysLeft => Get.find<AccessService>().daysLeft;

  /// The milestone to celebrate on "Dose logged", or null. Counts as
  /// shown, so call once per screen.
  Future<String?> doseDoneCard() async {
    if (!_canPrompt) return null;
    final ms = config.value.milestones;
    final shown = _shown;
    String? hit;
    if (ms.contains('first_dose') &&
        !shown.contains('first_dose') &&
        _tracker.doses.length == 1) {
      hit = 'first_dose';
    } else if (ms.contains('streak_3') &&
        !shown.contains('streak_3') &&
        _tracker.logStreak >= 3) {
      hit = 'streak_3';
    }
    if (hit == null) return null;
    await _mark(milestone: hit);
    Analytics.upsellView(where: 'dose_done', id: hit);
    return hit;
  }

  /// After a log near the end of the free week: opens the Plus screen once.
  /// Returns true when it did.
  Future<bool> afterLog() async {
    final days = config.value.fullScreenDaysLeft;
    if (days <= 0 || !_canPrompt) return false;
    if (_settings.get(_fullKey) == true) return false;
    final a = Get.find<AccessService>();
    if (!a.started.value || a.daysLeft > days) return false;
    await _settings.put(_fullKey, true);
    await _mark();
    Analytics.upsellView(where: 'week_end', id: 'week_end');
    Get.toNamed<void>(Routes.plus);
    return true;
  }

  void tapped(String id) => Analytics.upsellTap(id: id);

  /// Debug: forget every prompt shown.
  Future<void> debugReset() async {
    if (!kDebugMode) return;
    await _settings.delete(_shownKey);
    await _settings.delete(_lastDayKey);
    await _settings.delete(_fullKey);
  }
}
