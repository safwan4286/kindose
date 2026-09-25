import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/date_utils.dart';
import '../../services/tracker_service.dart';

enum ProgressRange { month, quarter, all }

class DayBar {
  const DayBar(this.label, this.value, this.hit);

  final String label;

  /// 0.0 – 1.0 bar height.
  final double value;
  final bool hit;
}

/// Weight trend and weekly habit strips. All numbers are simple
/// arithmetic on what the user logged. No predictions.
class ProgressController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final Rx<ProgressRange> range = ProgressRange.month.obs;

  static const double lbPerKg = 2.20462;

  bool get useKg => tracker.profile.value?.useKg ?? true;
  String get unit => useKg ? 'kg' : 'lb';
  double shown(double kg) => useKg ? kg : kg * lbPerKg;
  String fmt(double kg) => shown(kg).toStringAsFixed(1);

  DateTime get rangeStart {
    final today = Dates.dateOnly(DateTime.now());
    switch (range.value) {
      case ProgressRange.month:
        return today.subtract(const Duration(days: 30));
      case ProgressRange.quarter:
        return today.subtract(const Duration(days: 90));
      case ProgressRange.all:
        final first = tracker.weights.isNotEmpty ? tracker.weights.first.date : today;
        final firstDose = tracker.doses.isNotEmpty ? tracker.doses.last.takenAt : today;
        final start = first.isBefore(firstDose) ? first : firstDose;
        return Dates.dateOnly(start).isBefore(today.subtract(const Duration(days: 7)))
            ? Dates.dateOnly(start)
            : today.subtract(const Duration(days: 7));
    }
  }

  List<WeightEntry> get points =>
      tracker.weights.where((w) => !w.date.isBefore(rangeStart)).toList();

  List<DateTime> get doseDates => tracker.doses
      .where((d) => !d.takenAt.isBefore(rangeStart))
      .map((d) => d.takenAt)
      .toList();

  bool get hasTrend => points.length >= 2;

  /// Average of weigh-ins in the last 7 days, or the latest one.
  double? get weeklyAverageKg {
    if (tracker.weights.isEmpty) return null;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = tracker.weights.where((w) => w.date.isAfter(cutoff)).toList();
    final list = recent.isEmpty ? [tracker.weights.last] : recent;
    return list.fold<double>(0, (s, w) => s + w.kg) / list.length;
  }

  WeightEntry? get first => tracker.weights.isEmpty ? null : tracker.weights.first;

  /// Change from first weigh-in to weekly average, e.g. "−2.8 kg · −3.0%".
  String get changeLabel {
    final f = first;
    final avg = weeklyAverageKg;
    if (f == null || avg == null) return '';
    final diff = avg - f.kg;
    final pct = f.kg == 0 ? 0.0 : diff / f.kg * 100;
    final sign = diff < 0 ? '−' : '+';
    return '$sign${shown(diff.abs()).toStringAsFixed(1)} $unit · $sign${pct.abs().toStringAsFixed(1)}%';
  }

  bool get isDown => (weeklyAverageKg ?? 0) <= (first?.kg ?? 0);

  String get toGoalLabel {
    final goal = tracker.profile.value?.goalWeightKg;
    final avg = weeklyAverageKg;
    if (goal == null || avg == null) return 'Not set';
    final left = avg - goal;
    return left <= 0 ? 'Reached' : '${fmt(left)} $unit';
  }

  String get perWeekLabel {
    final f = first;
    final avg = weeklyAverageKg;
    if (f == null || avg == null || tracker.weights.length < 2) return '—';
    final days = Dates.daysBetween(f.date, tracker.weights.last.date);
    if (days < 7) return '—';
    final perWeek = (avg - f.kg) / (days / 7);
    final sign = perWeek < 0 ? '−' : '+';
    return '$sign${shown(perWeek.abs()).toStringAsFixed(1)} $unit';
  }

  List<DateTime> get last7Days {
    final today = Dates.dateOnly(DateTime.now());
    return [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
  }

  List<DayBar> get proteinBars {
    final goal = tracker.profile.value?.proteinGoalG ?? 100;
    return [
      for (final d in last7Days)
        () {
          final g = tracker.dayLog(d).proteinG;
          return DayBar(Dates.weekdayShort(d.weekday).substring(0, 1), goal == 0 ? 0 : (g / goal).clamp(0.0, 1.0), g >= goal);
        }(),
    ];
  }

  int get proteinDaysHit => proteinBars.where((b) => b.hit).length;

  List<DayBar> get nauseaBars => [
        for (final d in last7Days)
          () {
            final log = tracker.dayLog(d);
            final n = log.symptoms.contains('nausea') ? (log.nausea ?? 0) + 1 : 0;
            return DayBar(Dates.weekdayShort(d.weekday).substring(0, 1), n / 3, n >= 3);
          }(),
      ];

  /// Plain-language note about when nausea shows up, if there is a pattern.
  String get nauseaNote {
    final days = <int>[];
    for (final log in tracker.days.values) {
      if (!log.symptoms.contains('nausea')) continue;
      DateTime? before;
      for (final dose in tracker.doses) {
        if (!dose.takenAt.isAfter(log.date.add(const Duration(days: 1)))) {
          before = dose.takenAt;
          break;
        }
      }
      if (before != null) days.add(Dates.daysBetween(before, log.date));
    }
    if (days.length < 3) return 'Log a few check-ins to see patterns';
    days.sort();
    final median = days[days.length ~/ 2];
    return median == 0 ? 'Mostly on dose day' : 'Mostly around day $median after a dose';
  }
}
