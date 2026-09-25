import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/logs.dart';
import '../models/user_profile.dart';
import '../resources/catalog.dart';
import '../resources/date_utils.dart';

/// Single source of truth for everything the user logs.
///
/// All data lives on the phone in Hive boxes. Screens read the reactive
/// fields below and call the methods to change them, so every screen stays
/// in sync without passing data around.
class TrackerService extends GetxService {
  static const String _profileBox = 'profile';
  static const String _dosesBox = 'doses';
  static const String _daysBox = 'days';
  static const String _weightsBox = 'weights';
  static const String _settingsBox = 'settings';
  static const String _meKey = 'me';

  late Box<dynamic> _profile;
  late Box<dynamic> _doses;
  late Box<dynamic> _days;
  late Box<dynamic> _weights;
  late Box<dynamic> _settings;

  final Rxn<UserProfile> profile = Rxn<UserProfile>();

  /// Newest first.
  final RxList<DoseLog> doses = <DoseLog>[].obs;
  final RxMap<String, DayLog> days = <String, DayLog>{}.obs;

  /// Oldest first.
  final RxList<WeightEntry> weights = <WeightEntry>[].obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rxn<DateTime> nextAppointment = Rxn<DateTime>();

  Future<TrackerService> init() async {
    await Hive.initFlutter();
    _profile = await Hive.openBox<dynamic>(_profileBox);
    _doses = await Hive.openBox<dynamic>(_dosesBox);
    _days = await Hive.openBox<dynamic>(_daysBox);
    _weights = await Hive.openBox<dynamic>(_weightsBox);
    _settings = await Hive.openBox<dynamic>(_settingsBox);
    _load();
    return this;
  }

  void _load() {
    final raw = _profile.get(_meKey);
    profile.value = raw is Map ? UserProfile.fromMap(raw) : null;

    doses.assignAll(_doses.values
        .whereType<Map<dynamic, dynamic>>()
        .map(DoseLog.fromMap)
        .whereType<DoseLog>()
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt)));

    final dayMap = <String, DayLog>{};
    for (final v in _days.values.whereType<Map<dynamic, dynamic>>()) {
      final d = DayLog.fromMap(v);
      if (d != null) dayMap[d.key] = d;
    }
    days.assignAll(dayMap);

    weights.assignAll(_weights.values
        .whereType<Map<dynamic, dynamic>>()
        .map(WeightEntry.fromMap)
        .whereType<WeightEntry>()
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)));

    themeMode.value = _themeFromString(_settings.get('themeMode'));
    final appt = _settings.get('nextAppointment');
    nextAppointment.value =
        appt is int ? DateTime.fromMillisecondsSinceEpoch(appt) : null;
  }

  bool get hasProfile => profile.value != null;

  // ---------------------------------------------------------------- profile

  Future<void> saveProfile(UserProfile p) async {
    await _profile.put(_meKey, p.toMap());
    profile.value = p;
  }

  // ----------------------------------------------------------------- doses

  Future<DoseLog> addDose({
    required DateTime takenAt,
    required String site,
    int pain = 0,
    String? note,
  }) async {
    final p = profile.value;
    final log = DoseLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      takenAt: takenAt,
      medicineId: p?.medicineId ?? '',
      strengthMg: p?.strengthMg ?? 0,
      site: site,
      pain: pain,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );
    await _doses.put(log.id, log.toMap());
    doses.add(log);
    doses.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return log;
  }

  Future<void> removeDose(String id) async {
    await _doses.delete(id);
    doses.removeWhere((d) => d.id == id);
  }

  DoseLog? get lastDose => doses.isEmpty ? null : doses.first;

  DoseLog? doseOn(DateTime day) =>
      _firstOrNull(doses, (d) => Dates.sameDay(d.takenAt, day));

  String get nextSiteId => Catalog.nextSite(
      _firstOrNull(doses, (d) => d.site.isNotEmpty)?.site);

  String? get lastSiteId => _firstOrNull(doses, (d) => d.site.isNotEmpty)?.site;

  /// When the next dose is due, including the planned time of day.
  /// If a planned dose was missed, this returns that past date so the app
  /// can show it as due.
  DateTime? nextDoseAt([DateTime? nowArg]) {
    final p = profile.value;
    if (p == null) return null;
    final now = nowArg ?? DateTime.now();
    final today = Dates.dateOnly(now);
    final last = lastDose;
    DateTime day;

    if (p.isDaily) {
      day = (last != null && Dates.sameDay(last.takenAt, now))
          ? today.add(const Duration(days: 1))
          : today;
    } else if (last == null) {
      final ahead = (p.shotWeekday - today.weekday + 7) % 7;
      day = today.add(Duration(days: ahead));
    } else {
      day = Dates.dateOnly(last.takenAt).add(Duration(days: p.everyDays));
      if (p.everyDays == 7 || p.everyDays == 14) {
        // Snap to the chosen shot day if the user logged a day early or late.
        final shift = (p.shotWeekday - day.weekday + 7) % 7;
        if (shift != 0 && shift <= 3) {
          day = day.add(Duration(days: shift));
        } else if (shift != 0) {
          day = day.subtract(Duration(days: 7 - shift));
        }
      }
    }
    return DateTime(day.year, day.month, day.day)
        .add(Duration(minutes: p.shotMinutes));
  }

  /// True when a dose is due today (or overdue) and not yet logged today.
  bool isDoseDay([DateTime? nowArg]) {
    final now = nowArg ?? DateTime.now();
    final next = nextDoseAt(now);
    if (next == null) return false;
    return !Dates.dateOnly(next).isAfter(Dates.dateOnly(now)) &&
        doseOn(now) == null;
  }

  /// How many doses in a row were taken within a day of plan.
  int get onTimeStreak {
    final p = profile.value;
    if (p == null || doses.isEmpty) return 0;
    var streak = 1;
    for (var i = 0; i < doses.length - 1; i++) {
      final gap = Dates.daysBetween(doses[i + 1].takenAt, doses[i].takenAt);
      if ((gap - p.everyDays).abs() <= 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ------------------------------------------------------------------ days

  DayLog dayLog(DateTime day) {
    final key = Dates.key(day);
    return days[key] ?? DayLog.empty(key);
  }

  DayLog get today => dayLog(DateTime.now());

  Future<void> saveDay(DayLog log) async {
    await _days.put(log.key, log.toMap());
    days[log.key] = log;
  }

  Future<void> addProtein(int grams, [DateTime? day]) async {
    final d = dayLog(day ?? DateTime.now());
    await saveDay(d.copyWith(proteinG: math.max(0, d.proteinG + grams)));
  }

  Future<void> addWater(int ml, [DateTime? day]) async {
    final d = dayLog(day ?? DateTime.now());
    await saveDay(d.copyWith(waterMl: math.max(0, d.waterMl + ml)));
  }

  Future<void> setWater(int ml) async {
    await saveDay(today.copyWith(waterMl: math.max(0, ml)));
  }

  Future<void> setMood(int mood) async {
    await saveDay(today.copyWith(mood: mood));
  }

  // --------------------------------------------------------------- weights

  Future<void> addWeight(double kg, [DateTime? day]) async {
    final entry = WeightEntry(date: Dates.dateOnly(day ?? DateTime.now()), kg: kg);
    await _weights.put(entry.key, entry.toMap());
    weights.removeWhere((w) => w.key == entry.key);
    weights.add(entry);
    weights.sort((a, b) => a.date.compareTo(b.date));
  }

  double get startWeightKg =>
      weights.isNotEmpty ? weights.first.kg : (profile.value?.startWeightKg ?? 0);

  double? get latestWeightKg =>
      weights.isNotEmpty ? weights.last.kg : profile.value?.startWeightKg;

  // -------------------------------------------------------------- settings

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _settings.put('themeMode', mode.name);
    Get.changeThemeMode(mode);
  }

  Future<void> setNextAppointment(DateTime? date) async {
    nextAppointment.value = date;
    if (date == null) {
      await _settings.delete('nextAppointment');
    } else {
      await _settings.put('nextAppointment', date.millisecondsSinceEpoch);
    }
  }

  ThemeMode _themeFromString(dynamic v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Everything as plain data, for the user's own export.
  Map<String, dynamic> exportAll() => {
        'app': 'Kindose',
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': profile.value?.toMap(),
        'doses': doses.map((d) => d.toMap()).toList(),
        'days': days.values.map((d) => d.toMap()).toList(),
        'weights': weights.map((w) => w.toMap()).toList(),
      };

  /// Permanently removes every record on this phone.
  Future<void> deleteAll() async {
    await Future.wait([
      _profile.clear(),
      _doses.clear(),
      _days.clear(),
      _weights.clear(),
      _settings.clear(),
    ]);
    profile.value = null;
    doses.clear();
    days.clear();
    weights.clear();
    nextAppointment.value = null;
    themeMode.value = ThemeMode.system;
    Get.changeThemeMode(ThemeMode.system);
  }
}

T? _firstOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
