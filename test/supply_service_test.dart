// Pens & cost counting rules. Run with:
//   fvm flutter test test/supply_service_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kindose/models/user_profile.dart';
import 'package:kindose/resources/date_utils.dart';
import 'package:kindose/services/supply/supply_service.dart';
import 'package:kindose/services/tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late TrackerService tracker;
  late SupplyService supply;

  Future<void> start({int everyDays = 7, String form = 'pen'}) async {
    dir = await Directory.systemTemp.createTemp('kindose_supply_test');
    Hive.init(dir.path);
    Get.testMode = true;
    tracker = await Get.putAsync<TrackerService>(
      () => TrackerService().init(initHive: false),
    );
    await tracker.saveProfile(
      UserProfile.fromMap({
        'medicineId': 'mounjaro',
        'form': form,
        'strengthMg': 5.0,
        'everyDays': everyDays,
        'shotWeekday': DateTime.now().weekday,
        'shotMinutes': 9 * 60,
        'remindersOn': false,
      })!,
    );
    supply = Get.put<SupplyService>(SupplyService());
  }

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// Dose ids are the creation time in microseconds; a short pause keeps
  /// them unique and ordered.
  Future<String> logDose({Duration ago = Duration.zero}) async {
    await Future<void>.delayed(const Duration(milliseconds: 3));
    final d = await tracker.addDose(
      takenAt: DateTime.now().subtract(ago),
      site: 'belly_l',
    );
    await Future<void>.delayed(const Duration(milliseconds: 3));
    return d.id;
  }

  Future<void> setUp({int per = 4, int left = 4, int spare = 0}) async {
    await Future<void>.delayed(const Duration(milliseconds: 3));
    await supply.setUp(
      dosesPerPack: per,
      usedAlready: per - left,
      spare: spare,
    );
    await Future<void>.delayed(const Duration(milliseconds: 3));
  }

  group('set up and counting', () {
    test('not set up: nothing counted', () async {
      await start();
      expect(supply.isSetUp, isFalse);
      expect(supply.runningLow, isFalse);
    });

    test('a full new pen', () async {
      await start();
      await setUp(per: 4, left: 4);
      expect(supply.leftInPack, 4);
      expect(supply.usedInPack, 0);
      expect(supply.dosesLeft, 4);
    });

    test('"left now" from the set-up sheet', () async {
      await start();
      await setUp(per: 4, left: 2, spare: 1);
      expect(supply.leftInPack, 2);
      expect(supply.dosesLeft, 6);
    });

    test('each logged dose counts down, undo counts back up', () async {
      await start();
      await setUp(per: 4, left: 4);
      final id = await logDose();
      expect(supply.leftInPack, 3);
      await tracker.removeDose(id);
      expect(supply.leftInPack, 4);
    });

    test('dose logged after set-up with an earlier time still counts', () async {
      await start();
      await setUp(per: 4, left: 4);
      await logDose(ago: const Duration(hours: 3));
      expect(supply.leftInPack, 3);
    });

    test('dose logged before set-up (onboarding last dose) does not count',
        () async {
      await start();
      await logDose(ago: const Duration(days: 6));
      await setUp(per: 4, left: 4);
      expect(supply.leftInPack, 4);
    });

    test('old dose back-logged after set-up does not count', () async {
      await start();
      await setUp(per: 4, left: 4);
      await logDose(ago: const Duration(days: 10));
      expect(supply.leftInPack, 4);
    });

    test('editing a dose time keeps the count', () async {
      await start();
      await setUp(per: 4, left: 4);
      final id = await logDose();
      final d = tracker.doses.firstWhere((x) => x.id == id);
      await tracker.updateDose(
        d.copyWith(takenAt: d.takenAt.subtract(const Duration(hours: 5))),
      );
      expect(supply.leftInPack, 3);
    });
  });

  group('spare pens', () {
    test('empty pen with spares: count goes on without "Start a new pen"',
        () async {
      await start();
      await setUp(per: 4, left: 1, spare: 1);
      expect(supply.dosesLeft, 5);
      await logDose(); // last dose of the current pen
      expect(supply.leftInPack, 0);
      expect(supply.spareLeft, 1);
      expect(supply.dosesLeft, 4);
      final id = await logDose(); // first dose from the spare
      expect(supply.leftInPack, 3);
      expect(supply.spareLeft, 0);
      expect(supply.dosesLeft, 3);
      await tracker.removeDose(id); // undo puts the spare back
      expect(supply.leftInPack, 0);
      expect(supply.spareLeft, 1);
    });

    test('supply never goes below zero', () async {
      await start();
      await setUp(per: 2, left: 1);
      await logDose();
      await logDose();
      await logDose();
      expect(supply.leftInPack, 0);
      expect(supply.dosesLeft, 0);
      expect(supply.runningLow, isTrue);
    });

    test('start a new pen uses one spare; undo restores it', () async {
      await start();
      await setUp(per: 4, left: 0, spare: 2);
      final before = supply.snapshot();
      await supply.startNewPack();
      expect(supply.leftInPack, 4);
      expect(supply.spareLeft, 1);
      await supply.restore(before); // Undo on the toast
      expect(supply.leftInPack, 0);
      expect(supply.spareLeft, 2);
    });

    test('start a new pen after a spare was opened by the count', () async {
      await start();
      await setUp(per: 4, left: 1, spare: 2);
      await logDose();
      await logDose(); // opens spare #1 → 3 left, 1 spare
      expect(supply.leftInPack, 3);
      expect(supply.spareLeft, 1);
      await supply.startNewPack(); // throws away the opened one
      expect(supply.leftInPack, 4);
      expect(supply.spareLeft, 0);
    });

    test('spare stepper works from what the screen shows', () async {
      await start();
      await setUp(per: 4, left: 1, spare: 1);
      await logDose();
      await logDose(); // spare opened → 0 spare shown
      expect(supply.spareLeft, 0);
      await supply.setSpare(supply.spareLeft + 1);
      expect(supply.spareLeft, 1);
      expect(supply.leftInPack, 3);
    });
  });

  group('fix count', () {
    test('sets what is left and keeps counting', () async {
      await start();
      await setUp(per: 4, left: 4);
      await logDose();
      await supply.setLeftInPack(2);
      expect(supply.leftInPack, 2);
      await logDose();
      expect(supply.leftInPack, 1);
    });
  });

  group('refill reminder threshold', () {
    test('weekly pens: low at 1 dose left and no spare', () async {
      await start();
      await setUp(per: 4, left: 2);
      expect(supply.runningLow, isFalse);
      await logDose();
      expect(supply.runningLow, isTrue);
    });

    test('a spare pen means not low', () async {
      await start();
      await setUp(per: 4, left: 1, spare: 1);
      expect(supply.runningLow, isFalse);
    });

    test('daily tablets: low at a week left', () async {
      await start(everyDays: 1, form: 'tablet');
      await setUp(per: 30, left: 8);
      expect(supply.lowAt, 7);
      expect(supply.runningLow, isFalse);
      await logDose();
      expect(supply.runningLow, isTrue);
    });
  });

  group('dates', () {
    test('pen and supply dates follow the dose schedule', () async {
      await start();
      await setUp(per: 4, left: 3, spare: 1);
      final next = Dates.dateOnly(tracker.nextDoseAt(DateTime.now())!);
      expect(supply.packLastsUntil, next.add(const Duration(days: 14)));
      expect(supply.nextPackNeededOn, next.add(const Duration(days: 21)));
      expect(supply.supplyLastsUntil, next.add(const Duration(days: 42)));
    });
  });

  group('purchases and spend', () {
    Purchase buy(String id, int packs, double price, DateTime date) =>
        Purchase(id: id, date: date, packs: packs, price: price);

    test('a purchase adds spares; removing it takes them off', () async {
      await start();
      await setUp(per: 4, left: 4);
      await supply.addPurchase(buy('a', 2, 1000, DateTime.now()));
      expect(supply.spareLeft, 2);
      final taken = await supply.removePurchase('a');
      expect(taken, 2);
      expect(supply.spareLeft, 0);
    });

    test('removing never takes off pens already used', () async {
      await start();
      await setUp(per: 4, left: 4);
      await supply.addPurchase(buy('a', 2, 1000, DateTime.now()));
      await supply.setSpare(1);
      expect(await supply.removePurchase('a'), 1);
      expect(supply.spareLeft, 0);
    });

    test('spend this month, per dose and money text', () async {
      await start();
      await setUp(per: 4, left: 4);
      final now = DateTime.now();
      await supply.addPurchase(buy('a', 1, 1079, now));
      await supply.addPurchase(buy('b', 1, 23.5, DateTime(2020, 1, 5)));
      expect(supply.spendIn(now.year, now.month), 1079);
      expect(supply.totalSpend, 1102.5);
      expect(supply.perDose, closeTo(1102.5 / 8, 0.001));
      await supply.setCurrency(r'$');
      expect(supply.money(1079), r'$1,079');
      expect(supply.money(23.5), r'$23.50');
    });
  });

  group('delete all', () {
    // TrackerService.deleteAll clears the settings box (it also resets the
    // app theme, which needs a running app, so the box is cleared here).
    test('clears the pen set-up', () async {
      await start();
      await setUp(per: 4, left: 2, spare: 3);
      await Hive.box<dynamic>('settings').clear();
      supply.load();
      expect(supply.isSetUp, isFalse);
      expect(supply.spareLeft, 0);
    });
  });
}
