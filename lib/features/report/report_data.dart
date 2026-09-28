import 'dart:math' as math;

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../services/tracker_service.dart';
import '../../widgets/k_ruler.dart';

/// Which parts the user chose to include.
class ReportSections {
  const ReportSections({
    this.doses = true,
    this.weight = true,
    this.sideEffects = true,
    this.nutrition = true,
    this.notes = false,
  });

  final bool doses;
  final bool weight;
  final bool sideEffects;
  final bool nutrition;
  final bool notes;
}

/// One side effect over the period.
class SymptomRow {
  const SymptomRow({required this.label, required this.days, required this.strongest, this.usualDay});

  final String label;
  final int days;

  /// 1 mild … 3 severe.
  final int strongest;

  /// "Day 1", "Day 1–2", "Dose day", or null when there isn't enough data.
  final String? usualDay;
}

/// Plain summary of one period, shared by the app and the PDF.
/// Only facts the user logged, no interpretation.
class ReportData {
  ReportData._({
    required this.from,
    required this.to,
    required this.periodNote,
    required this.sections,
    required this.profile,
    required this.doses,
    required this.periodWeights,
    required this.allWeights,
    required this.doseChanges,
    required this.symptoms,
    required this.checkInDays,
    required this.days,
    required this.avgProtein,
    required this.proteinDaysHit,
    required this.loggedDays,
    required this.avgWaterMl,
    required this.notes,
    required this.questions,
    required this.onSchedule,
    required this.startKg,
    required this.treatmentStart,
    required this.foodNoise,
    required this.appetite,
    required this.moodLine,
    this.patientName,
    this.patientDob,
  });

  factory ReportData.build(
    TrackerService t, {
    required DateTime from,
    required DateTime to,
    required ReportSections sections,
    String periodNote = '',
    List<String> questions = const [],
    String? patientName,
    String? patientDob,
  }) {
    final start = Dates.dateOnly(from);
    final end = Dates.dateOnly(to).add(const Duration(days: 1));
    bool inRange(DateTime d) => !d.isBefore(start) && d.isBefore(end);
    final p = t.profile.value;

    final allDoses = t.doses.reversed.toList(); // oldest first
    final doses = allDoses.where((d) => inRange(d.takenAt)).toList();
    final days = t.days.values.where((d) => inRange(d.date)).toList()..sort((a, b) => a.key.compareTo(b.key));

    // Dose changes over the whole treatment (for the chart and header).
    final changes = <(DateTime, double)>[];
    for (var i = 0; i < allDoses.length; i++) {
      if (i == 0 || allDoses[i].strengthMg != allDoses[i - 1].strengthMg) {
        changes.add((Dates.dateOnly(allDoses[i].takenAt), allDoses[i].strengthMg));
      }
    }

    // On schedule: within a day of the plan (daily: one per day).
    var onSchedule = 0;
    for (final d in doses) {
      final i = allDoses.indexOf(d);
      if (i <= 0 || p == null) {
        onSchedule++;
        continue;
      }
      final gap = Dates.daysBetween(allDoses[i - 1].takenAt, d.takenAt);
      if ((gap - p.everyDays).abs() <= 1) onSchedule++;
    }

    // Side effects: days, strongest level, usual day after the dose.
    final ids = <String>{for (final d in days) ...d.symptoms};
    final rows = <SymptomRow>[];
    for (final id in ids) {
      var count = 0;
      var strongest = 0;
      final offsets = <int>[];
      final weeks = <String>{};
      for (final d in days) {
        final level = id == 'nausea' ? (d.symptoms.contains('nausea') ? (d.nausea ?? 0) + 1 : 0) : d.levelOf(id);
        if (level == 0) continue;
        count++;
        strongest = math.max(strongest, level);
        final before = _doseBefore(t.doses, d.date);
        if (before != null) {
          final off = Dates.daysBetween(before.takenAt, d.date);
          if (off >= 0 && off <= 6) {
            offsets.add(off);
            weeks.add(before.id);
          }
        }
      }
      if (count == 0) continue;
      rows.add(SymptomRow(
        label: Catalog.symptoms[id] ?? id,
        days: count,
        strongest: strongest.clamp(1, 3),
        usualDay: (p?.isDaily ?? false) || weeks.length < 3 ? null : _usualDay(offsets),
      ));
    }
    rows.sort((a, b) => b.days.compareTo(a.days));

    int countOf(Iterable<int?> values, int v) => values.where((x) => x == v).length;
    final checkIns = days.where((d) => d.hasCheckIn).toList();
    final noise = checkIns.map((d) => d.foodNoise);
    final appetite = checkIns.map((d) => d.appetite);
    final moods = checkIns.map((d) => d.mood).whereType<int>().toList();
    String moodLine = '';
    if (moods.isNotEmpty) {
      final counts = <int, int>{};
      for (final m in moods) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
      final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      moodLine = 'Mood: mostly "${Catalog.moods[top.key].label}" (${top.value} of ${moods.length})';
    }

    final withFood = days.where((d) => d.proteinG > 0 || d.waterMl > 0).toList();
    final goal = p?.proteinGoalG ?? 100;
    final firstDose = allDoses.isEmpty ? null : allDoses.first.takenAt;

    return ReportData._(
      from: start,
      to: Dates.dateOnly(to),
      periodNote: periodNote,
      sections: sections,
      profile: p,
      doses: doses,
      periodWeights: t.weights.where((w) => inRange(w.date)).toList(),
      allWeights: t.weights.toList(),
      doseChanges: changes,
      symptoms: rows,
      checkInDays: checkIns.length,
      days: Dates.daysBetween(start, Dates.dateOnly(to)) + 1,
      avgProtein: withFood.isEmpty ? 0 : withFood.fold<int>(0, (s, d) => s + d.proteinG) ~/ withFood.length,
      proteinDaysHit: withFood.where((d) => d.proteinG >= goal).length,
      loggedDays: withFood.length,
      avgWaterMl: withFood.isEmpty ? 0 : withFood.fold<int>(0, (s, d) => s + d.waterMl) ~/ withFood.length,
      notes: days.where((d) => d.note != null).map((d) => '${Dates.short(d.date)}: ${d.note}').toList(),
      questions: questions.where((q) => q.trim().isNotEmpty).toList(),
      onSchedule: onSchedule,
      startKg: t.startWeightKg,
      treatmentStart: p?.treatmentStartedAt ?? firstDose,
      foodNoise: checkIns.any((d) => d.foodNoise != null)
          ? 'Food noise: quiet ${countOf(noise, 0)} days, some ${countOf(noise, 1)}, loud ${countOf(noise, 2)}'
          : '',
      appetite: checkIns.any((d) => d.appetite != null)
          ? 'Appetite: low ${countOf(appetite, 0)} days, normal ${countOf(appetite, 1)}, high ${countOf(appetite, 2)}'
          : '',
      moodLine: moodLine,
      patientName: patientName,
      patientDob: patientDob,
    );
  }

  static DoseLog? _doseBefore(List<DoseLog> newestFirst, DateTime day) {
    for (final d in newestFirst) {
      if (!Dates.dateOnly(d.takenAt).isAfter(day)) return d;
    }
    return null;
  }

  /// Most common day(s) after the dose: "Dose day", "Day 1", "Day 1–2".
  static String? _usualDay(List<int> offsets) {
    if (offsets.isEmpty) return null;
    final counts = List<int>.filled(7, 0);
    for (final o in offsets) {
      counts[o]++;
    }
    final best = counts.reduce(math.max);
    final top = [for (var i = 0; i < 7; i++) if (counts[i] == best) i];
    String name(int d) => d == 0 ? 'Dose day' : 'Day $d';
    if (top.length == 1) return name(top.first);
    if (top.length == 2 && top[1] == top[0] + 1 && top[0] > 0) return 'Day ${top[0]}–${top[1]}';
    return null;
  }

  final DateTime from;
  final DateTime to;

  /// "since last visit", "last 4 weeks"… shown after the dates.
  final String periodNote;
  final ReportSections sections;
  final UserProfile? profile;
  final List<DoseLog> doses;
  final List<WeightEntry> periodWeights;
  final List<WeightEntry> allWeights;

  /// (date, mg) where each strength started, oldest first.
  final List<(DateTime, double)> doseChanges;
  final List<SymptomRow> symptoms;
  final int checkInDays;
  final int days;
  final int avgProtein;
  final int proteinDaysHit;
  final int loggedDays;
  final int avgWaterMl;
  final List<String> notes;
  final List<String> questions;
  final int onSchedule;
  final double startKg;
  final DateTime? treatmentStart;
  final String foodNoise;
  final String appetite;
  final String moodLine;
  final String? patientName;
  final String? patientDob;

  bool get useKg => profile?.useKg ?? true;
  String get unit => useKg ? 'kg' : 'lb';
  double shown(double kg) => useKg ? kg : kg * Imperial.lbPerKg;
  String weight(double kg) => shown(kg).toStringAsFixed(1);

  String signed(double kgDiff) {
    final v = shown(kgDiff);
    // Plain ASCII signs: the PDF font may not have U+2212.
    final sign = v < -0.05 ? '-' : (v > 0.05 ? '+' : '');
    return '$sign${v.abs().toStringAsFixed(1)}';
  }

  String get period {
    final sameYear = from.year == to.year;
    final a = sameYear ? Dates.short(from) : '${Dates.short(from)} ${from.year}';
    return '$a – ${Dates.short(to)} ${to.year}';
  }

  String get medicineLine {
    final p = profile;
    if (p == null) return '';
    final m = Catalog.medicine(p.medicineId);
    final name = Catalog.medicineName(p.medicineId, p.customMedicine);
    final molecule = m.molecule;
    final withMolecule = molecule == null || name.toLowerCase() == molecule ? name : '$name ($molecule)';
    final every = switch (p.everyDays) {
      1 => 'daily',
      7 => 'weekly',
      14 => 'every 2 weeks',
      _ => 'every ${p.everyDays} days',
    };
    final parts = <String>['$withMolecule ${Catalog.mgLabel(p.strengthMg)}, $every, ${Catalog.formLabel(p.form).toLowerCase()}'];
    final s = treatmentStart;
    if (s != null) parts.add('started ${Dates.short(s)} ${s.year}');
    if (doseChanges.length > 1) {
      final last = doseChanges.last;
      parts.add('${Catalog.mgLabel(last.$2)} since ${Dates.short(last.$1)}');
    }
    return parts.join(' · ');
  }

  /// Weight change inside the period ("−1.1 kg"), or null with < 2 weigh-ins.
  String? get periodChange {
    if (periodWeights.length < 2) return null;
    return '${signed(periodWeights.last.kg - periodWeights.first.kg)} $unit';
  }

  String get weightSub {
    if (periodWeights.isEmpty) return 'no weigh-ins';
    final first = periodWeights.first.kg;
    final last = periodWeights.last.kg;
    final since = startKg > 0 ? ' · ${signed(last - startKg)} since start' : '';
    return '${weight(first)} to ${weight(last)}$since';
  }

  String get dosesValue => '$onSchedule of ${doses.length}';

  bool get isDaily => profile?.isDaily ?? false;
}
