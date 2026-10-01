import 'package:get/get.dart';

import '../../services/haptics/haptics.dart';
import '../../services/notifications/reminder_service.dart';
import '../../services/plus/access_service.dart';

import 'log_sheet.dart';

enum HomeTab { today, progress, report, me }

class HomeController extends GetxController {
  final Rx<HomeTab> tab = HomeTab.today.obs;

  /// True while the + Log sheet is showing (the + turns into an x).
  final RxBool logOpen = false.obs;

  @override
  void onReady() {
    super.onReady();
    // App opened by tapping a dose reminder: go straight to Log dose.
    if (Get.isRegistered<ReminderService>()) {
      Get.find<ReminderService>().openLaunchPayload();
    }
  }

  /// Switches tab without feedback (used by reminders and links).
  void select(HomeTab t) => tab.value = t;

  /// Tab bar tap: a tick of haptics only when the tab really changes.
  void tapTab(HomeTab t) {
    if (tab.value == t) return;
    Haptics.instance.selectionClick();
    tab.value = t;
  }

  Future<void> openLogSheet() async {
    if (logOpen.value) return;
    if (!AccessService.allow()) return;
    logOpen.value = true;
    try {
      await showLogSheet();
    } finally {
      logOpen.value = false;
    }
  }
}
