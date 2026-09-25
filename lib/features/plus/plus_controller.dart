import 'package:get/get.dart';

import '../../resources/routes.dart';
import '../../widgets/toast.dart';

class PlusPlan {
  const PlusPlan(this.id, this.name, this.sub, this.price, {this.best = false});

  final String id;
  final String name;
  final String sub;
  final String price;
  final bool best;
}

/// Paywall UI only. Purchases are not connected in this build. They will
/// go through RevenueCat later, with store prices instead of these labels.
class PlusController extends GetxController {
  static const List<PlusPlan> plans = [
    PlusPlan('year', 'Yearly', '7-day free trial · \$3.33 a month', '\$39.99', best: true),
    PlusPlan('month', 'Monthly', 'Cancel anytime', '\$6.99'),
  ];

  final RxString selected = 'year'.obs;

  /// True when opened at the end of onboarding: closing goes to Home.
  late final bool fromOnboarding = Get.arguments == true;

  bool get isYearly => selected.value == 'year';

  String get cta => isYearly ? 'Start 7-day free trial' : 'Subscribe for \$6.99 a month';

  String get fine => isYearly
      ? 'Free for 7 days, then \$39.99 a year. Cancel anytime in your store settings.'
      : 'Billed monthly. Cancel anytime in your store settings.';

  void subscribe() {
    showToast('Subscriptions are not connected yet. Everything free works fully.');
  }

  void restore() {
    showToast('Nothing to restore yet.');
  }

  void close() {
    if (fromOnboarding) {
      Get.offAllNamed<void>(Routes.home);
    } else {
      popRoute();
    }
  }
}
