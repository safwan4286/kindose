import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  /// Length of the 4-week Progress range.
  static const int freeHistoryDays = 28;

  // ------------------------------------------------------------ debug

  static const String _debugKey = 'debugPlus';

  /// Debug builds only: act as a Plus subscriber (Me → "Debug: Plus").
  /// Always false in release builds.
  static final RxBool debugPlus = false.obs;

  /// What the store (RevenueCat) last said.
  static bool _fromStore = false;

  /// The only way to set [active] from purchases, so the debug switch
  /// isn't undone by the next customer-info update.
  static void setFromStore(bool entitled) {
    _fromStore = entitled;
    active.value = entitled || debugPlus.value;
  }

  /// Reads the saved debug switch. Call once the settings box is open.
  static void loadDebug() {
    if (!kDebugMode) return;
    debugPlus.value = Hive.box<dynamic>('settings').get(_debugKey) == true;
    active.value = _fromStore || debugPlus.value;
  }

  static Future<void> setDebugPlus(bool on) async {
    if (!kDebugMode) return;
    debugPlus.value = on;
    active.value = _fromStore || on;
    await Hive.box<dynamic>('settings').put(_debugKey, on);
  }
}
