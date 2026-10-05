// Check-in nausea / mood rules. Run with:
//   fvm flutter test test/check_in_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kindose/features/check_in/check_in_controller.dart';
import 'package:kindose/models/logs.dart';
import 'package:kindose/models/user_profile.dart';
import 'package:kindose/resources/catalog.dart';
import 'package:kindose/resources/date_utils.dart';
import 'package:kindose/services/tracker_service.dart';
import 'package:kindose/widgets/mood_row.dart';
import 'package:kindose/features/today/today_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayLog nausea', () {
    test('"None" is saved, counts as a check-in, is not nausea', () {
      final key = Dates.key(DateTime.now());
      final d = DayLog.fromMap(DayLog(key: key, nausea: -1).toMap())!;
      expect(d.nausea, -1);
      expect(d.hasCheckIn, isTrue);
      expect(d.hasNausea, isFalse);
      expect(d.symptoms.contains('nausea'), isFalse);
    });

    test('mild nausea is nausea', () {
      final key = Dates.key(DateTime.now());
      final d = DayLog(key: key, nausea: 0, symptoms: const ['nausea']);
      expect(d.hasNausea, isTrue);
    });

    test('not answered is not a check-in', () {
      final d = DayLog(key: Dates.key(DateTime.now()));
      expect(d.hasCheckIn, isFalse);
      expect(d.hasNausea, isFalse);
    });
  });

  group('check-in controller', () {
    late Directory dir;
    late TrackerService tracker;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kindose_checkin_test');
      Hive.init(dir.path);
      Get.testMode = true;
      tracker = await Get.putAsync<TrackerService>(
        () => TrackerService().init(initHive: false),
      );
      await tracker.saveProfile(
        UserProfile.fromMap({'medicineId': 'mounjaro', 'everyDays': 7})!,
      );
    });

    tearDown(() async {
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    test('None, Mild … Severe select and clear', () {
      final c = Get.put(CheckInController()); // runs onInit
      expect(c.nauseaOnScreen, isNull); // nothing picked yet
      c.pickNausea(0); // None
      expect(c.nausea.value, -1);
      expect(c.nauseaOnScreen, 0);
      c.pickNausea(0); // tap again clears
      expect(c.nauseaOnScreen, isNull);
      c.pickNausea(2); // Moderate
      expect(c.nausea.value, 1);
      expect(c.nauseaOnScreen, 2);
      c.pickNausea(3); // Severe
      expect(c.anySevere, isTrue);
      c.pickNausea(0); // None after Severe
      expect(c.nauseaOnScreen, 0);
      expect(c.anySevere, isFalse);
    });

    test('a saved "None" comes back selected', () async {
      final key = Dates.key(DateTime.now());
      await tracker.saveDay(DayLog(key: key, nausea: -1));
      final c = Get.put(CheckInController()); // runs onInit
      expect(c.nauseaOnScreen, 0);
    });

    test('a saved Moderate comes back selected', () async {
      final key = Dates.key(DateTime.now());
      await tracker.saveDay(
        DayLog(key: key, nausea: 1, symptoms: const ['nausea']),
      );
      final c = Get.put(CheckInController()); // runs onInit
      expect(c.nauseaOnScreen, 2);
    });
  });

  group('mood faces', () {
    test('Today and check-in use the same words, Rough … Great', () {
      expect(TodayController.faceLabels, [
        'Rough',
        'Low',
        'Okay',
        'Good',
        'Great',
      ]);
      expect(Catalog.moods.map((m) => m.label).toList().reversed.toList(),
          TodayController.faceLabels);
    });

    testWidgets('check-in faces run Rough … Great and pick the right mood',
        (tester) async {
      int? picked;
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: MoodRow(selected: null, onPick: (i) => picked = i),
          ),
        ),
      );
      final first = tester.getTopLeft(find.text('Rough')).dx;
      final last = tester.getTopLeft(find.text('Great')).dx;
      expect(first < last, isTrue);
      await tester.tap(find.text('Great'));
      expect(picked, 0); // Catalog.moods[0] is Great
      await tester.tap(find.text('Rough'));
      expect(picked, 4);
    });
  });
}
