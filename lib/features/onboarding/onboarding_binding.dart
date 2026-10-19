import 'package:get/get.dart';

import 'onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}

/// Same screens, opened from Me to change answers. Pass the steps to show
/// as the route arguments (a List<OnboardingStep>); none = the plan steps.
class EditPlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(
        editMode: true,
        editSteps: Get.arguments is List<OnboardingStep>
            ? Get.arguments as List<OnboardingStep>
            : null,
      ),
    );
  }
}
