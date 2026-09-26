import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/bmi.dart';
import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_ruler.dart';
import '../../../widgets/weight_input.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Question 11: optional goal weight. Shows how much is left to lose (or
/// gain) and the goal BMI. A goal below the healthy BMI range gets a
/// gentle "agree it with your doctor" note, never a block.
class GoalPage extends GetView<OnboardingController> {
  const GoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return StepScaffold(
      title: "What's your goal weight?",
      subtitle: 'Optional. You can change it anytime.',
      cta: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(label: 'Continue', onPressed: controller.confirmGoal),
          SizedBox(height: 4.sp),
          LinkButton(label: 'Skip for now', onTap: controller.skipGoal),
        ],
      ),
      children: [
        Obx(
          () => WeightInput(
            kg: controller.goalDraftKg.value,
            useKg: controller.useKg.value,
            onKg: controller.setGoalDraft,
            onUnit: (v) => controller.useKg.value = v,
            typeTitle: 'Goal weight',
            minKg: OnboardingController.minWeightKg,
            maxKg: OnboardingController.maxWeightKg,
          ),
        ),
        SizedBox(height: 20.sp),
        const _GoalSummary().enter(motion, delay: 320),
      ],
    );
  }
}

/// "7.5 kg to lose" pill, goal BMI line and the low-BMI note.
class _GoalSummary extends GetView<OnboardingController> {
  const _GoalSummary();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Obx(() {
      final useKg = controller.useKg.value;
      final unit = useKg ? 'kg' : 'lb';
      final diffKg = controller.goalDiffKg;
      final diff = (useKg ? diffKg : diffKg * Imperial.lbPerKg).abs();
      final steady = diff < 0.05;
      final label = steady ? 'keep it steady' : diffKg > 0 ? 'to lose' : 'to gain';
      final bmi = controller.goalBmi;
      final low = bmi != null && Bmi.range(bmi) == BmiRange.below;

      return Column(
        children: [
          Semantics(
            liveRegion: true,
            label: steady ? 'Keep your weight steady' : '${diff.toStringAsFixed(1)} $unit $label',
            excludeSemantics: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 10.sp),
              decoration: BoxDecoration(
                color: dark ? k.cardAlt : AppColors.ink,
                borderRadius: BorderRadius.circular(18.sp),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (!steady) ...[
                    Text(
                      '${diff.toStringAsFixed(1)} $unit',
                      style: AppText.h1.copyWith(fontSize: 30.sp, height: 1, color: AppColors.lime),
                    ),
                    SizedBox(width: 6.sp),
                  ],
                  Text(label, style: AppText.title.copyWith(fontSize: 15.sp, color: AppColors.white)),
                ],
              ),
            ),
          ),
          if (bmi != null) ...[
            SizedBox(height: 10.sp),
            Text(
              'Goal BMI ${bmi.toStringAsFixed(1)} · ${Bmi.label(Bmi.range(bmi))}',
              style: AppText.small.copyWith(fontSize: 13.5.sp, color: k.muted),
            ),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: low
                ? Padding(
                    padding: EdgeInsets.only(top: 12.sp),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF7A4E0B).withValues(alpha: 0.3) : const Color(0xFFFBEFD9),
                        borderRadius: BorderRadius.circular(16.sp),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PhosphorIcon(PhosphorIconsBold.info, size: 16.sp, color: dark ? const Color(0xFFFBEFD9) : const Color(0xFF7A4E0B)),
                          SizedBox(width: 8.sp),
                          Expanded(
                            child: Text(
                              "That's below the healthy range. Please agree this goal with your doctor.",
                              style: AppText.small.copyWith(
                                fontSize: 13.sp,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: dark ? const Color(0xFFFBEFD9) : const Color(0xFF7A4E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      );
    });
  }
}
