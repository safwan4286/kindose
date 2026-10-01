import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/offers/offer_config.dart';
import '../../services/offers/offer_service.dart';
import '../../services/purchases/purchase_service.dart';
import '../../widgets/toast.dart';

/// Passed to [Routes.offer].
class OfferArgs {
  const OfferArgs({required this.fromOnboarding});

  /// True when the paywall came at the end of onboarding, so closing the
  /// offer goes on to Home instead of back.
  final bool fromOnboarding;
}

/// Discount offer shown after someone closes the paywall. What it says and
/// when it shows come from [OfferService] (backend-driven later).
class OfferController extends GetxController {
  final OfferConfig config = Get.find<OfferService>().config.value;

  late final bool fromOnboarding =
      Get.arguments is OfferArgs && (Get.arguments as OfferArgs).fromOnboarding;

  /// Blocks double taps while a purchase runs.
  final RxBool busy = false.obs;
  bool _closing = false;

  /// Never claim "one time only" unless the rules really make it so.
  String get subtitle {
    if (config.maxShows == 1 ||
        config.subtitle != OfferConfig.defaults.subtitle) {
      return config.subtitle;
    }
    return 'A thank-you for trying Kindose.';
  }

  PurchaseService? get _purchases =>
      Get.isRegistered<PurchaseService>() ? Get.find<PurchaseService>() : null;

  /// The yearly package of the offer offering (`offer_30`).
  Package? get _offer => _purchases?.package('year', offeringId: config.offeringId);

  /// Store prices when loaded; the config strings until then.
  String get offerPrice {
    final p = _offer?.storeProduct;
    if (p == null) return config.offerPrice;
    return p.introductoryPrice?.priceString ?? p.priceString;
  }

  String get regularPrice =>
      _purchases?.package('year')?.storeProduct.priceString ?? config.regularPrice;

  String get perMonth {
    final p = _offer?.storeProduct;
    if (p == null) return config.perMonth;
    final intro = p.introductoryPrice;
    return '${PurchaseService.monthlyOf(intro?.priceString ?? p.priceString, intro?.price ?? p.price)}/mo';
  }

  Future<void> claim() async {
    if (busy.value) return;
    final ps = _purchases;
    final pkg = _offer;
    if (ps == null || !ps.ready || pkg == null) {
      showToast("This offer isn't available right now.");
      return;
    }
    busy.value = true;
    try {
      Haptics.instance.mediumImpact();
      switch (await ps.buy(pkg)) {
        case PurchaseOutcome.success:
          showToast('Welcome to Kindose Plus');
          close();
        case PurchaseOutcome.pending:
          showToast('Your payment is pending. Plus turns on as soon as it goes through.');
        case PurchaseOutcome.failed:
          showToast("The purchase didn't go through. Please try again.");
        case PurchaseOutcome.unavailable:
          showToast("Purchases aren't available right now.");
        case PurchaseOutcome.cancelled:
          break;
      }
    } finally {
      busy.value = false;
    }
  }

  void close() {
    if (_closing) return;
    _closing = true;
    Haptics.instance.selectionClick();
    if (fromOnboarding) {
      Get.offAllNamed<void>(Routes.home);
    } else {
      popRoute();
    }
  }
}
