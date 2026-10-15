// Dose edge cases: late doses, skipping, moved dates, undo. Run with:
//   fvm flutter test test/dose_flow_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kindose/models/user_profile.dart';
import 'package:kindose/resources/date_utils.dart';
import 'package:kindose/services/tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late TrackerService t;
  final today = Dates.dateOnly(DateTime.now());
  DateTime daysAgo(int n) =>
      today.subtract(Duration(days: n)).add(const Duration(hours: 9));

  Future<void> start({int everyDays = 7, int? weekday, DateTime? planned}) async {
    dir = await Directory.systemTemp.createTemp('kindose_dose_flow_test');
    Hive.init(dir.path);
    Get.testMode = true;
    t = await Get.putAsync<TrackerService>(
      () => TrackerService().init(initHive: false),
    );
    await t.saveProfile(
      UserProfile.fromMap({
        'medicineId': 'mounjaro',
        'form': 'pen',
        'strengthMg': 5.0,
        'everyDays': everyDays,
        'shotWeekday': weekday ?? today.weekday,
        'shotMinutes': 9 * 60,
        'startWeightKg': 80.0,
        'useKg': true,
        if (planned != null)
          'plannedFirstDose': planned.millisecondsSinceEpoch,
      })!,
    );
  }

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> dose(int ago) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await t.addDose(takenAt: daysAgo(ago), site: 'lbelly');
  }

  group('on time', () {
    test('the dose after a late one is on time when the day snapped back',
        () async {
      await start();
      // Usual day = today's weekday. 14 ago (on time), 5 ago (2 days
      // late), today (5 days later: the day the app asked for).
      final late = daysAgo(5);
      final next = t.nextDoseAfter(late)!;
      expect(Dates.sameDay(next, today), isTrue);
      expect(t.onTimeAfter(late, daysAgo(0)), isTrue);
      expect(t.onTimeAfter(daysAgo(14), late), isFalse);
    });

    test('streak counts through a snapped-back dose', () async {
      await start();
      await dose(21);
      await dose(14);
      await dose(5); // late: the streak starts again here
      await dose(0); // back on the usual day: counts
      expect(t.onTimeStreak, 2);
    });
  });

  group('skip', () {
    test('skipping an overdue weekly dose moves to the next planned day',
        () async {
      await start();
      await dose(14); // next was due 7 days ago
      final due = t.nextDoseAt()!;
      expect(Dates.dateOnly(due).isBefore(today), isTrue);
      final next = t.nextPlannedAfterSkip(due);
      expect(next, today);
      await t.moveNextDose(next);
      expect(Dates.sameDay(t.nextDoseAt()!, today), isTrue);
    });
  });

  group('moved date', () {
    test('a forgotten older dose keeps the moved date', () async {
      await start();
      await dose(7);
      final moved = Dates.addDays(today, 3);
      await t.moveNextDose(moved);
      await dose(20); // filled in from Day view
      expect(t.nextDoseOverride.value, moved);
    });

    test('the newest dose uses the moved date up', () async {
      await start();
      await dose(7);
      await t.moveNextDose(today);
      await dose(0);
      expect(t.nextDoseOverride.value, isNull);
    });

    test('undo of a just-logged dose puts the moved date back', () async {
      await start();
      await dose(7);
      await t.moveNextDose(today);
      await dose(0);
      final d = t.lastDose!;
      t.lastLogUndo = DoseUndo(doseId: d.id, movedBefore: today);
      final u = await t.removeDoseAndRestore(d.id);
      expect(t.nextDoseOverride.value, today);
      await t.restoreDose(d, u);
      expect(t.lastDose!.id, d.id);
      expect(t.nextDoseOverride.value, isNull);
    });
  });

  group('first dose', () {
    test('a missed planned first dose shows as overdue, not next week',
        () async {
      final planned = Dates.addDays(today, -2);
      await start(planned: planned, weekday: planned.weekday);
      expect(Dates.sameDay(t.nextDoseAt()!, planned), isTrue);
    });
  });
}
