import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/bmi.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../widgets/ask_number.dart';
import '../../../widgets/big_value.dart';
import '../../../widgets/bmi_card.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_ruler.dart';
import '../../../widgets/k_widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Question 10: today's weight. kg or lb, big tappable number, ruler in
/// 0.1 steps and a live BMI card. Stored in kg.
class WeightPage extends GetView<OnboardingController> {
  const WeightPage({super.key});

  double _shown(double kg) => controller.useKg.value ? kg : kg * Imperial.lbPerKg;
  double _toKg(double shown) => controller.useKg.value ? shown : shown / Imperial.lbPerKg;
  String get _unit => controller.useKg.value ? 'kg' : 'lb';

  double get _min => _shown(OnboardingController.minWeightKg).ceilToDouble();
  double get _max => _shown(OnboardingController.maxWeightKg).floorToDouble();

  Future<void> _type(BuildContext context) async {
    // Unit at the moment the sheet opens; the answer is in that unit.
    final kg = controller.useKg.value;
    final v = await askNumber(
      context,
      title: 'Weight today',
      unit: _unit,
      initial: double.parse(_shown(controller.weightKg.value).toStringAsFixed(1)),
      min: _min,
      max: _max,
    );
    if (v != null && !v.isNaN) controller.setWeight(kg ? v : v / Imperial.lbPerKg);
  }

  void _step(int tenths) {
    Haptics.instance.selectionClick();
    final shown = double.parse(_shown(controller.weightKg.value).toStringAsFixed(1));
    controller.setWeight(_toKg((shown + tenths * 0.1).clamp(_min, _max)));
  }

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);

    return StepScaffold(
      title: "What's your current weight?",
      subtitle: 'Your starting point. Only you see it.',
      cta: PillButton(label: 'Continue', onPressed: controller.confirmWeight),
      children: [
        Center(
          child: SizedBox(
            width: 220.sp,
            child: Obx(
              () => KSegmented<bool>(
                options: const [true, false],
                selected: controller.useKg.value,
                onChanged: (v) => controller.useKg.value = v,
                labelOf: (v) => v ? 'kg' : 'lb',
              ),
            ),
          ),
        ).enter(motion, delay: 100, dy: 0.1),
        SizedBox(height: 30.sp),
        Obx(() {
          final shown = _shown(controller.weightKg.value).toStringAsFixed(1);
          return BigValue(
            value: shown,
            unit: _unit,
            semanticLabel: 'Weight $shown $_unit',
            onTap: () => _type(context),
          );
        }).enter(motion, delay: 160),
        SizedBox(height: 26.sp),
        Obx(() {
          // Capture the unit this ruler was built for. A fling that is still
          // running when the unit is switched must convert with the old unit,
          // and the key gives each unit its own ruler so the fling stops.
          final kg = controller.useKg.value;
          final shown = double.parse(_shown(controller.weightKg.value).toStringAsFixed(1));
          return KRuler(
            key: ValueKey(kg),
            semanticLabel: 'Weight in $_unit',
            value: shown,
            min: _min,
            max: _max,
            step: 0.1,
            majorEvery: 10,
            midEvery: 5,
            labelOf: (v) => v.round().toString(),
            semanticValueOf: (v) => '${v.toStringAsFixed(1)} $_unit',
            onChanged: (v) => controller.setWeight(kg ? v : v / Imperial.lbPerKg),
          );
        }).enter(motion, delay: 220),
        SizedBox(height: 8.sp),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleIconButton(icon: PhosphorIconsBold.minus, label: 'Less', size: 44.sp, onTap: () => _step(-1)),
            SizedBox(width: 12.sp),
            CircleIconButton(icon: PhosphorIconsBold.plus, label: 'More', size: 44.sp, onTap: () => _step(1)),
          ],
        ).enter(motion, delay: 260),
        SizedBox(height: 18.sp),
        Obx(() {
          final bmi = Bmi.of(controller.weightKg.value, controller.heightCm.value);
          if (bmi == null) return const SizedBox.shrink();
          return BmiCard(bmi: bmi);
        }).enter(motion, delay: 320),
      ],
    );
  }
}
