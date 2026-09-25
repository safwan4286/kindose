import 'package:get/get.dart';

import '../me/me_controller.dart';
import '../progress/progress_controller.dart';
import '../report/report_controller.dart';
import '../today/today_controller.dart';
import 'home_controller.dart';

/// The four tabs live inside one route, so their controllers share the
/// Home route's lifetime and are removed when Home is removed.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<TodayController>(() => TodayController());
    Get.lazyPut<ProgressController>(() => ProgressController());
    Get.lazyPut<ReportController>(() => ReportController());
    Get.lazyPut<MeController>(() => MeController());
  }
}
