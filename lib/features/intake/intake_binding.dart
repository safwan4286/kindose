import 'package:get/get.dart';

import 'intake_controller.dart';

class IntakeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IntakeController>(() => IntakeController());
  }
}
