import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../services/tracker_service.dart';

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

class SymptomCount {
  const SymptomCount(this.label, this.days);

  final String label;
  final int days;
}

/// Plain summary of one period, shared by the in-app preview and the PDF.
/// Only facts the user logged, no interpretation.
class ReportData {
  ReportData._({
    required this.from,
    required this.to,
    required this.sections,
    required this.profile,
    required this.doses,
    required this.weights,
    required this.symptoms,
    required this.checkInDays,
    required this.avgProtein,
    required this.proteinDaysHit,
    required this.loggedDays,
    required this.avgWaterMl,
    required this.notes,
    this.patientName,
    this.patientDob,
  });

  factory ReportData.build(
    TrackerService t, {
    required DateTime from,
    required DateTime to,
    required ReportSections sections,
    String? patientName,
    String? patientDob,
  }) {
    final start = Dates.dateOnly(from);
    final end = Dates.dateOnly(to).add(const Duration(days: 1));
    bool inRange(DateTime d) => !d.isBefore(start) && d.isBefore(end);

    final doses = t.doses.where((d) => inRange(d.takenAt)).toList()
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    final weights = t.weights.where((w) => inRange(w.date)).toList();
    final days = t.days.values.where((d) => inRange(d.date)).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final counts = <String, int>{};
    for (final d in days) {
      for (final s in d.symptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    final symptoms = counts.entries
        .map((e) => SymptomCount(Catalog.symptoms[e.key] ?? e.key, e.value))
        .toList()
      ..sort((a, b) => b.days.compareTo(a.days));

    final withFood = days.where((d) => d.proteinG > 0 || d.waterMl > 0).toList();
    final goal = t.profile.value?.proteinGoalG ?? 100;

    return ReportData._(
      from: start,
      to: Dates.dateOnly(to),
      sections: sections,
      profile: t.profile.value,
      doses: doses,
      weights: weights,
      symptoms: symptoms,
      checkInDays: days.where((d) => d.hasCheckIn).length,
      avgProtein: withFood.isEmpty ? 0 : withFood.fold<int>(0, (s, d) => s + d.proteinG) ~/ withFood.length,
      proteinDaysHit: withFood.where((d) => d.proteinG >= goal).length,
      loggedDays: withFood.length,
      avgWaterMl: withFood.isEmpty ? 0 : withFood.fold<int>(0, (s, d) => s + d.waterMl) ~/ withFood.length,
      notes: days.where((d) => d.note != null).map((d) => '${Dates.short(d.date)}: ${d.note}').toList(),
      patientName: patientName,
      patientDob: patientDob,
    );
  }

  final DateTime from;
  final DateTime to;
  final ReportSections sections;
  final UserProfile? profile;
  final List<DoseLog> doses;
  final List<WeightEntry> weights;
  final List<SymptomCount> symptoms;
  final int checkInDays;
  final int avgProtein;
  final int proteinDaysHit;
  final int loggedDays;
  final int avgWaterMl;
  final List<String> notes;
  final String? patientName;
  final String? patientDob;

  bool get useKg => profile?.useKg ?? true;
  String get unit => useKg ? 'kg' : 'lb';
  String weight(double kg) => (useKg ? kg : kg * 2.20462).toStringAsFixed(1);

  String get period => '${Dates.short(from)} ${from.year} - ${Dates.short(to)} ${to.year}';

  String get medicineLine {
    final p = profile;
    if (p == null) return '';
    final m = Catalog.medicine(p.medicineId);
    final every = switch (p.everyDays) {
      1 => 'daily',
      7 => 'weekly',
      14 => 'every 2 weeks',
      _ => 'every ${p.everyDays} days',
    };
    return '${m.name} (${m.sub.split(' · ').first}) ${Catalog.mg(p.strengthMg)} mg, $every, ${Catalog.formLabel(p.form).toLowerCase()}';
  }

  String? get weightChange {
    if (weights.length < 2) return null;
    final diff = weights.last.kg - weights.first.kg;
    final pct = weights.first.kg == 0 ? 0.0 : diff / weights.first.kg * 100;
    final sign = diff < 0 ? '-' : '+';
    return '$sign${weight(diff.abs())} $unit ($sign${pct.abs().toStringAsFixed(1)}%)';
  }

  String doseLine(DoseLog d) {
    final site = d.site.isEmpty ? '' : ' · ${Catalog.siteName(d.site)}';
    final pain = d.site.isEmpty ? '' : ' · pain ${d.pain}/10';
    return '${Dates.shortWithDay(d.takenAt)}, ${Dates.time(d.takenAt)} · ${Catalog.mg(d.strengthMg)} mg$site$pain';
  }
}
