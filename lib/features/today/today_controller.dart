import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../resources/water_units.dart';
import '../../services/haptics/haptics.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/plus/access_service.dart';
import '../../services/plus/plus_access.dart';
import '../../services/tracker_service.dart';
import '../../widgets/k_ruler.dart';
import '../../widgets/toast.dart';
import '../home/home_controller.dart';
import '../home/weight_sheet.dart';
import '../log_dose/log_dose_controller.dart' show logMissedDose;
import 'next_bite.dart';
import 'weekly_summary.dart';
import 'widgets/next_bite_card.dart';
import '../../widgets/k_date_picker.dart';

/// What the top card shows.
enum DoseCardState {
  /// No medicine chosen yet ("Not decided" in onboarding).
  noMedicine,

  /// Starting soon: first dose is ahead.
  firstDose,

  /// Weekly / every-N-days, next dose in the future.
  upcoming,

  /// Due today, not logged yet.
  doseDay,

  /// Was due on an earlier day, not logged.
  overdue,

  /// Logged today.
  takenToday,

  /// Daily tablet (taken or not shown on the card itself).
  daily,
}

/// Cards the user can reorder or hide with "Edit Today".
class TodayCard {
  const TodayCard(this.id, this.label);

  final String id;
  final String label;

  static const List<TodayCard> all = [
    TodayCard('bite', 'Next bite'),
    TodayCard('protein', 'Protein'),
    TodayCard('water', 'Water'),
    TodayCard('weight', 'Weight'),
    TodayCard('feel', 'How are you feeling'),
    TodayCard('tip', 'Tip for you'),
    TodayCard('log', "Today's log"),
  ];
}

class SetupItem {
  const SetupItem(this.label, this.done, this.onTap);

  final String label;
  final bool done;
  final VoidCallback? onTap;
}

/// One row in "Today's log".
class TodayLogRow {
  const TodayLogRow({
    required this.at,
    required this.title,
    required this.value,
    required this.kind,
    this.entryId,
  });

  final DateTime? at;
  final String title;
  final String value;

  /// 'protein', 'water', 'dose', 'weight' (for the colour dot).
  final String kind;

  /// Set for protein / water rows, which can be swiped away.
  final String? entryId;
}

/// Everything on the Today tab. Values are getters over [TrackerService],
/// so reading them inside `Obx` keeps the screen live.
class TodayController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();

  /// Ticks every 30 s so the countdown and greeting stay current.
  final Rx<DateTime> now = DateTime.now().obs;
  final RxBool busy = false.obs;
  Timer? _ticker;

  /// 250 ml, or 8 fl oz for people who see water in ounces.
  int get glassMl => Water.glassMl;

  @override
  void onInit() {
    super.onInit();
    final hidden = Hive.box<dynamic>('settings').get(_weeklyKey);
    if (hidden is String) weeklyHidden.value = hidden;
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => now.value = DateTime.now(),
    );
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  /// Touch every reactive source the screen depends on (call inside Obx).
  void watch() {
    access.endsAt.value;
    access.started.value;
    now.value;
    tracker.profile.value;
    tracker.doses.length;
    tracker.days.length;
    tracker.weights.length;
    tracker.setupDismissed.value;
    tracker.todayOrder.length;
    tracker.todayHidden.length;
    tracker.nextDoseOverride.value;
    weeklyHidden.value;
    biteAdded.length;
    PlusAccess.unlocked;
  }

  // ------------------------------------------------------------ next bite

  /// "yyyy-MM-dd|ideaId" for ideas added from the card, so a fresh idea
  /// takes their place for the rest of the day.
  final RxSet<String> biteAdded = <String>{}.obs;

  /// Plus shows 3 ideas; free shows 1. Open in debug builds for testing.
  bool get biteUnlocked => PlusAccess.unlocked || kDebugMode;

  NextBite get nextBite {
    final key = Dates.key(now.value);
    final skip = {
      for (final k in biteAdded)
        if (k.startsWith('$key|')) k.substring(key.length + 1),
    };
    return NextBite.build(tracker, now.value, skip: skip);
  }

  Future<void> addBite(BiteIdea idea) async {
    if (!AccessService.allow()) return;
    Haptics.instance.lightImpact();
    final key = Dates.key(now.value);
    final entryId = await tracker.addProtein(idea.grams, null, idea.label);
    final tag = '$key|${idea.id}';
    biteAdded.add(tag);
    showUndoToast('Added ${idea.name} · ${idea.grams} g', () async {
      await tracker.removeEntry(key, entryId);
      biteAdded.remove(tag);
    });
  }

  /// A removed entry that came from Next bite lets that idea come back.
  void forgetBite(String? label) {
    if (label == null) return;
    final key = Dates.key(now.value);
    for (final i in NextBite.pool) {
      if (i.label == label) biteAdded.remove('$key|${i.id}');
    }
  }

  void showBiteWhy(NextBite b) {
    Haptics.instance.selectionClick();
    showBiteWhySheet(b);
  }

  void openPlusFromBite() {
    Haptics.instance.lightImpact();
    Get.toNamed<void>(Routes.plus);
  }

  // ---------------------------------------------------------- weekly card

  static const String _weeklyKey = 'weeklyHidden';

  /// Monday key of the last weekly card the user hid.
  final RxString weeklyHidden = ''.obs;

  /// Last week in short, or null (not enough logged, or already hidden).
  WeeklySummary? get weekly {
    final s = WeeklySummary.build(tracker, now.value);
    if (s == null || s.key == weeklyHidden.value) return null;
    return s;
  }

  void dismissWeekly() {
    final s = WeeklySummary.build(tracker, now.value);
    if (s == null) return;
    Haptics.instance.lightImpact();
    weeklyHidden.value = s.key;
    Hive.box<dynamic>('settings').put(_weeklyKey, s.key);
  }

  void openProgressFromWeekly() {
    Haptics.instance.selectionClick();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().select(HomeTab.progress);
    }
  }

  UserProfile? get profile => tracker.profile.value;
  DayLog get day => tracker.dayLog(now.value);
  String get greeting => Dates.greeting(now.value);
  String get dateLine =>
      '${Dates.weekdayName(now.value.weekday)}, ${Dates.short(now.value)}'
          .toUpperCase();
  int get streak => tracker.logStreak;

  // ------------------------------------------------------------------ dose

  bool get isTablet => profile?.form == 'tablet';
  DateTime? get nextDoseAt => tracker.nextDoseAt(now.value);
  DoseLog? get doseToday => tracker.doseOn(now.value);

  String get medicineName {
    final p = profile;
    if (p == null) return '';
    return Catalog.medicineName(p.medicineId, p.customMedicine);
  }

  String? get medicineMark =>
      profile == null ? null : Catalog.medicine(profile!.medicineId).mark;

  String get doseLabel {
    final p = profile;
    if (p == null || p.strengthMg <= 0) return '';
    return Catalog.mgLabel(p.strengthMg);
  }

  /// "Week 16" since treatment start (or first dose).
  int? get treatmentWeek {
    final start =
        profile?.treatmentStartedAt ??
        (tracker.doses.isEmpty ? null : tracker.doses.last.takenAt);
    if (start == null || start.isAfter(now.value)) return null;
    return Dates.daysBetween(start, now.value) ~/ 7 + 1;
  }

  /// Number of this dose in the log (the one about to be taken).
  int get doseNumber => tracker.doses.length + 1;

  DoseCardState get doseState {
    final p = profile;
    if (p == null || p.medicineId == Catalog.undecided)
      return DoseCardState.noMedicine;
    if (p.isDaily) return DoseCardState.daily;
    if (doseToday != null) return DoseCardState.takenToday;
    final next = nextDoseAt;
    if (next == null) return DoseCardState.noMedicine;
    final today = Dates.dateOnly(now.value);
    final nextDay = Dates.dateOnly(next);
    if (nextDay.isBefore(today)) return DoseCardState.overdue;
    if (nextDay == today) return DoseCardState.doseDay;
    if (tracker.doses.isEmpty) return DoseCardState.firstDose;
    return DoseCardState.upcoming;
  }

  int get daysUntilNext {
    final next = nextDoseAt;
    return next == null ? 0 : Dates.daysBetween(now.value, next);
  }

  String get countdownLabel {
    final d = daysUntilNext;
    if (d <= 0) return 'today';
    if (d == 1) return 'tomorrow';
    return 'in $d days';
  }

  String get nextDoseWhen {
    final next = nextDoseAt;
    final p = profile;
    if (next == null || p == null) return '';
    return '${Dates.weekdayName(next.weekday)} · ${Dates.timeOfDay(p.shotMinutes)}';
  }

  String get doseTime => Dates.timeOfDay(profile?.shotMinutes ?? 480);

  String get nextSiteName => Catalog.siteName(tracker.nextSiteId);
  String get nextSiteId => tracker.nextSiteId;
  String siteName(String id) => Catalog.siteName(id);
  String timeOf(DateTime t) => Dates.time(t);
  String? get lastSiteName =>
      tracker.lastSiteId == null ? null : Catalog.siteName(tracker.lastSiteId!);

  /// 7 cells ending on the next dose day: 'done', 'today', 'dose', ''.
  List<(String letter, String state)> get weekStrip {
    final next = nextDoseAt;
    final today = Dates.dateOnly(now.value);
    final end = next == null
        ? today.add(const Duration(days: 6))
        : Dates.dateOnly(next);
    final start = end.subtract(const Duration(days: 6));
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = start.add(Duration(days: i));
          final letter = Dates.weekdayName(d.weekday).substring(0, 1);
          if (tracker.doseOn(d) != null) return (letter, 'done');
          if (d == end) return (letter, 'dose');
          if (d == today) return (letter, 'today');
          return (letter, '');
        }(),
    ];
  }

  /// Last 7 days for a daily tablet: 'done', 'today', 'missed'.
  List<(String letter, String state)> get dailyStrip {
    final today = Dates.dateOnly(now.value);
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final d = today.subtract(Duration(days: i));
          final letter = Dates.weekdayName(d.weekday).substring(0, 1);
          if (tracker.doseOn(d) != null) return (letter, 'done');
          return (letter, i == 0 ? 'today' : 'missed');
        }(),
    ];
  }

  Future<void> logDose() async {
    Haptics.instance.lightImpact();
    await Get.toNamed<void>(Routes.logDose);
  }

  /// "Walk me through it" on the dose-day card, for people who said
  /// injections make them nervous.
  bool get showGuideLink =>
      !isTablet && (profile?.focus.contains('nerves') ?? false);

  Future<void> openGuide() async {
    Haptics.instance.lightImpact();
    await Get.toNamed<void>(Routes.guide);
  }

  /// One-tap "Taken" is for tablets only. Daily injections open Log dose,
  /// so the injection spot is recorded and rotation keeps working.
  Future<void> markTaken() async {
    if (!AccessService.allow()) return;
    if (!isTablet) {
      await logDose();
      return;
    }
    if (busy.value) return;
    busy.value = true;
    try {
      await tracker.addDose(takenAt: DateTime.now(), site: '');
      Haptics.instance.mediumImpact();
    } finally {
      busy.value = false;
    }
  }

  /// Removes today's dose; Undo puts the same record back (same id, so
  /// Pens & cost counts it again).
  Future<void> undoDoseToday() async {
    final d = doseToday;
    if (d == null) return;
    Haptics.instance.selectionClick();
    await tracker.removeDose(d.id);
    showUndoToast('Dose removed', () => tracker.updateDose(d));
  }

  // ------------------------------------------------ after a dose is logged

  /// "Undo" stays on the card for 10 minutes after logging (a quick fix
  /// for a mis-tap); after that the card shows "⋯" with all the options.
  bool get canQuickUndo {
    final d = doseToday;
    if (d == null) return false;
    final us = int.tryParse(d.id);
    final logged = us == null
        ? d.takenAt
        : DateTime.fromMicrosecondsSinceEpoch(us);
    return now.value.difference(logged) < const Duration(minutes: 10);
  }

  /// "Next: Sun, 12 Oct · 8:00 AM" on the logged card.
  String get nextDoseLine {
    final next = nextDoseAt;
    final p = profile;
    if (next == null || p == null) return '';
    return '${Dates.shortWithDay(next)} · ${Dates.timeOfDay(p.shotMinutes)}';
  }

  /// Tap on the logged card: edit time, spot, strength, how it felt, note.
  void editDoseToday() {
    final d = doseToday;
    if (d == null) return;
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.logDose, arguments: d);
  }

  /// A dose from an earlier day that wasn't logged (past only).
  void logMissedDose() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.logDose, arguments: logMissedDose);
  }

  Future<void> moveDate(BuildContext context) async {
    Haptics.instance.selectionClick();
    final today = Dates.dateOnly(now.value);
    // Once today's dose is logged, the next one can't also be today.
    final first = doseToday == null
        ? today
        : today.add(const Duration(days: 1));
    final current = nextDoseAt;
    final picked = await showKDatePicker(
      context: context,
      initialDate: current == null || current.isBefore(first)
          ? first
          : Dates.dateOnly(current),
      firstDate: first,
      lastDate: today.add(const Duration(days: 21)),
      title: 'Move this dose to',
      note: 'Only the reminder moves. Check your leaflet or doctor if unsure.',
    );
    if (picked == null) return;
    await tracker.moveNextDose(picked);
    showToast('Next dose moved to ${Dates.shortWithDay(picked)}');
  }

  void chooseMedicine() => Get.toNamed<void>(Routes.editPlan);

  // --------------------------------------------------------------- protein

  int get proteinGoal => profile?.proteinGoalG ?? 100;
  int get proteinLeft => (proteinGoal - day.proteinG).clamp(0, 999);
  double get proteinProgress =>
      proteinGoal == 0 ? 0 : (day.proteinG / proteinGoal).clamp(0.0, 1.0);
  List<Food> get quickFoods => Catalog.quickFoods(profile?.diet);

  Future<void> addProtein(int grams, [String? label]) async {
    if (!AccessService.allow()) return;
    Haptics.instance.lightImpact();
    await tracker.addProtein(grams, null, label);
    showToast(
      label == null ? 'Added $grams g protein' : 'Added $label · $grams g',
    );
  }

  void openProtein() =>
      Get.toNamed<void>(Routes.addIntake, arguments: 'protein');

  // ----------------------------------------------------------------- water

  int get waterGoal => profile?.waterGoalMl ?? 2500;

  /// Glasses shown: enough for the goal, and always one more empty "+"
  /// glass so days above the goal can be logged too (6 per row, max 4 rows).
  int get glassCount {
    final goal = (waterGoal / glassMl).ceil().clamp(4, 18);
    return (glassesFull + 1 > goal ? glassesFull + 1 : goal).clamp(4, 24);
  }

  /// Glasses that make up the goal ("5 of 12 glasses").
  int get glassesGoal => (waterGoal / glassMl).ceil().clamp(1, 99);

  double get waterProgress =>
      waterGoal <= 0 ? 0 : (day.waterMl / waterGoal).clamp(0.0, 1.0);

  bool get waterGoalHit => day.waterMl >= waterGoal;

  void openWater() => Get.toNamed<void>(Routes.addIntake, arguments: 'water');

  /// Today's date line opens the day view (with its calendar).
  void openDay() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.day);
  }

  int get glassesFull => (day.waterMl / glassMl).floor();

  /// Number only ("1.25" or "42"); the unit is [Water.unit].
  String get litres => Water.total(day.waterMl);
  String get waterGoalLitres => Water.total(waterGoal);

  /// Tap an empty glass to fill up to it; tap the last full one to empty it.
  void tapGlass(int i) {
    if (!AccessService.allow()) return;
    final full = glassesFull;
    final ml = (i == full - 1) ? i * glassMl : (i + 1) * glassMl;
    if (ml > day.waterMl) {
      Haptics.instance.lightImpact();
    } else {
      Haptics.instance.selectionClick();
    }
    tracker.setWater(ml);
  }

  // ---------------------------------------------------------------- weight

  bool get useKg => profile?.useKg ?? true;
  String get unit => useKg ? 'kg' : 'lb';
  String fmtWeight(double kg) => useKg
      ? kg.toStringAsFixed(1)
      : (kg * Imperial.lbPerKg).toStringAsFixed(0);

  double? get latestKg => tracker.latestWeightKg;
  double get startKg => tracker.startWeightKg;
  double? get goalKg => profile?.goalWeightKg;

  /// 0–1 of the way from start to goal (0 without a goal).
  double get goalProgress {
    final g = goalKg;
    final now = latestKg;
    if (g == null || now == null || (startKg - g).abs() < 0.1) return 0;
    return ((startKg - now) / (startKg - g)).clamp(0.0, 1.0);
  }

  String get changeSinceStart {
    final now = latestKg;
    if (now == null) return '';
    final diff = now - startKg;
    if (diff.abs() < 0.05) return 'Same as your start';
    final amount = useKg
        ? diff.abs().toStringAsFixed(1)
        : (diff.abs() * Imperial.lbPerKg).toStringAsFixed(1);
    return '${diff < 0 ? '−' : '+'}$amount $unit since start';
  }

  String get lastWeighIn {
    if (tracker.weights.isEmpty) return 'No weigh-in yet';
    final days = Dates.daysBetween(tracker.weights.last.date, now.value);
    if (days <= 0) return 'Weighed today';
    if (days == 1) return 'Weighed yesterday';
    return 'Weighed $days days ago';
  }

  void logWeight() {
    Haptics.instance.selectionClick();
    showWeightSheet();
  }

  // ------------------------------------------------------------------ feel

  /// Faces left to right: Rough … Great (Catalog.moods is Great … Rough).
  /// The check-in screen shows them in the same order with the same words.
  static final List<String> faceLabels = [
    for (final m in Catalog.moods.reversed) m.label,
  ];
  int? get selectedFace => day.mood == null ? null : 4 - day.mood!;

  String get feelNote {
    final last = tracker.lastDose;
    if (last == null || isTablet || (profile?.isDaily ?? false)) return '';
    final d = Dates.daysBetween(last.takenAt, now.value);
    if (d == 0) return 'Dose day';
    return 'Day $d after dose';
  }

  Future<void> pickFace(int face) async {
    if (!AccessService.allow()) return;
    Haptics.instance.selectionClick();
    await tracker.setMood(4 - face);
  }

  void openCheckIn() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.checkIn);
  }

  // ------------------------------------------------------------------- tip

  (String title, String text) get tip {
    final dayIndex = now.value.difference(DateTime(now.value.year)).inDays;
    final state = doseState;
    if (state == DoseCardState.doseDay || state == DoseCardState.takenToday) {
      return (
        'DOSE DAY TIP',
        Catalog.doseDayTips[dayIndex % Catalog.doseDayTips.length],
      );
    }
    final focus = (profile?.focus ?? const <String>[])
        .where(Catalog.tips.containsKey)
        .toList();
    final key = focus.isEmpty ? 'muscle' : focus[dayIndex % focus.length];
    final list = Catalog.tips[key]!;
    final title = switch (key) {
      'muscle' => 'FOR YOUR MUSCLE',
      'nausea' => 'EASIER ON YOUR STOMACH',
      'noise' => 'QUIETER FOOD NOISE',
      'remember' => 'NEVER MISS A DOSE',
      'nerves' => 'CALMER DOSE DAYS',
      'progress' => 'SEEING PROGRESS',
      _ => 'GOOD TO KNOW',
    };
    return (title, list[dayIndex % list.length]);
  }

  /// Icon for the tip card (focus → 3D image), chosen in the widget.
  String get tipFocus {
    final state = doseState;
    if (state == DoseCardState.doseDay || state == DoseCardState.takenToday)
      return 'nausea';
    final focus = (profile?.focus ?? const <String>[])
        .where(Catalog.tips.containsKey)
        .toList();
    if (focus.isEmpty) return 'muscle';
    return focus[now.value.difference(DateTime(now.value.year)).inDays %
        focus.length];
  }

  // ------------------------------------------------------------- today log

  List<TodayLogRow> get logRows {
    final rows = <TodayLogRow>[
      for (final e in day.entries)
        TodayLogRow(
          at: e.at,
          title: e.isProtein
              ? 'Protein${e.label == null ? '' : ' · ${e.label}'}'
              : 'Water',
          value: e.isProtein ? '+${e.amount} g' : '+${Water.amount(e.amount)}',
          kind: e.kind,
          entryId: e.id,
        ),
    ];
    final dose = doseToday;
    if (dose != null) {
      final site = dose.site.isEmpty ? '' : ' · ${Catalog.siteName(dose.site)}';
      rows.add(
        TodayLogRow(
          at: dose.takenAt,
          title: 'Dose$site',
          value: doseLabel.isEmpty ? '✓' : doseLabel,
          kind: 'dose',
        ),
      );
    }
    final weighIn = tracker.weights.where(
      (w) => Dates.sameDay(w.date, now.value),
    );
    if (weighIn.isNotEmpty) {
      rows.add(
        TodayLogRow(
          at: null,
          title: 'Weigh-in',
          value: '${fmtWeight(weighIn.last.kg)} $unit',
          kind: 'weight',
        ),
      );
    }
    rows.sort((a, b) => (a.at ?? DateTime(0)).compareTo(b.at ?? DateTime(0)));
    return rows;
  }

  Future<void> removeRow(TodayLogRow row) async {
    final id = row.entryId;
    if (id == null) return;
    if (!AccessService.allow()) return;
    Haptics.instance.mediumImpact();
    await tracker.removeEntry(day.key, id);
    showToast('${row.title} removed');
  }

  // ----------------------------------------------------------- set-up card

  List<SetupItem> get setupItems => [
    SetupItem(
      'Log your starting weight',
      tracker.weights.isNotEmpty,
      logWeight,
    ),
    SetupItem(
      isTablet ? 'Log your first tablet' : 'Log your first dose',
      tracker.doses.isNotEmpty,
      () => Get.toNamed<void>(Routes.logDose),
    ),
    SetupItem(
      'Add your first protein',
      tracker.days.values.any((d) => d.proteinG > 0),
      openProtein,
    ),
    SetupItem(
      'Turn on reminders',
      profile?.remindersOn ?? false,
      turnOnReminders,
    ),
  ];

  bool get showSetup =>
      !locked &&
      !tracker.setupDismissed.value &&
      setupItems.any((i) => !i.done);

  // ------------------------------------------------------------ free week

  AccessService get access => Get.find<AccessService>();

  /// Free week over and no Plus. Today stays fully visible (6 Oct
  /// decision); actions open the paywall through [AccessService.allow].
  bool get locked => access.locked;

  bool get showFreeStrip =>
      access.inFreeWeek && access.started.value && access.config.value.gatingOn;
  int get setupDone => setupItems.where((i) => i.done).length;

  Future<void> dismissSetup() async {
    Haptics.instance.selectionClick();
    await tracker.dismissSetup();
  }

  Future<void> turnOnReminders() async {
    final p = profile;
    if (p == null) return;
    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      showToast('Allow notifications for Kindose in your phone settings.');
      return;
    }
    Haptics.instance.mediumImpact();
    await tracker.saveProfile(p.copyWith(remindersOn: true));
    showToast('Reminders are on');
  }

  // ------------------------------------------------------------ edit today

  /// Card ids in display order, without the hidden ones.
  /// Until the user arranges Today themselves, cards that match their
  /// goals from onboarding come first.
  List<String> get cardOrder {
    final saved = tracker.todayOrder
        .where((id) => TodayCard.all.any((c) => c.id == id))
        .toList();
    final base = saved.isEmpty ? _goalOrder : saved;
    final missing = TodayCard.all
        .map((c) => c.id)
        .where((id) => !base.contains(id) && id != 'bite');
    // Next bite is new: put it first for layouts saved before it existed.
    return [if (!base.contains('bite')) 'bite', ...base, ...missing];
  }

  /// Onboarding goal → the Today card that helps with it.
  static const Map<String, String> _goalCard = {
    'muscle': 'protein',
    'progress': 'weight',
    'nausea': 'feel',
    'noise': 'feel',
  };

  /// Goal cards first (in the order the goals were picked), then the rest
  /// in the usual order. Water stays right after protein.
  List<String> get _goalOrder {
    final picked = <String>[];
    for (final goal in profile?.focus ?? const <String>[]) {
      final id = _goalCard[goal];
      if (id == null || picked.contains(id)) continue;
      picked.add(id);
      if (id == 'protein') picked.add('water');
    }
    // Next bite always leads; it adapts to the day by itself.
    return [
      'bite',
      ...picked,
      for (final c in TodayCard.all)
        if (!picked.contains(c.id) && c.id != 'bite') c.id,
    ];
  }

  /// Hidden cards. Next bite already shows protein progress and quick
  /// adds, so the Protein card starts hidden until the user saves their own
  /// layout (it's still there in Edit Today).
  Set<String> get hiddenCards {
    final saved = tracker.todayOrder;
    if (saved.isEmpty || !saved.contains('bite')) {
      return {...tracker.todayHidden, 'protein'};
    }
    return tracker.todayHidden.toSet();
  }

  List<String> get visibleCards =>
      cardOrder.where((id) => !hiddenCards.contains(id)).toList();

  Future<void> saveLayout(List<String> order, Set<String> hidden) async {
    Haptics.instance.lightImpact();
    await tracker.saveTodayLayout(order, hidden);
  }
}
