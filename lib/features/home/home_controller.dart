import 'package:get/get.dart';

import '../../services/haptics/haptics.dart';
import '../../services/notifications/reminder_service.dart';
import '../../services/tracker_service.dart';

import 'log_sheet.dart';

/// Order = tab bar order = IndexedStack order in HomeScreen.
enum HomeTab { today, doses, progress, report, me }

class HomeController extends GetxController {
  final Rx<HomeTab> tab = HomeTab.today.obs;

  /// True while the + Log sheet is showing (the + turns into an x).
  final RxBool logOpen = false.obs;

  /// The round + shows on the tabs where logging fits; on Report and Me it
  /// would only cover their buttons.
  bool get showLogButton =>
      tab.value == HomeTab.today ||
      tab.value == HomeTab.progress ||
      tab.value == HomeTab.doses;

  @override
  void onReady() {
    super.onReady();
    // App opened by tapping a dose reminder: go straight to Log dose.
    if (Get.isRegistered<ReminderService>()) {
      Get.find<ReminderService>().openLaunchPayload();
    }
  }

  /// Daily-tablet plans call the tab "Tablets" with a pill icon.
  bool get isTablet =>
      Get.find<TrackerService>().profile.value?.form == 'tablet';

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
    logOpen.value = true;
    try {
      await showLogSheet();
    } finally {
      logOpen.value = false;
    }
  }
}
