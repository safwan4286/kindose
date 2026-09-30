import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/logs.dart';
import '../models/user_profile.dart';
import '../resources/catalog.dart';
import '../resources/date_utils.dart';
import '../resources/images.dart';

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

  /// The appointment before [nextAppointment] ("since last visit" reports).
  final Rxn<DateTime> lastAppointment = Rxn<DateTime>();

  /// Questions the user wants printed on the doctor report.
  final RxList<String> reportQuestions = <String>[].obs;

  /// Reminder 3 days before [nextAppointment]. On unless turned off in Me.
  final RxBool visitReminderOn = true.obs;

  /// "Get set up" card closed by the user.
  final RxBool setupDismissed = false.obs;

  /// Today card ids in the user's order, and the ones they hid.
  final RxList<String> todayOrder = <String>[].obs;
  final RxSet<String> todayHidden = <String>{}.obs;

  /// Next dose moved to another day with "Move date". Cleared when a dose
  /// is logged.
  final Rxn<DateTime> nextDoseOverride = Rxn<DateTime>();

  /// Foods the user saved from the Protein screen's custom sheet, newest
  /// first. Kept in the settings box, so cloud backup includes them.
  final RxList<Food> myFoods = <Food>[].obs;

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

    doses.assignAll(
      _doses.values
          .whereType<Map<dynamic, dynamic>>()
          .map(DoseLog.fromMap)
          .whereType<DoseLog>()
          .toList()
        ..sort((a, b) => b.takenAt.compareTo(a.takenAt)),
    );

    final dayMap = <String, DayLog>{};
    for (final v in _days.values.whereType<Map<dynamic, dynamic>>()) {
      final d = DayLog.fromMap(v);
      if (d != null) dayMap[d.key] = d;
    }
    days.assignAll(dayMap);

    weights.assignAll(
      _weights.values
          .whereType<Map<dynamic, dynamic>>()
          .map(WeightEntry.fromMap)
          .whereType<WeightEntry>()
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)),
    );

    themeMode.value = _themeFromString(_settings.get('themeMode'));
    final appt = _settings.get('nextAppointment');
    nextAppointment.value = appt is int
        ? DateTime.fromMillisecondsSinceEpoch(appt)
        : null;
    final lastAppt = _settings.get('lastAppointment');
    lastAppointment.value = lastAppt is int
        ? DateTime.fromMillisecondsSinceEpoch(lastAppt)
        : null;
    final qs = _settings.get('reportQuestions');
    reportQuestions.assignAll(
      qs is List ? qs.whereType<String>() : const <String>[],
    );
    setupDismissed.value = _settings.get('setupDismissed') == true;
    visitReminderOn.value = _settings.get('visitReminderOn') != false;
    final order = _settings.get('todayOrder');
    todayOrder.assignAll(
      order is List ? order.whereType<String>() : const <String>[],
    );
    final hidden = _settings.get('todayHidden');
    todayHidden.assignAll(
      hidden is List ? hidden.whereType<String>() : const <String>[],
    );
    final moved = _settings.get('nextDoseOverride');
    nextDoseOverride.value = moved is int
        ? DateTime.fromMillisecondsSinceEpoch(moved)
        : null;
    final mine = _settings.get(_myFoodsKey);
    myFoods.assignAll(
      mine is List
          ? mine
                .whereType<Map<dynamic, dynamic>>()
                .map(_myFoodFrom)
                .whereType<Food>()
          : const <Food>[],
    );
  }

  // --------------------------------------------------------------- my foods

  static const String _myFoodsKey = 'myFoods';

  static Food? _myFoodFrom(Map<dynamic, dynamic> m) {
    final id = m['id'];
    final name = m['name'];
    final grams = m['grams'];
    if (id is! String ||
        name is! String ||
        name.trim().isEmpty ||
        grams is! int)
      return null;
    final portion = m['portion'];
    return Food(
      id,
      name,
      grams,
      Img3d.bowl,
      portion: portion is String ? portion : '',
      cat: 'mine',
    );
  }

  /// Adds [f], or replaces the saved food with the same id.
  Future<void> saveMyFood(Food f) async {
    final i = myFoods.indexWhere((x) => x.id == f.id);
    if (i >= 0) {
      myFoods[i] = f;
    } else {
      myFoods.insert(0, f);
    }
    await _saveMyFoods();
  }

  Future<void> removeMyFood(String id) async {
    myFoods.removeWhere((x) => x.id == id);
    await _saveMyFoods();
  }

  Future<void> _saveMyFoods() => _settings.put(_myFoodsKey, [
    for (final f in myFoods)
      {'id': f.id, 'name': f.name, 'portion': f.portion, 'grams': f.grams},
  ]);

  Future<void> dismissSetup() async {
    setupDismissed.value = true;
    await _settings.put('setupDismissed', true);
  }

  Future<void> saveTodayLayout(List<String> order, Set<String> hidden) async {
    todayOrder.assignAll(order);
    todayHidden.assignAll(hidden);
    await _settings.put('todayOrder', order);
    await _settings.put('todayHidden', hidden.toList());
  }

  /// "Move date": the next dose happens on [day] (at the usual time).
  Future<void> moveNextDose(DateTime? day) async {
    final d = day == null ? null : Dates.dateOnly(day);
    nextDoseOverride.value = d;
    if (d == null) {
      await _settings.delete('nextDoseOverride');
    } else {
      await _settings.put('nextDoseOverride', d.millisecondsSinceEpoch);
    }
  }

  bool get hasProfile => profile.value != null;

  // ---------------------------------------------------------------- profile

  Future<void> saveProfile(UserProfile p) async {
    await _profile.put(_meKey, p.toMap());
    profile.value = p;
  }

  // ----------------------------------------------------------------- doses

  /// Saves a dose. [medicineId] and [strengthMg] default to the profile,
  /// so pass them only when this dose was different ("Change").
  Future<DoseLog> addDose({
    required DateTime takenAt,
    required String site,
    int? pain,
    String? note,
    String? medicineId,
    double? strengthMg,
  }) async {
    final p = profile.value;
    final log = DoseLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      takenAt: takenAt,
      medicineId: medicineId ?? p?.medicineId ?? '',
      strengthMg: strengthMg ?? p?.strengthMg ?? 0,
      site: site,
      pain: pain,
      note: _cleanNote(note),
    );
    await _doses.put(log.id, log.toMap());
    if (nextDoseOverride.value != null) await moveNextDose(null);
    doses.add(log);
    doses.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return log;
  }

  /// Replaces a saved dose (same id), e.g. "Edit Monday's dose".
  Future<void> updateDose(DoseLog log) async {
    final fixed = log.copyWith(note: () => _cleanNote(log.note));
    await _doses.put(fixed.id, fixed.toMap());
    final i = doses.indexWhere((d) => d.id == fixed.id);
    if (i == -1) {
      doses.add(fixed);
    } else {
      doses[i] = fixed;
    }
    doses.sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  String? _cleanNote(String? note) =>
      (note == null || note.trim().isEmpty) ? null : note.trim();

  Future<void> removeDose(String id) async {
    await _doses.delete(id);
    doses.removeWhere((d) => d.id == id);
  }

  DoseLog? get lastDose => doses.isEmpty ? null : doses.first;

  DoseLog? doseOn(DateTime day) =>
      _firstOrNull(doses, (d) => Dates.sameDay(d.takenAt, day));

  /// Injection doses with a site, newest first.
  Iterable<DoseLog> get siteDoses => doses.where((d) => d.site.isNotEmpty);

  /// The spot used longest ago (never-used spots first).
  String get nextSiteId =>
      Catalog.nextSite(siteDoses.map((d) => d.site).toList());

  String? get lastSiteId => _firstOrNull(siteDoses, (_) => true)?.site;

  /// 1-based position of [id] in the log, oldest = 1.
  int doseNumberOf(String id) {
    final i = doses.indexWhere((d) => d.id == id);
    return i == -1 ? doses.length : doses.length - i;
  }

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
    final planned = p.plannedFirstDose;
    final moved = nextDoseOverride.value;
    if (moved != null &&
        (last == null || moved.isAfter(Dates.dateOnly(last.takenAt)))) {
      return moved.add(Duration(minutes: p.shotMinutes));
    }

    if (last == null &&
        planned != null &&
        !Dates.dateOnly(planned).isBefore(today)) {
      // Starting or restarting: the first dose is on the day they chose.
      day = Dates.dateOnly(planned);
    } else if (p.isDaily) {
      day = (last != null && Dates.sameDay(last.takenAt, now))
          ? today.add(const Duration(days: 1))
          : today;
    } else if (last == null) {
      final ahead = (p.shotWeekday - today.weekday + 7) % 7;
      day = today.add(Duration(days: ahead));
    } else {
      day = _nextDay(last.takenAt, p.everyDays, p.shotWeekday);
    }
    return DateTime(
      day.year,
      day.month,
      day.day,
    ).add(Duration(minutes: p.shotMinutes));
  }

  /// When the next dose would be if one is taken at [takenAt]. Pass
  /// [weekday] to preview a different dose day ("Count from today").
  DateTime? nextDoseAfter(DateTime takenAt, {int? weekday}) {
    final p = profile.value;
    if (p == null) return null;
    final day = p.isDaily
        ? Dates.dateOnly(takenAt).add(const Duration(days: 1))
        : _nextDay(takenAt, p.everyDays, weekday ?? p.shotWeekday);
    return day.add(Duration(minutes: p.shotMinutes));
  }

  /// [everyDays] after [from], snapped to [weekday] for weekly and
  /// two-weekly plans when the dose was a day or three early or late.
  DateTime _nextDay(DateTime from, int everyDays, int weekday) {
    var day = Dates.dateOnly(from).add(Duration(days: everyDays));
    if (everyDays == 7 || everyDays == 14) {
      final shift = (weekday - day.weekday + 7) % 7;
      if (shift != 0 && shift <= 3) {
        day = day.add(Duration(days: shift));
      } else if (shift != 0) {
        day = day.subtract(Duration(days: 7 - shift));
      }
    }
    return day;
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
    // Update memory first so the UI (e.g. a swiped row) changes this frame.
    days[log.key] = log;
    await _days.put(log.key, log.toMap());
  }

  /// Adds protein and remembers the entry (for Today's log and undo).
  /// Returns the entry id.
  Future<String> addProtein(int grams, [DateTime? day, String? label]) =>
      _addEntry('protein', grams, day, label);

  Future<String> addWater(int ml, [DateTime? day, String? label]) =>
      _addEntry('water', ml, day, label);

  Future<String> _addEntry(
    String kind,
    int amount,
    DateTime? day,
    String? label,
  ) async {
    final at = day ?? DateTime.now();
    final d = dayLog(at);
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      at: at,
      kind: kind,
      amount: amount,
      label: label,
    );
    await saveDay(
      d.copyWith(
        proteinG: kind == 'protein' ? math.max(0, d.proteinG + amount) : null,
        waterMl: kind == 'water' ? math.max(0, d.waterMl + amount) : null,
        entries: [...d.entries, entry],
      ),
    );
    return entry.id;
  }

  /// Protein foods the user logs most often, as (name, grams), most used
  /// first. Only entries that came from a named food count.
  List<(String, int)> favouriteFoods([int limit = 2]) {
    final counts = <String, int>{};
    final grams = <String, int>{};
    for (final d in days.values) {
      for (final e in d.entries) {
        final name = e.label;
        if (e.kind != 'protein' || name == null || name.isEmpty) continue;
        counts[name] = (counts[name] ?? 0) + 1;
        grams[name] = e.amount;
      }
    }
    final names = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    return [for (final n in names.take(limit)) (n, grams[n] ?? 0)];
  }

  /// Removes one protein / water entry and takes its amount off the total.
  Future<void> removeEntry(String dayKey, String entryId) async {
    final d = days[dayKey];
    if (d == null) return;
    final e = _firstOrNull(d.entries, (x) => x.id == entryId);
    if (e == null) return;
    await saveDay(
      d.copyWith(
        proteinG: e.isProtein ? math.max(0, d.proteinG - e.amount) : null,
        waterMl: e.isProtein ? null : math.max(0, d.waterMl - e.amount),
        entries: d.entries.where((x) => x.id != entryId).toList(),
      ),
    );
  }

  /// Sets today's water total (glass taps). Going up adds an entry; going
  /// down removes the newest water entries first.
  Future<void> setWater(int ml) async {
    final d = today;
    final target = math.max(0, ml);
    final diff = target - d.waterMl;
    if (diff > 0) {
      await addWater(diff);
      return;
    }
    if (diff == 0) return;
    var toRemove = -diff;
    final entries = [...d.entries];
    for (var i = entries.length - 1; i >= 0 && toRemove > 0; i--) {
      final e = entries[i];
      if (e.isProtein) continue;
      if (e.amount <= toRemove) {
        toRemove -= e.amount;
        entries.removeAt(i);
      } else {
        entries[i] = LogEntry(
          id: e.id,
          at: e.at,
          kind: e.kind,
          amount: e.amount - toRemove,
          label: e.label,
        );
        toRemove = 0;
      }
    }
    await saveDay(d.copyWith(waterMl: target, entries: entries));
  }

  /// Days in a row (ending today, or yesterday if today is still empty)
  /// with anything logged: dose, protein, water, feeling or weight.
  int get logStreak {
    bool active(DateTime day) {
      final d = days[Dates.key(day)];
      if (d != null && (d.proteinG > 0 || d.waterMl > 0 || d.hasCheckIn))
        return true;
      if (doseOn(day) != null) return true;
      return weights.any((w) => Dates.sameDay(w.date, day));
    }

    var day = Dates.dateOnly(DateTime.now());
    if (!active(day)) day = day.subtract(const Duration(days: 1));
    var n = 0;
    while (n < 3650 && active(day)) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  Future<void> setMood(int mood) async {
    await saveDay(today.copyWith(mood: mood));
  }

  // --------------------------------------------------------------- weights

  Future<void> addWeight(double kg, [DateTime? day]) async {
    final entry = WeightEntry(
      date: Dates.dateOnly(day ?? DateTime.now()),
      kg: kg,
    );
    await _weights.put(entry.key, entry.toMap());
    weights.removeWhere((w) => w.key == entry.key);
    weights.add(entry);
    weights.sort((a, b) => a.date.compareTo(b.date));
  }

  double get startWeightKg => weights.isNotEmpty
      ? weights.first.kg
      : (profile.value?.startWeightKg ?? 0);

  double? get latestWeightKg =>
      weights.isNotEmpty ? weights.last.kg : profile.value?.startWeightKg;

  // -------------------------------------------------------------- settings

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _settings.put('themeMode', mode.name);
    Get.changeThemeMode(mode);
  }

  Future<void> setNextAppointment(DateTime? date) async {
    await rollAppointment();
    nextAppointment.value = date;
    if (date == null) {
      await _settings.delete('nextAppointment');
    } else {
      await _settings.put('nextAppointment', date.millisecondsSinceEpoch);
    }
  }

  /// A "next" appointment that has passed becomes the last visit.
  Future<void> rollAppointment() async {
    final next = nextAppointment.value;
    if (next == null ||
        !Dates.dateOnly(next).isBefore(Dates.dateOnly(DateTime.now())))
      return;
    lastAppointment.value = next;
    nextAppointment.value = null;
    reportQuestions.clear();
    await _settings.put('lastAppointment', next.millisecondsSinceEpoch);
    await _settings.delete('nextAppointment');
  }

  Future<void> setVisitReminderOn(bool on) async {
    visitReminderOn.value = on;
    await _settings.put('visitReminderOn', on);
  }

  Future<void> setReportQuestions(List<String> list) async {
    reportQuestions.assignAll(list);
    await _settings.put('reportQuestions', list);
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

  // ---------------------------------------------------------- cloud backup

  static const int backupVersion = 1;

  /// Every saved box as plain JSON, for the cloud backup. Includes the
  /// settings box, so pens, reminders and Today layout come back too.
  Map<String, dynamic> backupData() => {
    'app': 'Kindose',
    'v': backupVersion,
    'savedAt': DateTime.now().toIso8601String(),
    'boxes': {
      _profileBox: _dump(_profile),
      _dosesBox: _dump(_doses),
      _daysBox: _dump(_days),
      _weightsBox: _dump(_weights),
      _settingsBox: _dump(_settings),
    },
  };

  static Map<String, dynamic> _dump(Box<dynamic> box) => {
    for (final k in box.keys) '$k': _plain(box.get(k)),
  };

  /// Hive maps may have non-String keys; JSON needs String keys.
  static Object? _plain(Object? v) => switch (v) {
    Map() => {for (final e in v.entries) '${e.key}': _plain(e.value)},
    List() => [for (final x in v) _plain(x)],
    DateTime() => v.millisecondsSinceEpoch,
    _ => v,
  };

  /// Replaces everything on this phone with a [backupData] copy. Returns
  /// false and changes nothing when it doesn't look like a Kindose backup.
  Future<bool> restoreBackup(Map<String, dynamic> data) async {
    final boxes = data['boxes'];
    if (data['app'] != 'Kindose' || boxes is! Map) return false;
    final profileBox = boxes[_profileBox];
    final me = profileBox is Map ? profileBox[_meKey] : null;
    if (me is! Map || UserProfile.fromMap(me) == null) return false;

    final targets = <String, Box<dynamic>>{
      _profileBox: _profile,
      _dosesBox: _doses,
      _daysBox: _days,
      _weightsBox: _weights,
      _settingsBox: _settings,
    };
    for (final e in targets.entries) {
      final raw = boxes[e.key];
      await e.value.clear();
      if (raw is Map) {
        await e.value.putAll({
          for (final x in raw.entries) '${x.key}': x.value,
        });
      }
    }
    _load();
    Get.changeThemeMode(themeMode.value);
    return true;
  }

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
    lastAppointment.value = null;
    reportQuestions.clear();
    setupDismissed.value = false;
    visitReminderOn.value = true;
    todayOrder.clear();
    todayHidden.clear();
    nextDoseOverride.value = null;
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
