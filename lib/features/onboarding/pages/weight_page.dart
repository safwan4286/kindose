import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kindose/widgets/safe_bottom.dart';

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
    // Short phones (SE, mini; 812 pt and under): drop the BMI footnote and
    // tighten the gaps so the whole card sits above Continue.
    final short = MediaQuery.sizeOf(context).height < 830;
    return StepScaffold(
      title: "What's your current weight?",
      subtitle: 'Your starting point. Only you see it.',
      cta: KBottomPadding(
        child: PillButton(
          label: 'Continue',
          onPressed: controller.confirmWeight,
        ),
      ),
      children: [
        Obx(
          () => WeightInput(
            kg: controller.weightKg.value,
            useKg: controller.useKg.value,
            onKg: controller.setWeight,
            onUnit: controller.setUseKg,
            typeTitle: 'Weight today',
            minKg: OnboardingController.minWeightKg,
            maxKg: OnboardingController.maxWeightKg,
            compact: short,
          ),
        ),
        SizedBox(height: short ? 10.sp : 18.sp),
        Obx(() {
          final bmi = Bmi.of(
            controller.weightKg.value,
            controller.heightCm.value,
          );
          if (bmi == null) return const SizedBox.shrink();
          return BmiCard(bmi: bmi, showNote: !short);
        }).enter(motion, delay: 320),
      ],
    );
  }
}
