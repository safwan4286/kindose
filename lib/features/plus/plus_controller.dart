import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/offers/offer_service.dart';
import '../../services/plus/access_service.dart';
import '../../services/purchases/purchase_service.dart';
import '../offer/offer_controller.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

class PlusPlan {
  const PlusPlan(
    this.id,
    this.name,
    this.sub,
    this.price,
    this.per, {
    this.badge,
  });

  final String id;
  final String name;
  final String sub;

  /// The amount actually billed. Stores require this to be the most
  /// prominent price, so it is the big number on the tile.
  final String price;
  final String per;
  final String? badge;
}

class PlusPerk {
  const PlusPerk(
    this.icon,
    this.title,
    this.sub,
    this.focus, {
    this.weeklyOnly = false,
  });

  final String icon;
  final String title;
  final String sub;

  /// "What to help with" answers this perk matches, for the FOR YOU tag.
  final Set<String> focus;

  /// Hidden for daily plans (the dose-week pattern needs weekly doses).
  final bool weeklyOnly;
}

/// Paywall. No store trial: everyone gets a free week in the app first
/// (AccessService). Purchases go through RevenueCat ([PurchaseService]);
/// plan prices come from the store, [fallbackPlans] only until they load.
class PlusController extends GetxController {
  static const List<PlusPlan> fallbackPlans = [
    PlusPlan(
      'year',
      'Yearly',
      '\$4.17 a month',
      '\$49.99',
      'a year',
      badge: 'SAVE 72%',
    ),
    PlusPlan('month', 'Monthly', 'Cancel anytime', '\$14.99', 'a month'),
  ];

  static const List<PlusPerk> perks = [
    // Only perks that work at launch (store rule). Backup is free with
    // sign-in; "Snap a meal" comes back here in v1.1.
    PlusPerk(
      Img3d.syringe,
      'Dose log and spot rotation',
      'Every dose, spot and how it felt',
      {'remember', 'nerves'},
    ),
    PlusPerk(
      Img3d.biceps,
      'Protein & water coach',
      'Next bite ideas and gentle reminders you control',
      {'muscle', 'noise'},
    ),
    PlusPerk(
      Img3d.nauseated,
      'Your pattern',
      'See which day after your dose is hardest for you',
      {'nausea'},
      weeklyOnly: true,
    ),
    PlusPerk(
      Img3d.chartDown,
      'Progress and doctor report',
      'Charts since day one and a PDF for your visit',
      {'progress'},
    ),
    PlusPerk(
      Img3d.moneyBag,
      'Pens and cost',
      'Doses left, refill nudge, monthly spend',
      {'cost'},
    ),
  ];

  final RxString selected = 'year'.obs;

  /// Scroll of the paywall list. It lives here, not in the screen, because
  /// PlusScreen is a GetView (stateless, no initState/dispose). GetX calls
  /// onClose when the page is removed, so it is always disposed.
  final ScrollController scrollController = ScrollController();

  /// True once the list has scrolled a little. Only flips when the value
  /// changes, so the screen doesn't rebuild on every pixel.
  final RxBool scrolled = false.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // If scrolled above top, snap back to 0
    if (scrollController.offset < 0) {
      scrollController.jumpTo(0);
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  /// True when opened at the end of onboarding: closing goes to Home.
  late final bool fromOnboarding = Get.arguments == true;

  late final Set<String> _focus = {
    ...?Get.find<TrackerService>().profile.value?.focus,
  };

  bool isForYou(PlusPerk perk) => perk.focus.any(_focus.contains);

  /// Perks for this plan: no dose-week pattern for daily plans.
  List<PlusPerk> get shownPerks {
    final daily =
        Get.find<TrackerService>().profile.value?.isDaily ?? false;
    return [
      for (final p in perks)
        if (!daily || !p.weeklyOnly) p,
    ];
  }

  bool get isYearly => selected.value == 'year';

  PurchaseService? get _purchases =>
      Get.isRegistered<PurchaseService>() ? Get.find<PurchaseService>() : null;

  /// Yearly + monthly with store prices, or [fallbackPlans].
  List<PlusPlan> get plans {
    final ps = _purchases;
    final y = ps?.package('year')?.storeProduct;
    final m = ps?.package('month')?.storeProduct;
    if (y == null || m == null) return fallbackPlans;
    final save = m.price > 0
        ? ((1 - y.price / (m.price * 12)) * 100).round()
        : 0;
    return [
      PlusPlan(
        'year',
        'Yearly',
        '${PurchaseService.monthlyOf(y.priceString, y.price)} a month',
        y.priceString,
        'a year',
        badge: save > 0 ? 'SAVE $save%' : null,
      ),
      PlusPlan('month', 'Monthly', 'Cancel anytime', m.priceString, 'a month'),
    ];
  }

  PlusPlan get _plan => plans.firstWhere(
    (p) => p.id == selected.value,
    orElse: () => plans.first,
  );

  /// True while a purchase or restore runs.
  bool get busy => _purchases?.busy.value ?? false;

  String get cta =>
      'Get Plus · ${_plan.price} / ${isYearly ? 'year' : 'month'}';

  String get fine => isYearly
      ? 'Billed now. Renews yearly until you cancel.'
      : 'Billed now. Renews monthly until you cancel.';

  AccessService get _access => Get.find<AccessService>();

  /// The free-week line in the hero.
  String get freeLine {
    if (_access.locked)
      return 'Your free week has ended.\nYour data is safe. Pick a plan to keep logging.';
    if (!_access.started.value) {
      return 'Your first week is free. No card needed.\nIt starts with your first dose.';
    }
    return 'Your first week is free. No card needed.\nFree until ${Dates.shortWithDay(_access.endsAt.value)}';
  }

  /// The text button under the plans (it closes the paywall).
  String get secondary {
    if (fromOnboarding) return 'Start my free week';
    return _access.locked ? 'Not now' : 'Keep my free week';
  }

  void pick(String id) {
    if (selected.value == id) return;
    Haptics.instance.selectionClick();
    selected.value = id;
  }

  Future<void> subscribe() async {
    final ps = _purchases;
    final pkg = ps?.package(selected.value);
    if (ps == null || !ps.ready || pkg == null) {
      showToast(
        "Plans aren't available right now. Check your connection and try again.",
      );
      if (ps != null) unawaited(ps.loadOfferings());
      return;
    }
    Haptics.instance.lightImpact();
    switch (await ps.buy(pkg)) {
      case PurchaseOutcome.success:
        Haptics.instance.mediumImpact();
        showToast('Welcome to Kindose Plus');
        _leave();
      case PurchaseOutcome.pending:
        showToast(
          'Your payment is pending. Plus turns on as soon as it goes through.',
        );
      case PurchaseOutcome.failed:
        showToast("The purchase didn't go through. Please try again.");
      case PurchaseOutcome.unavailable:
        showToast("Purchases aren't available right now.");
      case PurchaseOutcome.cancelled:
        break;
    }
  }

  Future<void> restore() async {
    Haptics.instance.selectionClick();
    final ps = _purchases;
    if (ps == null || !ps.ready) {
      showToast("Purchases aren't available right now.");
      return;
    }
    final back = await ps.restore();
    if (back == true) {
      showToast('Kindose Plus restored');
      _leave();
    } else if (back == false) {
      showToast('No Plus purchase found for this store account.');
    } else {
      showToast("Couldn't restore right now. Please try again.");
    }
  }

  /// After a purchase or restore: straight on, no offer.
  void _leave() {
    if (fromOnboarding) {
      Get.offAllNamed<void>(Routes.home);
    } else {
      popRoute();
    }
  }

  bool _closing = false;

  /// Close (X, back gesture). If the offer rules allow, the paywall is
  /// replaced by the one-time discount screen instead.
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    Haptics.instance.selectionClick();
    // Only offer what can really be bought (debug builds always show it,
    // so the screen can be checked before the offer product exists).
    final offers = Get.find<OfferService>();
    final canOffer =
        kDebugMode ||
        _purchases?.package(
              'year',
              offeringId: offers.config.value.offeringId,
            ) !=
            null;
    final showOffer =
        canOffer &&
        await offers.onPaywallClosed(fromOnboarding: fromOnboarding);
    if (showOffer) {
      Get.offNamed<void>(
        Routes.offer,
        arguments: OfferArgs(fromOnboarding: fromOnboarding),
      );
    } else if (fromOnboarding) {
      Get.offAllNamed<void>(Routes.home);
    } else {
      popRoute();
    }
  }
}
