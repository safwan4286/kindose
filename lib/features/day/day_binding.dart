import 'package:get/get.dart';

import 'day_controller.dart';

class DayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DayController>(() => DayController());
  }
}
