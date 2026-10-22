import 'dart:math' as math;

import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/bmi.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/feel_pattern.dart';
import '../../resources/routes.dart';
import '../../resources/water_units.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/plus_access.dart';
import '../../services/tracker_service.dart';
import '../../widgets/k_ruler.dart';
import '../home/home_controller.dart';
import '../home/weight_sheet.dart';

enum ProgressRange { month, quarter, all }

/// One bar in a 7-day chart.
class DayBar {
  const DayBar({required this.date, required this.value, required this.goal});

  final DateTime date;
  final double value;
  final double goal;

  bool get hit => goal > 0 && value >= goal;
}

/// A dose change drawn on the weight chart ("5 mg from here").
class DoseMarker {
  const DoseMarker(this.date, this.label);

  final DateTime date;
  final String label;
}

/// One cell of the "How you felt" grid. [level] is -1 for no check-in,
/// 0 fine, 1 mild, 2 moderate, 3 severe. [inFuture] cells are blank.
class FeelCell {
  const FeelCell({
    required this.date,
    required this.level,
    required this.doseDay,
    required this.inFuture,
  });

  final DateTime date;
  final int level;
  final bool doseDay;
  final bool inFuture;
}

/// Progress tab. Every number is simple arithmetic on what the user logged;
/// nothing is predicted.
class ProgressController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final Rx<ProgressRange> range = ProgressRange.month.obs;

  /// Tapped weigh-in on the chart (index into [points]); -1 = latest.
  final RxInt selected = (-1).obs;

  void watch() {
    tracker.weights.length;
    tracker.doses.length;
    tracker.days.length;
    tracker.profile.value;
    tracker.nextDoseOverride.value; // "Move date" changes the next dose
    range.value;
    selected.value;
    feelPage.value;
    PlusAccess.unlocked;
  }

  // ------------------------------------------------------------ feel paging

  /// How many 4-week periods back the "How you felt" grid shows (0 = now).
  final RxInt feelPage = 0.obs;

  /// Monday of the first week in the period shown.
  DateTime get feelStart {
    final today = Dates.dateOnly(DateTime.now());
    final monday = Dates.addDays(today, -(today.weekday - 1));
    return Dates.addDays(monday, -21 - 28 * feelPage.value);
  }

  DateTime get feelEnd => Dates.addDays(feelStart, 27);

  /// "28 Sep – 25 Oct".
  String get feelRange => '${Dates.short(feelStart)} – ${Dates.short(feelEnd)}';

  /// Free history is the last 28 days, which the current period covers;
  /// earlier periods need Plus.
  bool get feelLocked => feelPage.value > 0 && !PlusAccess.unlocked;

  /// Older periods while there is any log before them (or one locked step).
  bool get canFeelBack {
    if (feelLocked) return false;
    final first = tracker.days.keys.isEmpty && tracker.doses.isEmpty
        ? null
        : _firstLogDay;
    return first != null && first.isBefore(feelStart);
  }

  DateTime? get _firstLogDay {
    DateTime? first;
    for (final d in tracker.days.values) {
      final day = Dates.parseKey(d.key);
      if (day != null && (first == null || day.isBefore(first))) first = day;
    }
    for (final d in tracker.doses) {
      final day = Dates.dateOnly(d.takenAt);
      if (first == null || day.isBefore(first)) first = day;
    }
    return first;
  }

  void feelBack() {
    if (!canFeelBack) return;
    Haptics.instance.selectionClick();
    feelPage.value++;
  }

  void feelForward() {
    if (feelPage.value == 0) return;
    Haptics.instance.selectionClick();
    feelPage.value--;
  }

  UserProfile? get profile => tracker.profile.value;

  void pickRange(ProgressRange r) {
    if (range.value == r) return;
    Haptics.instance.selectionClick();
    range.value = r;
    selected.value = -1;
  }

  /// Longer ranges need Plus.
  bool get locked => range.value != ProgressRange.month && !PlusAccess.unlocked;

  void openPlus() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.plus);
  }

  void openReport() {
    Haptics.instance.selectionClick();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().select(HomeTab.report);
    }
  }

  void logWeight() => showWeightSheet();

  // ------------------------------------------------------------ weigh-ins

  /// "27 entries · last Mon, 19 Oct" for the Weigh-ins row.
  String get weighInsSummary {
    final w = tracker.weights;
    if (w.isEmpty) return 'None yet · add past ones here';
    final n = w.length;
    return '$n ${n == 1 ? 'entry' : 'entries'} · last ${Dates.shortWithDay(w.last.date)}';
  }

  void openWeighIns() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.weighIns);
  }

  /// A protein or water bar: that day's view.
  void openDay(DateTime day) {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.day, arguments: day);
  }

  // ---------------------------------------------------------------- weight

  bool get useKg => profile?.useKg ?? true;
  String get unit => useKg ? 'kg' : 'lb';
  double shown(double kg) => useKg ? kg : kg * Imperial.lbPerKg;
  String fmt(double kg) => shown(kg).toStringAsFixed(1);

  DateTime get rangeStart {
    final today = Dates.dateOnly(DateTime.now());
    switch (range.value) {
      case ProgressRange.month:
        return Dates.addDays(today, -PlusAccess.freeHistoryDays);
      case ProgressRange.quarter:
        return Dates.addDays(today, -90);
      case ProgressRange.all:
        final firstWeight = tracker.weights.isNotEmpty
            ? tracker.weights.first.date
            : today;
        final firstDose = tracker.doses.isNotEmpty
            ? tracker.doses.last.takenAt
            : today;
        return Dates.dateOnly(
          firstWeight.isBefore(firstDose) ? firstWeight : firstDose,
        );
    }
  }

  List<WeightEntry> get points =>
      tracker.weights.where((w) => !w.date.isBefore(rangeStart)).toList();

  bool get hasWeights => tracker.weights.isNotEmpty;
  double get startKg => tracker.startWeightKg;
  double? get latestKg => tracker.latestWeightKg;

  /// Weighed, but within 0.05 of the start (shown as "No change yet").
  bool get noChange {
    final now = latestKg;
    if (now == null || startKg <= 0) return false;
    return shown(now - startKg).abs() <= 0.05;
  }

  /// "−7.8" (sign + number, no unit).
  String get changeNumber {
    final now = latestKg;
    if (now == null || startKg <= 0) return '0.0';
    final d = shown(now - startKg);
    final sign = d < -0.05 ? '−' : (d > 0.05 ? '+' : '±');
    return '$sign${d.abs().toStringAsFixed(1)}';
  }

  String get changeLine {
    final now = latestKg;
    if (now == null || startKg <= 0) return '';
    if (noChange) return 'Same as your start, ${fmt(now)} $unit';
    final pct = (now - startKg).abs() / startKg * 100;
    return '${fmt(startKg)} → ${fmt(now)} $unit · ${pct.toStringAsFixed(1)}% of your start';
  }

  String? get bmiLabel {
    final now = latestKg;
    final h = profile?.heightCm;
    if (now == null || h == null) return null;
    final b = Bmi.of(now, h);
    return b == null ? null : 'BMI ${b.toStringAsFixed(1)}';
  }

  String? get toGoalLabel {
    final goal = profile?.goalWeightKg;
    final now = latestKg;
    if (goal == null || now == null) return null;
    final left = now - goal;
    return left <= 0 ? 'Goal reached' : '${fmt(left)} $unit to goal';
  }

  double? get goalShown {
    final g = profile?.goalWeightKg;
    return g == null ? null : shown(g);
  }

  /// Show the goal line only when it is close enough to the data to read.
  bool get showGoalLine {
    final g = profile?.goalWeightKg;
    final pts = points;
    if (g == null || pts.isEmpty) return false;
    // The chart itself also leaves it out when it would squash the line.
    final lo = pts.map((p) => p.kg).reduce(math.min);
    return (lo - g) < 4;
  }

  /// Dose strength changes inside the range.
  List<DoseMarker> get doseMarkers {
    final list = tracker.doses.reversed.toList(); // oldest first
    final out = <DoseMarker>[];
    for (var i = 1; i < list.length; i++) {
      final d = list[i];
      if (d.strengthMg != list[i - 1].strengthMg &&
          !d.takenAt.isBefore(rangeStart)) {
        out.add(
          DoseMarker(Dates.dateOnly(d.takenAt), Catalog.mgLabel(d.strengthMg)),
        );
      }
    }
    return out;
  }

  void pickPoint(int i) {
    Haptics.instance.selectionClick();
    selected.value = i;
  }

  // ----------------------------------------------------------------- doses

  bool get hasDoses => tracker.doses.isNotEmpty;
  bool get isDaily => profile?.isDaily ?? false;

  /// Doses in the chosen range taken within a day of plan ("3/4"), or for
  /// daily plans days taken out of days since the first dose ("5/6"),
  /// never counting days before treatment started.
  String get onTimeValue {
    final (ok, total) = _onTime;
    return total == 0 ? '0' : '$ok/$total';
  }

  /// Worth celebrating: at least 3 in 4 on time (highlighted tile).
  bool get onTimeGood {
    final (ok, total) = _onTime;
    return total > 0 && ok / total >= 0.75;
  }

  (int, int) get _onTime {
    final p = profile;
    if (p == null || tracker.doses.isEmpty) return (0, 0);
    final start = rangeStart;
    final today = Dates.dateOnly(DateTime.now());
    if (p.isDaily) {
      final first = Dates.dateOnly(tracker.doses.last.takenAt);
      final from = first.isAfter(start) ? first : start;
      // Today counts once its tablet is logged, not before, so a perfect
      // week doesn't read "6/7" every morning.
      var days = Dates.daysBetween(from, today) + 1;
      final skip = days > 1 && tracker.doseOn(today) == null ? 1 : 0;
      days -= skip;
      var taken = 0;
      for (var i = 0; i < days; i++) {
        if (tracker.doseOn(Dates.addDays(today, -(i + skip))) != null) taken++;
      }
      return (taken, days);
    }
    final list = tracker.doses.reversed.toList(); // oldest first
    var ok = 0;
    var total = 0;
    for (var i = 0; i < list.length; i++) {
      if (list[i].takenAt.isBefore(start)) continue;
      total++;
      // The very first dose has nothing to be late against.
      if (i == 0) {
        ok++;
        continue;
      }
      // Same rule as the streak: on the interval, or on the day the app
      // asked for (weekly plans snap back to the usual day after a late
      // one, so that next dose isn't "late" too).
      if (tracker.onTimeAfter(list[i - 1].takenAt, list[i].takenAt)) ok++;
    }
    return (ok, total);
  }

  String get onTimeSub => isDaily ? 'days taken' : 'on time';

  /// The plan's dose changed since the last logged one (e.g. moved up to
  /// 7.5 mg in Edit plan): show the new dose "from next dose".
  bool get _planChanged {
    final p = profile;
    final last = tracker.lastDose;
    return p != null &&
        last != null &&
        p.strengthMg > 0 &&
        p.strengthMg != last.strengthMg;
  }

  String get currentDose {
    final last = tracker.lastDose;
    if (last == null) {
      final mg = profile?.strengthMg ?? 0;
      return mg > 0 ? Catalog.mgLabel(mg) : '—';
    }
    return Catalog.mgLabel(
      _planChanged ? profile!.strengthMg : last.strengthMg,
    );
  }

  String get currentDoseSince {
    final list = tracker.doses; // newest first
    if (list.isEmpty) return 'your dose';
    if (_planChanged) return 'from next dose';
    final mg = list.first.strengthMg;
    var since = list.first.takenAt;
    for (final d in list) {
      if (d.strengthMg != mg) break;
      since = d.takenAt;
    }
    return 'since ${Dates.short(since)}';
  }

  String get nextDoseValue {
    final n = tracker.nextDoseAt();
    if (n == null) return '—';
    final rel = Dates.relativeDay(n, DateTime.now());
    if (rel == 'Today' || rel == 'Tomorrow') return rel;
    // A weekday alone is only clear within the coming week.
    final days = Dates.daysBetween(DateTime.now(), n);
    if (days < 0) return 'Due';
    return days < 7 ? Dates.weekdayShort(n.weekday) : Dates.short(n);
  }

  /// (area, count) for belly, thighs, arms inside the range.
  List<(String, int)> get siteAreas {
    final start = rangeStart;
    var belly = 0, thigh = 0, arm = 0;
    for (final d in tracker.siteDoses) {
      if (d.takenAt.isBefore(start)) continue;
      if (d.site.contains('belly')) {
        belly++;
      } else if (d.site.contains('thigh')) {
        thigh++;
      } else if (d.site.contains('arm')) {
        arm++;
      }
    }
    return [('Belly', belly), ('Thighs', thigh), ('Arms', arm)];
  }

  /// Any injection plan, daily pens (Saxenda) too; never tablets.
  bool get showSites =>
      profile?.form != 'tablet' && siteAreas.any((a) => a.$2 > 0);

  String get sitesNote {
    final areas = siteAreas;
    final unused = areas
        .where((a) => a.$2 == 0)
        .map((a) => a.$1.toLowerCase())
        .toList();
    if (unused.isEmpty) return 'Nice rotation. Each spot gets time to rest.';
    final names = unused.length == 1
        ? unused.first
        : '${unused.first} and ${unused.last}';
    return '${names[0].toUpperCase()}${names.substring(1)} not used lately. Rotating gives each spot time to rest.';
  }

  String get rangeWord => switch (range.value) {
    ProgressRange.month => 'last 4 weeks',
    ProgressRange.quarter => 'last 3 months',
    ProgressRange.all => 'all time',
  };

  // ------------------------------------------------------- protein / water

  List<DateTime> get last7Days {
    final today = Dates.dateOnly(DateTime.now());
    return [for (var i = 6; i >= 0; i--) Dates.addDays(today, -i)];
  }

  List<DayBar> get proteinBars {
    final goal = (profile?.proteinGoalG ?? 100).toDouble();
    return [
      for (final d in last7Days)
        DayBar(
          date: d,
          value: tracker.dayLog(d).proteinG.toDouble(),
          goal: goal,
        ),
    ];
  }

  List<DayBar> get waterBars {
    final goal = (profile?.waterGoalMl ?? 2500).toDouble();
    return [
      for (final d in last7Days)
        DayBar(
          date: d,
          value: tracker.dayLog(d).waterMl.toDouble(),
          goal: goal,
        ),
    ];
  }

  String barsHeadline(List<DayBar> bars, {required bool water}) {
    final logged = bars.where((b) => b.value > 0).toList();
    if (logged.isEmpty) return 'Nothing logged this week yet';
    final hit = bars.where((b) => b.hit).length;
    final avg = logged.fold<double>(0, (s, b) => s + b.value) / logged.length;
    final avgLabel = water
        ? Water.totalWithUnit(avg.round())
        : '${avg.round()} g';
    return 'Goal reached $hit of 7 days · avg $avgLabel';
  }

  // ------------------------------------------------------------ how you felt

  static int dayLevel(DayLog log) => FeelPattern.dayLevel(log);

  /// 4 weeks, Monday first: the current period, or [feelPage] back.
  List<FeelCell> get feelCells {
    final today = Dates.dateOnly(DateTime.now());
    final start = feelStart;
    return [
      for (var i = 0; i < 28; i++)
        () {
          final d = Dates.addDays(start, i);
          final future = d.isAfter(today);
          return FeelCell(
            date: d,
            level: future ? -1 : dayLevel(tracker.dayLog(d)),
            doseDay: !isDaily && tracker.doseOn(d) != null,
            inFuture: future,
          );
        }(),
    ];
  }

  /// Today's check-in is saved (hides "Check in today").
  bool get checkedInToday => tracker.today.hasCheckIn;

  void openCheckIn() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.checkIn);
  }

  String get feelHeadline {
    final cells = feelCells.where((c) => c.level >= 0).toList();
    if (cells.isEmpty) {
      return feelPage.value == 0
          ? 'No check-ins yet. One a day builds your picture.'
          : 'No check-ins in these weeks.';
    }
    final avg = cells.fold<int>(0, (s, c) => s + c.level) / cells.length;
    final word = avg < 0.5
        ? 'Mostly fine'
        : (avg < 1.5
              ? 'Mostly mild'
              : (avg < 2.3 ? 'Some harder days' : 'A tough few weeks'));
    final counts = <String, int>{};
    for (final c in cells) {
      final log = tracker.dayLog(c.date);
      for (final s in log.symptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '$word.';
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return '$word. ${Catalog.symptoms[top] ?? top} came up most.';
  }

  /// "Day 1 after your dose is usually your hardest", or null when there
  /// isn't enough data (3+ dose weeks with check-ins).
  String? get patternLine {
    if (isDaily || tracker.doses.length < FeelPattern.minWeeks) return null;
    final day = FeelPattern.hardestDay(tracker.days.values, tracker.doses);
    if (day == null) return null;
    if (day < 0) return 'No hard day stands out. Your weeks look steady.';
    return day == 0
        ? 'Dose day is usually your hardest.'
        : 'Day $day after your dose is usually your hardest.';
  }

  bool get isPlus => PlusAccess.unlocked;
}
