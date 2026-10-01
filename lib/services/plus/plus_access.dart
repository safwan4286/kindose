import 'package:get/get.dart';

/// Who can use the app.
///
/// [active] = paid Plus (RevenueCat sets it after a purchase or restore;
/// false until purchases are connected). [freeWeek] = the free week is
/// still running (AccessService keeps it up to date). Screens check
/// [unlocked]; only the next dose, last spot, dose reminder, injection
/// guide, settings, export and delete stay open when it is false.
class PlusAccess {
  PlusAccess._();

  /// True while the user has an active Plus subscription.
  static final RxBool active = false.obs;

  /// True during the free week (and before it starts).
  static final RxBool freeWeek = true.obs;

  /// Plus or free week. Reading it inside an Obx watches both.
  static bool get unlocked => active.value || freeWeek.value;

  /// Charts and history free users can see.
  static const int freeHistoryDays = 28;
}
