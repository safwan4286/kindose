import 'package:get/get.dart';

import 'log_dose_controller.dart';

class LogDoseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LogDoseController>(() => LogDoseController());
  }
}
