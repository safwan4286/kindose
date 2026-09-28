import 'package:get/get.dart';

/// Who has Kindose Plus, and the free limits.
///
/// For now [active] is always false: RevenueCat will set it after a
/// purchase or restore (week 4). The limits move to Firebase Remote Config
/// then, so they can change without an app update.
class PlusAccess {
  PlusAccess._();

  /// True while the user has an active Plus subscription or trial.
  static final RxBool active = false.obs;

  /// Charts and history free users can see.
  static const int freeHistoryDays = 28;
}
