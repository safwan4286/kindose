// Timed paywall offer and free-week Plus prompts. Run with:
//   fvm flutter test test/offer_upsell_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kindose/models/logs.dart';
import 'package:kindose/models/user_profile.dart';
import 'package:kindose/resources/date_utils.dart';
import 'package:kindose/services/offers/offer_config.dart';
import 'package:kindose/services/offers/offer_service.dart';
import 'package:kindose/services/plus/access_service.dart';
import 'package:kindose/services/plus/plus_access.dart';
import 'package:kindose/services/tracker_service.dart';
import 'package:kindose/services/upsell/upsell_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? dir;
  late TrackerService t;

  Future<void> start() async {
    final d = await Directory.systemTemp.createTemp('kindose_offer_test');
    dir = d;
    Hive.init(d.path);
    Get.testMode = true;
    PlusAccess.active.value = false;
    t = await Get.putAsync<TrackerService>(
      () => TrackerService().init(initHive: false),
    );
    await t.saveProfile(
      UserProfile.fromMap({
        'medicineId': 'mounjaro',
        'form': 'pen',
        'strengthMg': 5.0,
        'everyDays': 7,
        'shotWeekday': DateTime.now().weekday,
        'shotMinutes': 9 * 60,
        'startWeightKg': 80.0,
        'heightCm': 175.0,
        'useKg': true,
      })!,
    );
  }

  tearDown(() async {
    PlusAccess.active.value = false;
    final d = dir;
    if (d == null) return;
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (d.existsSync()) await d.delete(recursive: true);
    dir = null;
  });

  group('offer config', () {
    test('missing mode keeps the one-time rule', () {
      expect(OfferConfig.fromJson({}).mode, OfferMode.once);
      expect(OfferConfig.fromJson({'mode': 'nonsense'}).mode, OfferMode.once);
    });

    test('reads timer mode and hours', () {
      final c = OfferConfig.fromJson({'mode': 'timer', 'timer_hours': 24});
      expect(c.mode, OfferMode.timer);
      expect(c.timerHours, 24);
      expect(OfferConfig.fromJson({}).trigger, OfferTrigger.weekEnd);
      expect(
        OfferConfig.fromJson({'trigger': 'home_first'}).trigger,
        OfferTrigger.homeFirst,
      );
      expect(
        OfferConfig.fromJson({'mode': 'until_claimed'}).mode,
        OfferMode.untilClaimed,
      );
    });
  });

  group('offer service', () {
    test('once: shows a single time', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({'trigger': 'paywall_close'});
      expect(await o.onPaywallClosed(fromOnboarding: false), isTrue);
      expect(await o.onPaywallClosed(fromOnboarding: false), isFalse);
    });

    test('timer: every close inside the window, none after', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({
        'trigger': 'paywall_close',
        'mode': 'timer',
        'timer_hours': 24,
      });
      expect(await o.onPaywallClosed(fromOnboarding: false), isTrue);
      expect(o.endsAt, isNotNull);
      expect(await o.onPaywallClosed(fromOnboarding: false), isTrue);
      expect(o.bannerVisible, isTrue);
      // Move the window start back past 24 hours.
      final past = DateTime.now().subtract(const Duration(hours: 25));
      o.startedAt.value = past;
      await Hive.box<dynamic>('settings')
          .put('offerStartedAt', past.millisecondsSinceEpoch);
      expect(await o.onPaywallClosed(fromOnboarding: false), isFalse);
      expect(o.bannerVisible, isFalse);
    });

    test('until claimed: keeps showing, stops with Plus', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({'trigger': 'paywall_close', 'mode': 'until_claimed'});
      expect(await o.onPaywallClosed(fromOnboarding: false), isTrue);
      expect(await o.onPaywallClosed(fromOnboarding: false), isTrue);
      PlusAccess.active.value = true;
      expect(await o.onPaywallClosed(fromOnboarding: false), isFalse);
    });

    test('default trigger: paywall close alone never shows it', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({'mode': 'timer'});
      expect(o.config.value.trigger, OfferTrigger.weekEnd);
      expect(await o.onPaywallClosed(fromOnboarding: true), isFalse);
      expect(await o.onPaywallClosed(fromOnboarding: false), isFalse);
    });

    test('week end: waits for the last day, then the window opens', () async {
      await start();
      final a = Get.put<AccessService>(AccessService().init());
      final o = Get.put(OfferService());
      o.applyRemote({'mode': 'timer'});
      // Free week running with 7 days left: not yet.
      await t.addDose(takenAt: DateTime.now(), site: 'lbelly');
      expect(await o.onHome(), isFalse);
      // Free week over.
      a.applyRemote({'free_days': 0, 'gating_on': true});
      expect(await o.onHome(), isTrue);
      expect(o.endsAt, isNotNull);
      // Shown once on Home; closing the paywall brings it back.
      expect(await o.onHome(), isFalse);
      expect(await o.onPaywallClosed(fromOnboarding: false), isTrue);
    });

    test('week end: nothing before the free week starts', () async {
      await start();
      Get.put<AccessService>(AccessService().init());
      final o = Get.put(OfferService());
      expect(await o.onHome(), isFalse);
    });

    test('home first: shows on the first Home visit', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({'trigger': 'home_first', 'mode': 'timer'});
      expect(await o.onHome(), isTrue);
      expect(await o.onHome(), isFalse);
    });

    test('home trigger never shows for Plus users', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({'trigger': 'home_first'});
      PlusAccess.active.value = true;
      expect(await o.onHome(), isFalse);
    });

    test('disabled: never shows', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({'enabled': false, 'mode': 'timer'});
      expect(await o.onPaywallClosed(fromOnboarding: false), isFalse);
    });

    test('banner can be hidden', () async {
      await start();
      final o = Get.put(OfferService());
      o.applyRemote({'trigger': 'paywall_close', 'mode': 'timer'});
      await o.onPaywallClosed(fromOnboarding: false);
      await o.hideBanner();
      expect(o.bannerVisible, isFalse);
    });
  });

  group('plus prompts', () {
    Future<UpsellService> upsell() async {
      await start();
      Get.put<AccessService>(AccessService().init());
      return Get.put(UpsellService());
    }

    test('first dose card, once', () async {
      final u = await upsell();
      await t.addDose(takenAt: DateTime.now(), site: 'lbelly');
      expect(await u.doseDoneCard(), 'first_dose');
      await u.debugReset();
      await Hive.box<dynamic>('settings').put('upsellShown', ['first_dose']);
      expect(await u.doseDoneCard(), isNull);
    });

    test('at most one prompt a day', () async {
      final u = await upsell();
      await t.addDose(takenAt: DateTime.now(), site: 'lbelly');
      expect(await u.doseDoneCard(), 'first_dose');
      expect(await u.afterLog(), isFalse);
    });

    test('never on a severe day', () async {
      final u = await upsell();
      await t.addDose(takenAt: DateTime.now(), site: 'lbelly');
      await t.saveDay(
        DayLog(
          key: Dates.key(DateTime.now()),
          symptoms: const ['nausea'],
          nausea: 2,
        ),
      );
      expect(await u.doseDoneCard(), isNull);
    });

    test('never for Plus users', () async {
      final u = await upsell();
      await t.addDose(takenAt: DateTime.now(), site: 'lbelly');
      PlusAccess.active.value = true;
      expect(await u.doseDoneCard(), isNull);
    });

    test('end-of-week screen waits for the last days', () async {
      final u = await upsell();
      await t.addDose(takenAt: DateTime.now(), site: 'lbelly');
      // 7 days left, limit is 2: nothing yet.
      expect(await u.afterLog(), isFalse);
    });

    test('remote switch turns prompts off', () async {
      final u = await upsell();
      u.applyRemote({'enabled': false});
      await t.addDose(takenAt: DateTime.now(), site: 'lbelly');
      expect(await u.doseDoneCard(), isNull);
    });
  });
}
