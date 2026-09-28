import 'package:get/get.dart';

import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/offers/offer_config.dart';
import '../../services/offers/offer_service.dart';
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

  late final bool fromOnboarding = Get.arguments is OfferArgs && (Get.arguments as OfferArgs).fromOnboarding;

  /// Blocks double taps while a purchase runs.
  final RxBool busy = false.obs;
  bool _closing = false;

  /// Never claim "one time only" unless the rules really make it so.
  String get subtitle {
    if (config.maxShows == 1 || config.subtitle != OfferConfig.defaults.subtitle) {
      return config.subtitle;
    }
    return 'A thank-you for trying Kindose.';
  }

  /// TODO(purchases): buy [OfferConfig.productId] with RevenueCat. On
  /// success set PlusAccess.active and call [close].
  Future<void> claim() async {
    if (busy.value) return;
    busy.value = true;
    try {
      Haptics.instance.mediumImpact();
      showToast('Subscriptions are not connected yet. Everything free works fully.');
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
