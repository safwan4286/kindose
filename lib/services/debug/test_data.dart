import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../tracker_service.dart';

/// Debug builds only: fills the phone with ~16 weeks of realistic logs so
/// Progress, Doses, Report and the PDF can be checked with real-looking
/// data, and puts the real data back afterwards.
///
/// * The real data is kept on the phone (settings key [_realKey]) first.
/// * While test data is on, automatic and manual backups are skipped
///   ([isOn], checked in BackendService), so it never reaches Supabase.
class TestData {
  TestData._();

  static const String onKey = 'debugTestData';
  static const String _realKey = 'debugRealData';

  static Box<dynamic> get _settings => Hive.box<dynamic>('settings');

  /// Test data is on this phone (debug builds only).
  static bool get isOn => kDebugMode && _settings.get(onKey) == true;

  /// Replaces doses, days and weights with 16 weeks of test logs.
  static Future<void> fill(TrackerService t) async {
    if (!kDebugMode) return;
    final p = t.profile.value;
    if (p == null) return;
    // Keep the real data once (filling twice keeps the first copy).
    if (_settings.get(_realKey) is! String) {
      await _settings.put(_realKey, jsonEncode(t.backupData()));
    }

    final rnd = math.Random(7);
    final today = Dates.dateOnly(DateTime.now());
    const weeks = 16;
    final start = Dates.addDays(today, -weeks * 7 + 1);

    // ---------------------------------------------------------- doses
    final med = Catalog.medicine(p.medicineId);
    final steps = med.strengths.isEmpty ? [p.strengthMg] : med.strengths;
    final doses = <String, dynamic>{};
    void addDose(DateTime at, double mg, String site, {int? pain, String? note}) {
      final id = at.microsecondsSinceEpoch.toString();
      doses[id] = DoseLog(
        id: id,
        takenAt: at,
        medicineId: p.medicineId,
        strengthMg: mg,
        site: site,
        pain: pain,
        note: note,
      ).toMap();
    }

    final tablet = p.form == 'tablet';
    final sites = Catalog.sites.map((s) => s.id).toList();
    if (p.isDaily) {
      // Daily: last 60 days, a few missed.
      for (var i = 59; i >= 0; i--) {
        if (i == 0 || rnd.nextInt(12) == 0) continue; // today open, ~8% missed
        final day = Dates.addDays(today, -i);
        final step = math.min(steps.length - 1, (59 - i) ~/ 30);
        addDose(
          Dates.atMinutes(day, p.shotMinutes + rnd.nextInt(40) - 20),
          steps[step],
          tablet ? '' : sites[i % sites.length],
        );
      }
    } else {
      // Weekly (or every N days): titrate up every 4 doses. One dose two
      // days late, one missed, one with a note.
      var day = start;
      // First dose on the usual weekday.
      while (day.weekday != p.shotWeekday) {
        day = Dates.addDays(day, 1);
      }
      var n = 0;
      while (day.isBefore(today)) {
        final step = math.min(steps.length - 1, n ~/ 4);
        if (n == 9) {
          // Missed this one.
        } else if (!Dates.addDays(day, n == 6 ? 2 : 0).isAfter(today)) {
          final late = n == 6 ? 2 : 0;
          addDose(
            Dates.atMinutes(Dates.addDays(day, late), p.shotMinutes + rnd.nextInt(50)),
            steps[step],
            tablet ? '' : sites[n % sites.length],
            pain: tablet ? null : [0, 0, 1, 0, 2][n % 5],
            note: n == 4 ? 'Felt a bit sick the day after' : null,
          );
        }
        n++;
        day = Dates.addDays(day, p.everyDays);
      }
    }

    // --------------------------------------------------------- weights
    final weights = <String, dynamic>{};
    final startKg = p.startWeightKg > 0 ? p.startWeightKg + 6 : 92.0;
    for (var d = 0; d < weeks * 7; d += 3 + rnd.nextInt(3)) {
      final date = Dates.addDays(start, d);
      // About 0.6 kg a week, slowing down, with daily noise.
      final kg = startKg - 0.62 * (d / 7) * (1 - d / (weeks * 7 * 3)) +
          (rnd.nextDouble() - 0.5) * 0.8;
      final w = WeightEntry(date: date, kg: double.parse(kg.toStringAsFixed(1)));
      weights[w.key] = w.toMap();
    }

    // ------------------------------------------------------------ days
    final days = <String, dynamic>{};
    final doseDays = <DateTime>[
      for (final m in doses.values)
        Dates.dateOnly(DateTime.fromMillisecondsSinceEpoch(m['takenAt'] as int)),
    ];
    int daysSinceDose(DateTime d) {
      var best = 99;
      for (final x in doseDays) {
        final g = Dates.daysBetween(x, d);
        if (g >= 0 && g < best) best = g;
      }
      return best;
    }

    const foods = [
      ('Greek yogurt, 1 cup, 170 g', 17),
      ('Ready-to-drink shake', 30),
      ('Chicken breast, 100 g cooked', 31),
      ('Eggs × 2', 12),
      ('Cottage cheese, ½ cup', 14),
      ('Lentil soup, 1 bowl', 12),
    ];
    for (var i = weeks * 7 - 1; i >= 0; i--) {
      final date = Dates.addDays(today, -i);
      if (i > 0 && rnd.nextInt(8) == 0) continue; // ~12% days not logged
      final after = daysSinceDose(date);
      final entries = <LogEntry>[];
      var protein = 0;
      var water = 0;
      final meals = 2 + rnd.nextInt(3);
      for (var m = 0; m < meals; m++) {
        final f = foods[rnd.nextInt(foods.length)];
        final at = Dates.atMinutes(date, 8 * 60 + m * 210 + rnd.nextInt(60));
        entries.add(LogEntry(
          id: '${at.microsecondsSinceEpoch}$m',
          at: at,
          kind: 'protein',
          amount: f.$2,
          label: f.$1,
        ));
        protein += f.$2;
      }
      final glasses = 5 + rnd.nextInt(7);
      for (var g = 0; g < glasses; g++) {
        final at = Dates.atMinutes(date, 8 * 60 + g * 70);
        entries.add(LogEntry(
          id: '${at.microsecondsSinceEpoch}w$g',
          at: at,
          kind: 'water',
          amount: 250,
        ));
        water += 250;
      }
      entries.sort((a, b) => a.at.compareTo(b.at));

      // Check-in on ~65% of days; side effects peak 1–2 days after a dose.
      final checkIn = rnd.nextInt(100) < 65;
      final rough = after <= 2 && rnd.nextInt(3) > 0;
      final nausea = !checkIn ? null : (rough ? rnd.nextInt(2) : -1);
      final symptoms = <String>[
        if (nausea != null && nausea >= 0) 'nausea',
        if (checkIn && rough && rnd.nextBool()) 'tired',
        if (checkIn && rnd.nextInt(6) == 0) 'constip',
        if (checkIn && rough && rnd.nextInt(4) == 0) 'heartburn',
      ];
      days[Dates.key(date)] = DayLog(
        key: Dates.key(date),
        proteinG: protein,
        waterMl: water,
        mood: checkIn ? (rough ? 2 + rnd.nextInt(2) : rnd.nextInt(2)) : null,
        symptoms: symptoms,
        symptomLevels: {
          for (final s in symptoms) s: s == 'nausea' ? (nausea ?? 0) + 1 : 1,
        },
        nausea: nausea,
        foodNoise: checkIn ? (after <= 3 ? 0 : 1) : null,
        appetite: checkIn ? (after <= 2 ? 0 : 1) : null,
        note: i == 12 ? 'Low appetite all day, small meals helped' : null,
        entries: entries,
      ).toMap();
    }

    // ------------------------------------------- swap in, settings kept
    final data = t.backupData();
    final boxes = Map<String, dynamic>.from(data['boxes'] as Map);
    final settings = Map<String, dynamic>.from(boxes['settings'] as Map)
      ..remove(_realKey)
      ..[onKey] = true
      ..remove('nextDoseOverride');
    // The real copy goes back in after the restore wiped the box.
    final real = _settings.get(_realKey);
    final profileBox = Map<String, dynamic>.from(boxes['profile'] as Map);
    final me = Map<String, dynamic>.from(profileBox['me'] as Map)
      ..['treatmentStartedAt'] = start.millisecondsSinceEpoch
      ..['startWeightKg'] = startKg;
    profileBox['me'] = me;
    boxes
      ..['profile'] = profileBox
      ..['doses'] = doses
      ..['days'] = days
      ..['weights'] = weights
      ..['settings'] = settings;
    await t.restoreBackup({...data, 'boxes': boxes});
    if (real is String) await _settings.put(_realKey, real);
  }

  /// Puts the real data back (as it was before [fill]).
  static Future<bool> clear(TrackerService t) async {
    final raw = _settings.get(_realKey);
    if (raw is! String) {
      await _settings.delete(onKey);
      return false;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final ok = await t.restoreBackup(data);
    if (ok) {
      await _settings.delete(_realKey);
      await _settings.delete(onKey);
    }
    return ok;
  }
}
