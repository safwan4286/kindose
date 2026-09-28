import 'package:get/get.dart';

import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

class PlusPlan {
  const PlusPlan(this.id, this.name, this.sub, this.price, this.per, {this.badge});

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
    PlusPlan('year', 'Yearly', '7 days free · \$3.33 a month', '\$39.99', 'a year', badge: 'SAVE 52%'),
    PlusPlan('month', 'Monthly', 'No trial · cancel anytime', '\$6.99', 'a month'),
  ];

  static const List<PlusPerk> perks = [
    // Only perks that work at launch (store rule). Backup is free with
    // sign-in; "Snap a meal" comes back here in v1.1.
    PlusPerk(Img3d.chartDown, 'Full history and all charts', 'Every weigh-in and dose since day one', {'progress', 'muscle'}),
    PlusPerk(Img3d.nauseated, 'Side-effect patterns', 'See how you feel by days since dose and food', {'nausea', 'noise'}),
    PlusPerk(Img3d.clipboard, 'Doctor report with charts', 'Weight, doses and symptoms as a PDF', {'progress'}),
    PlusPerk(Img3d.moneyBag, 'Pen and cost tracker', 'Doses left, refill nudge, monthly spend', {'cost', 'remember'}),
  ];

  final RxString selected = 'year'.obs;

  /// True when opened at the end of onboarding: closing goes to Home.
  late final bool fromOnboarding = Get.arguments == true;

  late final Set<String> _focus = {...?Get.find<TrackerService>().profile.value?.focus};

  bool isForYou(PlusPerk perk) => perk.focus.any(_focus.contains);

  bool get isYearly => selected.value == 'year';

  String get cta => isYearly ? 'Start my free week' : 'Subscribe for \$6.99 a month';

  String get fine => isYearly
      ? 'Free for 7 days, then \$39.99 a year. Cancel anytime in your store settings.'
      : 'Billed monthly. Cancel anytime in your store settings.';

  void pick(String id) {
    if (selected.value == id) return;
    Haptics.instance.selectionClick();
    selected.value = id;
  }

  /// TODO(purchases): RevenueCat purchase, then schedule the day-5
  /// "trial ends soon" reminder promised on the trial timeline.
  void subscribe() {
    Haptics.instance.lightImpact();
    showToast('Subscriptions are not connected yet. Everything free works fully.');
  }

  void restore() {
    Haptics.instance.selectionClick();
    showToast('Nothing to restore yet.');
  }

  void close() {
    Haptics.instance.selectionClick();
    if (fromOnboarding) {
      Get.offAllNamed<void>(Routes.home);
    } else {
      popRoute();
    }
  }
}
