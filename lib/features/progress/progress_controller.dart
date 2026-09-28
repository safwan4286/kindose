import 'dart:math' as math;

import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/bmi.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
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
    range.value;
    selected.value;
    PlusAccess.active.value;
  }

  UserProfile? get profile => tracker.profile.value;

  void pickRange(ProgressRange r) {
    if (range.value == r) return;
    Haptics.instance.selectionClick();
    range.value = r;
    selected.value = -1;
  }

  /// Longer ranges need Plus.
  bool get locked =>
      range.value != ProgressRange.month && !PlusAccess.active.value;

  void openPlus() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.plus);
  }

  void openReport() {
    Haptics.instance.selectionClick();
    if (Get.isRegistered<HomeController>())
      Get.find<HomeController>().select(HomeTab.report);
  }

  void logWeight() => showWeightSheet();

  // ---------------------------------------------------------------- weight

  bool get useKg => profile?.useKg ?? true;
  String get unit => useKg ? 'kg' : 'lb';
  double shown(double kg) => useKg ? kg : kg * Imperial.lbPerKg;
  String fmt(double kg) => shown(kg).toStringAsFixed(1);

  DateTime get rangeStart {
    final today = Dates.dateOnly(DateTime.now());
    switch (range.value) {
      case ProgressRange.month:
        return today.subtract(const Duration(days: PlusAccess.freeHistoryDays));
      case ProgressRange.quarter:
        return today.subtract(const Duration(days: 90));
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
    final lo = pts.map((p) => p.kg).reduce(math.min);
    return range.value == ProgressRange.all || (lo - g) < 4;
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
          DoseMarker(
            Dates.dateOnly(d.takenAt),
            '${Catalog.mgLabel(d.strengthMg)} from here',
          ),
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

  /// "16/16" doses within a day of plan (weekly) or "24/28" days taken (daily).
  String get onTimeValue {
    final p = profile;
    if (p == null || tracker.doses.isEmpty) return '0';
    if (p.isDaily) {
      final today = Dates.dateOnly(DateTime.now());
      var taken = 0;
      for (var i = 0; i < 28; i++) {
        if (tracker.doseOn(today.subtract(Duration(days: i))) != null) taken++;
      }
      return '$taken/28';
    }
    final list = tracker.doses.reversed.toList();
    var ok = 1;
    for (var i = 1; i < list.length; i++) {
      final gap = Dates.daysBetween(list[i - 1].takenAt, list[i].takenAt);
      if ((gap - p.everyDays).abs() <= 1) ok++;
    }
    return '$ok/${list.length}';
  }

  String get onTimeSub => isDaily ? 'days taken' : 'on time';

  String get currentDose {
    final last = tracker.lastDose;
    return last == null ? '—' : Catalog.mgLabel(last.strengthMg);
  }

  String get currentDoseSince {
    final list = tracker.doses; // newest first
    if (list.isEmpty) return '';
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
    return rel == 'Today' || rel == 'Tomorrow'
        ? rel
        : Dates.weekdayShort(n.weekday);
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

  bool get showSites =>
      !isDaily && profile?.form != 'tablet' && siteAreas.any((a) => a.$2 > 0);

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
    return [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
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
        ? '${(avg / 1000).toStringAsFixed(1)} L'
        : '${avg.round()} g';
    return 'Goal reached $hit of 7 days · avg $avgLabel';
  }

  // ------------------------------------------------------------ how you felt

  static int dayLevel(DayLog log) {
    if (!log.hasCheckIn) return -1;
    var l = log.symptoms.contains('nausea') ? (log.nausea ?? 0) + 1 : 0;
    for (final id in Catalog.checkInEffects) {
      l = math.max(l, log.levelOf(id));
    }
    return l.clamp(0, 3);
  }

  /// 4 weeks, Monday first, ending with the current week.
  List<FeelCell> get feelCells {
    final today = Dates.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(const Duration(days: 21));
    return [
      for (var i = 0; i < 28; i++)
        () {
          final d = start.add(Duration(days: i));
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

  String get feelHeadline {
    final cells = feelCells.where((c) => c.level >= 0).toList();
    if (cells.isEmpty)
      return 'Check in a few times to see how you feel over time.';
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
    if (isDaily || tracker.doses.length < 3) return null;
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    final weeks = <String>{};
    for (final log in tracker.days.values) {
      final level = dayLevel(log);
      if (level < 0) continue;
      DoseLog? before;
      for (final dose in tracker.doses) {
        if (!Dates.dateOnly(dose.takenAt).isAfter(log.date)) {
          before = dose;
          break;
        }
      }
      if (before == null) continue;
      final off = Dates.daysBetween(before.takenAt, log.date);
      if (off < 0 || off > 6) continue;
      sums[off] += level;
      counts[off]++;
      weeks.add(before.id);
    }
    if (weeks.length < 3) return null;
    var best = -1;
    var bestAvg = 0.0;
    for (var i = 0; i < 7; i++) {
      if (counts[i] == 0) continue;
      final a = sums[i] / counts[i];
      if (a > bestAvg) {
        bestAvg = a;
        best = i;
      }
    }
    if (best < 0 || bestAvg < 0.5)
      return 'No hard day stands out. Your weeks look steady.';
    return best == 0
        ? 'Dose day is usually your hardest.'
        : 'Day $best after your dose is usually your hardest.';
  }

  bool get isPlus => PlusAccess.active.value;
}
