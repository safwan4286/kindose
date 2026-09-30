import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../services/tracker_service.dart';
import '../../widgets/k_ruler.dart';

/// One tile on the weekly card. [strip] is the 7-day protein strip.
class WeeklyTile {
  const WeeklyTile(this.caps, this.value, this.sub, {this.strip});

  final String caps;
  final String value;
  final String? sub;
  final List<bool>? strip;
}

/// Last week (Monday–Sunday) in short. Built from the log only; tiles with
/// no data are left out. Weight change is shown neutrally.
class WeeklySummary {
  const WeeklySummary({
    required this.key,
    required this.range,
    required this.week,
    required this.headline,
    required this.tiles,
    this.waterLine,
  });

  /// Monday of the summarised week ("2026-09-21"), used to hide it once seen.
  final String key;

  /// "21–27 Sep".
  final String range;

  /// Treatment week of that Monday, or null when unknown.
  final int? week;
  final String headline;
  final List<WeeklyTile> tiles;
  final String? waterLine;

  /// Days with anything logged needed before the card shows.
  static const int minLoggedDays = 4;

  /// Monday of the week before [now].
  static DateTime lastWeekStart(DateTime now) {
    final today = Dates.dateOnly(now);
    return today.subtract(Duration(days: today.weekday - 1 + 7));
  }

  /// Null when last week has fewer than [minLoggedDays] logged days.
  static WeeklySummary? build(TrackerService t, DateTime now) {
    final p = t.profile.value;
    if (p == null) return null;
    final start = lastWeekStart(now);
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final logs = [for (final d in days) t.dayLog(d)];
    final doses = t.doses.where((d) => _inWeek(d.takenAt, start)).toList();
    final weights = t.weights.where((w) => _inWeek(w.date, start)).toList();

    var logged = 0;
    for (var i = 0; i < 7; i++) {
      final l = logs[i];
      final any =
          l.proteinG > 0 ||
          l.waterMl > 0 ||
          l.hasCheckIn ||
          t.doseOn(days[i]) != null ||
          weights.any((w) => Dates.sameDay(w.date, days[i]));
      if (any) logged++;
    }
    if (logged < minLoggedDays) return null;

    final proteinHit = [for (final l in logs) l.proteinG >= p.proteinGoalG];
    final proteinDays = proteinHit.where((h) => h).length;
    final waterDays = logs.where((l) => l.waterMl >= p.waterGoalMl).length;

    final tiles = <WeeklyTile>[
      ?_weightTile(t, p, start, weights),
      ?_doseTile(t, p, days, doses),
      WeeklyTile(
        'PROTEIN GOAL',
        '$proteinDays of 7 days',
        null,
        strip: proteinHit,
      ),
      ?_feelTile(logs),
    ];

    final headline = logged == 7
        ? 'Seven days logged. Nicely kept.'
        : proteinDays >= 5
        ? 'Protein was strong this week.'
        : 'Here’s how your week went.';

    return WeeklySummary(
      key: Dates.key(start),
      range: _range(start),
      week: _weekOf(t, p, start),
      headline: headline,
      tiles: tiles,
      waterLine: waterDays == 0
          ? null
          : 'Water goal hit on $waterDays of 7 days.',
    );
  }

  static bool _inWeek(DateTime d, DateTime start) {
    final day = Dates.dateOnly(d);
    return !day.isBefore(start) &&
        day.isBefore(start.add(const Duration(days: 7)));
  }

  /// "21–27 Sep" / "Sep 21–27", or "28 Sep – 4 Oct" across months.
  static String _range(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return start.month == end.month
        ? (Dates.monthFirst
              ? '${Dates.monthShort(end.month)} ${start.day}–${end.day}'
              : '${start.day}–${end.day} ${Dates.monthShort(end.month)}')
        : '${Dates.short(start)} – ${Dates.short(end)}';
  }

  static int? _weekOf(TrackerService t, UserProfile p, DateTime start) {
    final began =
        p.treatmentStartedAt ?? (t.doses.isEmpty ? null : t.doses.last.takenAt);
    if (began == null || began.isAfter(start.add(const Duration(days: 6))))
      return null;
    final days = Dates.daysBetween(began, start);
    return days < 0 ? 1 : days ~/ 7 + 1;
  }

  /// Week average against the week before. Needs weigh-ins in both.
  static WeeklyTile? _weightTile(
    TrackerService t,
    UserProfile p,
    DateTime start,
    List<WeightEntry> week,
  ) {
    final before = t.weights
        .where((w) => _inWeek(w.date, start.subtract(const Duration(days: 7))))
        .toList();
    if (week.isEmpty || before.isEmpty) return null;
    double avg(List<WeightEntry> l) =>
        l.fold(0.0, (a, w) => a + w.kg) / l.length;
    var diff = avg(week) - avg(before);
    if (!p.useKg) diff *= Imperial.lbPerKg;
    final unit = p.useKg ? 'kg' : 'lb';
    final rounded = (diff * 10).round() / 10;
    final value = rounded == 0
        ? 'No change'
        : '${rounded < 0 ? '−' : '+'}${rounded.abs().toStringAsFixed(1)} $unit';
    return WeeklyTile('WEIGHT', value, 'week average vs last');
  }

  static WeeklyTile? _doseTile(
    TrackerService t,
    UserProfile p,
    List<DateTime> days,
    List<DoseLog> doses,
  ) {
    if (p.medicineId == Catalog.undecided) return null;
    if (p.isDaily) {
      final taken = days.where((d) => t.doseOn(d) != null).length;
      return WeeklyTile('DOSES', '$taken of 7 days', 'taken');
    }
    if (doses.isEmpty) {
      // Doses every 2+ weeks may simply not fall in this week.
      return p.everyDays <= 7
          ? const WeeklyTile('DOSE', 'Not logged', 'No dose logged this week')
          : null;
    }
    final d = doses.first; // newest first
    final i = t.doses.indexOf(d);
    final prev = i >= 0 && i + 1 < t.doses.length ? t.doses[i + 1] : null;
    final onTime =
        prev != null &&
        (Dates.daysBetween(prev.takenAt, d.takenAt) - p.everyDays).abs() <= 1;
    final parts = [
      Dates.weekdayShort(d.takenAt.weekday),
      if (d.strengthMg > 0) '${Catalog.mg(d.strengthMg)} mg',
      if (d.site.isNotEmpty) Catalog.siteName(d.site).toLowerCase(),
    ];
    return WeeklyTile('DOSE', onTime ? 'On time' : 'Logged', parts.join(' · '));
  }

  static WeeklyTile? _feelTile(List<DayLog> logs) {
    final moods = [for (final l in logs) ?l.mood];
    final effects = <String, int>{};
    for (final l in logs) {
      for (final s in l.symptoms) {
        effects[s] = (effects[s] ?? 0) + 1;
      }
    }
    if (moods.isEmpty && effects.isEmpty) return null;

    String? sub;
    if (effects.isNotEmpty) {
      final top = effects.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final name = Catalog.symptoms[top.key] ?? top.key;
      sub = '$name on ${top.value} ${top.value == 1 ? 'day' : 'days'}';
    } else {
      sub = 'No side effects logged';
    }

    if (moods.isEmpty) {
      final n = logs.where((l) => l.hasCheckIn).length;
      return WeeklyTile(
        'HOW YOU FELT',
        '$n check-${n == 1 ? 'in' : 'ins'}',
        sub,
      );
    }
    final counts = List<int>.filled(Catalog.moods.length, 0);
    for (final m in moods) {
      if (m >= 0 && m < counts.length) counts[m]++;
    }
    var best = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return WeeklyTile(
      'HOW YOU FELT',
      'Mostly ${Catalog.moods[best].label.toLowerCase()}',
      sub,
    );
  }
}
