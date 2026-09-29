import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/offers/offer_service.dart';
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
  const PlusPerk(this.icon, this.title, this.sub, this.focus);

  final String icon;
  final String title;
  final String sub;

  /// "What to help with" answers this perk matches, for the FOR YOU tag.
  final Set<String> focus;
}

/// Paywall UI only. Purchases are not connected in this build. They will
/// go through RevenueCat later, with store prices instead of these labels.
class PlusController extends GetxController {
  static const List<PlusPlan> plans = [
    PlusPlan(
      'year',
      'Yearly',
      '7 days free · \$3.33 a month',
      '\$39.99',
      'a year',
      badge: 'SAVE 52%',
    ),
    PlusPlan(
      'month',
      'Monthly',
      'No trial · cancel anytime',
      '\$6.99',
      'a month',
    ),
  ];

  static const List<PlusPerk> perks = [
    // Only perks that work at launch (store rule). Backup is free with
    // sign-in; "Snap a meal" comes back here in v1.1.
    PlusPerk(
      Img3d.chartDown,
      'Full history and all charts',
      'Every weigh-in and dose since day one',
      {'progress', 'muscle'},
    ),
    PlusPerk(
      Img3d.nauseated,
      'Side-effect patterns',
      'See which day after your dose is usually hardest',
      {'nausea', 'noise'},
    ),
    PlusPerk(
      Img3d.clipboard,
      'Doctor report with charts',
      'Weight, doses and symptoms as a PDF',
      {'progress'},
    ),
    PlusPerk(
      Img3d.moneyBag,
      'Pen and cost tracker',
      'Doses left, refill nudge, monthly spend',
      {'cost', 'remember'},
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

  bool get isYearly => selected.value == 'year';

  String get cta =>
      isYearly ? 'Start my free week' : 'Subscribe for \$6.99 a month';

  String get fine => isYearly
      ? '7 days free, then \$39.99/year. Cancel anytime.'
      : 'Billed monthly. Cancel anytime.';

  void pick(String id) {
    if (selected.value == id) return;
    Haptics.instance.selectionClick();
    selected.value = id;
  }

  /// TODO(purchases): RevenueCat purchase, then schedule the day-5
  /// "trial ends soon" reminder promised on the trial timeline.
  void subscribe() {
    Haptics.instance.lightImpact();
    showToast(
      'Subscriptions are not connected yet. Everything free works fully.',
    );
  }

  void restore() {
    Haptics.instance.selectionClick();
    showToast('Nothing to restore yet.');
  }

  bool _closing = false;

  /// Close (X, back gesture). If the offer rules allow, the paywall is
  /// replaced by the one-time discount screen instead.
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    Haptics.instance.selectionClick();
    final showOffer = await Get.find<OfferService>().onPaywallClosed(fromOnboarding: fromOnboarding);
    if (showOffer) {
      Get.offNamed<void>(Routes.offer, arguments: OfferArgs(fromOnboarding: fromOnboarding));
    } else if (fromOnboarding) {
      Get.offAllNamed<void>(Routes.home);
    } else {
      popRoute();
    }
  }
}
