import 'package:get/get.dart';

import 'plus_controller.dart';

class PlusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlusController>(() => PlusController());
  }
}
