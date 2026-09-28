import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/bmi.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../widgets/bmi_card.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/weight_input.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Question 10: today's weight with a live BMI card. Stored in kg.
class WeightPage extends GetView<OnboardingController> {
  const WeightPage({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return StepScaffold(
      title: "What's your current weight?",
      subtitle: 'Your starting point. Only you see it.',
      cta: PillButton(label: 'Continue', onPressed: controller.confirmWeight),
      children: [
        Obx(
          () => WeightInput(
            kg: controller.weightKg.value,
            useKg: controller.useKg.value,
            onKg: controller.setWeight,
            onUnit: (v) => controller.useKg.value = v,
            typeTitle: 'Weight today',
            minKg: OnboardingController.minWeightKg,
            maxKg: OnboardingController.maxWeightKg,
          ),
        ),
        SizedBox(height: 18.sp),
        Obx(() {
          final bmi = Bmi.of(
            controller.weightKg.value,
            controller.heightCm.value,
          );
          if (bmi == null) return const SizedBox.shrink();
          return BmiCard(bmi: bmi);
        }).enter(motion, delay: 320),
      ],
    );
  }
}
