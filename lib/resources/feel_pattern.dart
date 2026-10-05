import 'dart:math' as math;

import '../models/logs.dart';
import 'catalog.dart';
import 'date_utils.dart';

/// Which day after a dose usually feels hardest, from check-ins. Shared by
/// Progress ("Your pattern") and the doctor report. Weekly-type plans only.
class FeelPattern {
  FeelPattern._();

  /// Dose weeks with check-ins needed before a pattern is shown.
  static const int minWeeks = 3;

  /// How a day felt: 0 (fine) to 3 (severe), or -1 with no check-in.
  static int dayLevel(DayLog log) {
    if (!log.hasCheckIn) return -1;
    var l = log.symptoms.contains('nausea') ? (log.nausea ?? 0) + 1 : 0;
    for (final id in Catalog.checkInEffects) {
      l = math.max(l, log.levelOf(id));
    }
    return l.clamp(0, 3);
  }

  /// Day after the dose (0 = dose day) with the highest average level;
  /// -1 when no day stands out; null with fewer than [minWeeks] dose weeks
  /// of check-ins. [dosesNewestFirst] is `TrackerService.doses`.
  static int? hardestDay(
    Iterable<DayLog> days,
    List<DoseLog> dosesNewestFirst,
  ) {
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    final weeks = <String>{};
    for (final log in days) {
      final level = dayLevel(log);
      if (level < 0) continue;
      DoseLog? before;
      for (final dose in dosesNewestFirst) {
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
    if (weeks.length < minWeeks) return null;
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
    return best < 0 || bestAvg < 0.5 ? -1 : best;
  }

  /// "Dose day" / "Day 2 after the dose".
  static String dayName(int day) =>
      day == 0 ? 'Dose day' : 'Day $day after the dose';
}
