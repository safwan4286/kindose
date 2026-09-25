import 'package:get/get.dart';

import 'onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}

/// Same screens, opened from Me to change medicine, dose or shot day.
class EditPlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController(editMode: true));
  }
}
