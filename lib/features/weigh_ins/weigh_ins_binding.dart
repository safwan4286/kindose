import 'package:get/get.dart';

import 'weigh_ins_controller.dart';

class WeighInsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeighInsController>(() => WeighInsController());
  }
}
