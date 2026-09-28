import 'package:get/get.dart';

import '../../services/notifications/reminder_service.dart';

import 'log_sheet.dart';

enum HomeTab { today, progress, report, me }

class HomeController extends GetxController {
  final Rx<HomeTab> tab = HomeTab.today.obs;

  @override
  void onReady() {
    super.onReady();
    // App opened by tapping a dose reminder: go straight to Log dose.
    if (Get.isRegistered<ReminderService>()) Get.find<ReminderService>().openLaunchPayload();
  }

  void select(HomeTab t) => tab.value = t;

  Future<void> openLogSheet() => showLogSheet();
}
