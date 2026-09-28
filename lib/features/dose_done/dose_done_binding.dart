import 'package:get/get.dart';

import 'dose_done_controller.dart';

class DoseDoneBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoseDoneController>(() => DoseDoneController());
  }
}
