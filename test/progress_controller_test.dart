// Progress tab numbers. Run with:
//   fvm flutter test test/progress_controller_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kindose/features/progress/progress_controller.dart';
import 'package:kindose/models/logs.dart';
import 'package:kindose/models/user_profile.dart';
import 'package:kindose/resources/date_utils.dart';
import 'package:kindose/services/tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late TrackerService t;
  late ProgressController c;
  final today = Dates.dateOnly(DateTime.now());
  DateTime daysAgo(int n) =>
      today.subtract(Duration(days: n)).add(const Duration(hours: 9));

  Future<void> start({
    int everyDays = 7,
    double strength = 5,
    double startKg = 80,
    double? goalKg = 72,
    String form = 'pen',
  }) async {
    dir = await Directory.systemTemp.createTemp('kindose_progress_test');
    Hive.init(dir.path);
    Get.testMode = true;
    t = await Get.putAsync<TrackerService>(
      () => TrackerService().init(initHive: false),
    );
    await t.saveProfile(
      UserProfile.fromMap({
        'medicineId': 'mounjaro',
        'form': form,
        'strengthMg': strength,
        'everyDays': everyDays,
        'shotWeekday': today.weekday,
        'shotMinutes': 9 * 60,
        'startWeightKg': startKg,
        'goalWeightKg': goalKg,
        'heightCm': 175.0,
        'useKg': true,
        'proteinGoalG': 100,
        'waterGoalMl': 2000,
      })!,
    );
    c = Get.put<ProgressController>(ProgressController());
  }

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> dose(int ago, {double? mg, String site = 'lbelly'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await t.addDose(takenAt: daysAgo(ago), site: site, strengthMg: mg);
  }

  group('weight', () {
    test('one weigh-in: no change, no trend yet', () async {
      await start();
      await t.addWeight(80, today);
      expect(c.changeNumber, '±0.0');
      expect(c.points.length, 1);
      expect(c.toGoalLabel, '8.0 kg to goal');
    });

    test('loss shows a minus sign and percent of start', () async {
      await start();
      await t.addWeight(80, daysAgo(14));
      await t.addWeight(76, today);
      expect(c.changeNumber, '−4.0');
      expect(c.changeLine, '80.0 → 76.0 kg · 5.0% of your start');
    });

    test('lb users see pounds', () async {
      await start();
      await t.saveProfile(t.profile.value!.copyWith(useKg: false));
      await t.addWeight(80, daysAgo(7));
      await t.addWeight(79, today);
      expect(c.changeNumber, '−2.2');
      expect(c.unit, 'lb');
    });

    test('goal reached', () async {
      await start(goalKg: 75);
      await t.addWeight(74, today);
      expect(c.toGoalLabel, 'Goal reached');
    });

    test('4 weeks hides older weigh-ins; all time shows them', () async {
      await start();
      await t.addWeight(82, daysAgo(60));
      await t.addWeight(80, daysAgo(10));
      await t.addWeight(79, today);
      expect(c.points.length, 2);
      c.pickRange(ProgressRange.all);
      expect(c.points.length, 3);
    });
  });

  group('doses', () {
    test('weekly: on time within a day, late counts as not on time',
        () async {
      await start();
      await dose(21);
      await dose(14); // on time
      await dose(5); // 9 days later: late
      expect(c.onTimeValue, '2/3');
    });

    test('weekly: only doses in the chosen range count, late after a break', () async {
      await start();
      await dose(70);
      await dose(63);
      await dose(14);
      await dose(7);
      await dose(0);
      // 4 weeks: 14, 7 and today. The dose 14 days ago came 7 weeks after
      // the one before it, so it wasn't on time.
      expect(c.onTimeValue, '2/3');
      c.pickRange(ProgressRange.all);
      expect(c.onTimeValue, '4/5');
    });

    test('daily: days taken since the first dose, not a fixed 28', () async {
      await start(everyDays: 1, form: 'tablet');
      await dose(4, site: '');
      await dose(3, site: '');
      await dose(1, site: '');
      await dose(0, site: '');
      expect(c.onTimeValue, '4/5');
    });

    test('current dose: last logged strength and since when', () async {
      await start(strength: 5);
      await dose(14, mg: 2.5);
      await dose(7, mg: 5);
      await dose(0, mg: 5);
      expect(c.currentDose, '5 mg');
      expect(c.currentDoseSince, 'since ${Dates.short(daysAgo(7))}');
    });

    test('current dose: a plan change shows "from next dose"', () async {
      await start(strength: 5);
      await dose(7, mg: 5);
      await t.saveProfile(t.profile.value!.copyWith(strengthMg: 7.5));
      expect(c.currentDose, '7.5 mg');
      expect(c.currentDoseSince, 'from next dose');
    });

    test('next dose further than a week shows a date', () async {
      await start(everyDays: 14);
      await dose(0);
      expect(c.nextDoseValue, Dates.short(t.nextDoseAt()!));
    });

    test('spots by area count only the chosen range', () async {
      await start();
      await dose(60, site: 'larm');
      await dose(14, site: 'lbelly');
      await dose(7, site: 'rthigh');
      await dose(0, site: 'lbellyU');
      expect(c.siteAreas, [('Belly', 2), ('Thighs', 1), ('Arms', 0)]);
      c.pickRange(ProgressRange.all);
      expect(c.siteAreas, [('Belly', 2), ('Thighs', 1), ('Arms', 1)]);
    });
  });

  group('protein and water', () {
    test('nothing logged', () async {
      await start();
      expect(
        c.barsHeadline(c.proteinBars, water: false),
        'Nothing logged this week yet',
      );
    });

    test('goal days and average of logged days', () async {
      await start();
      await t.addProtein(120, daysAgo(1));
      await t.addProtein(60, today);
      expect(
        c.barsHeadline(c.proteinBars, water: false),
        'Goal reached 1 of 7 days · avg 90 g',
      );
      expect(c.proteinBars.length, 7);
      expect(c.proteinBars.last.value, 60);
    });
  });

  group('how you felt', () {
    test('no check-ins', () async {
      await start();
      expect(c.feelHeadline, startsWith('Check in a few times'));
    });

    test('nausea "None" counts as a fine day', () async {
      await start();
      await t.saveDay(DayLog(key: Dates.key(today), nausea: -1));
      expect(c.feelHeadline, 'Mostly fine.');
    });

    test('pattern needs 3 dose weeks', () async {
      await start();
      await dose(0);
      expect(c.patternLine, isNull);
    });
  });
}
