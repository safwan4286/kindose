import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../widgets/ask_number.dart';
import '../../../widgets/big_value.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_ruler.dart';
import '../../../widgets/k_widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Question 9: height. cm or ft · in, a big number you can tap to type,
/// and a ruler to drag. Stored in cm either way.
class HeightPage extends GetView<OnboardingController> {
  const HeightPage({super.key});

  static const double _minIn =
      OnboardingController.minHeightCm / Imperial.cmPerInch;
  static const double _maxIn =
      OnboardingController.maxHeightCm / Imperial.cmPerInch;

  Future<void> _type(BuildContext context) async {
    final cm = controller.heightShownCm;
    if (controller.heightInCm.value) {
      final v = await askNumber(
        context,
        title: 'Your height',
        unit: 'cm',
        initial: cm.roundToDouble(),
        min: OnboardingController.minHeightCm,
        max: OnboardingController.maxHeightCm,
        decimals: 0,
      );
      if (v != null && !v.isNaN) controller.setHeightCm(v.roundToDouble());
    } else {
      final inches = await askFeetInches(
        context,
        title: 'Your height',
        initialInches: cm / Imperial.cmPerInch,
        minInches: _minIn.ceilToDouble(),
        maxInches: _maxIn.floorToDouble(),
      );
      if (inches != null) controller.setHeightCm(inches * Imperial.cmPerInch);
    }
  }

  void _step(int delta) {
    Haptics.instance.selectionClick();
    final cm = controller.heightShownCm;
    if (controller.heightInCm.value) {
      controller.setHeightCm(cm.roundToDouble() + delta);
    } else {
      final inches = (cm / Imperial.cmPerInch).roundToDouble() + delta;
      controller.setHeightCm(inches * Imperial.cmPerInch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);

    return StepScaffold(
      title: 'How tall are you?',
      subtitle: 'Used for your BMI and goals.',
      cta: PillButton(label: 'Continue', onPressed: controller.confirmHeight),
      children: [
        Center(
          child: SizedBox(
            width: 220.sp,
            child: Obx(
              () => KSegmented<bool>(
                options: const [true, false],
                selected: controller.heightInCm.value,
                onChanged: (v) => controller.heightInCm.value = v,
                labelOf: (v) => v ? 'cm' : 'ft · in',
              ),
            ),
          ),
        ).enter(motion, delay: 100, dy: 0.1),
        SizedBox(height: 30.sp),
        Obx(() {
          final cm = controller.heightShownCm;
          final metric = controller.heightInCm.value;
          final big = metric
              ? '${cm.round()}'
              : Imperial.feetInches(cm / Imperial.cmPerInch);
          return BigValue(
            value: big,
            unit: metric ? 'cm' : null,
            semanticLabel:
                'Height ${metric ? '${cm.round()} centimetres' : big}',
            onTap: () => _type(context),
          );
        }).enter(motion, delay: 160),
        SizedBox(height: 26.sp),
        Obx(() {
          final cm = controller.heightShownCm;
          if (controller.heightInCm.value) {
            return KRuler(
              key: const ValueKey('cm'),
              semanticLabel: 'Height in centimetres',
              value: cm.roundToDouble(),
              min: OnboardingController.minHeightCm,
              max: OnboardingController.maxHeightCm,
              majorEvery: 5,
              labelOf: (v) => v.round().toString(),
              semanticValueOf: (v) => '${v.round()} cm',
              onChanged: controller.setHeightCm,
            );
          }
          return KRuler(
            key: const ValueKey('in'),
            semanticLabel: 'Height in feet and inches',
            value: (cm / Imperial.cmPerInch).roundToDouble(),
            min: _minIn.ceilToDouble(),
            max: _maxIn.floorToDouble(),
            majorEvery: 12,
            midEvery: 6,
            labelOf: (v) => "${v.round() ~/ 12}′",
            semanticValueOf: Imperial.feetInches,
            onChanged: (inches) =>
                controller.setHeightCm(inches * Imperial.cmPerInch),
          );
        }).enter(motion, delay: 220),
        SizedBox(height: 8.sp),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleIconButton(
              icon: PhosphorIconsBold.minus,
              label: 'Shorter',
              size: 44.sp,
              onTap: () => _step(-1),
            ),
            SizedBox(width: 12.sp),
            CircleIconButton(
              icon: PhosphorIconsBold.plus,
              label: 'Taller',
              size: 44.sp,
              onTap: () => _step(1),
            ),
          ],
        ).enter(motion, delay: 260),
      ],
    );
  }
}
