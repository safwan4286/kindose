import 'package:get/get.dart';

import 'pens_controller.dart';

class PensBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PensController>(() => PensController());
  }
}
