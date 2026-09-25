import 'package:get/get.dart';

import 'log_sheet.dart';

enum HomeTab { today, progress, report, me }

class HomeController extends GetxController {
  final Rx<HomeTab> tab = HomeTab.today.obs;

  void select(HomeTab t) => tab.value = t;

  Future<void> openLogSheet() => showLogSheet();
}
