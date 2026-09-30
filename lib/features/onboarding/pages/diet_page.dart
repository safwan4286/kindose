import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/colors.dart';
import '../../../resources/images.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../widgets/entrance.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_footer.dart';

/// Question 13: how you eat, so protein ideas fit.
class DietPage extends GetView<OnboardingController> {
  const DietPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final motion = !MediaQuery.disableAnimationsOf(context);
    Color tint(Color light, Color accent) =>
        dark ? accent.withValues(alpha: 0.16) : light;

    final options = [
      (
        'nonveg',
        'I eat everything',
        'Meat, fish, eggs and dairy',
        Img3d.chicken,
        tint(AppColors.tangerineSoft, AppColors.tangerine),
      ),
      (
        'pesc',
        'Pescatarian',
        'Fish and seafood, no meat',
        Img3d.fish,
        tint(AppColors.aquaSoft, AppColors.aqua),
      ),
      (
        'veg',
        'Vegetarian',
        'Eggs and dairy, no meat or fish',
        Img3d.egg,
        tint(const Color(0xFFFBEFD9), const Color(0xFFE0A23B)),
      ),
      (
        'vegan',
        'Vegan',
        'No animal foods at all',
        Img3d.seedling,
        tint(const Color(0xFFF1F7D6), AppColors.lime),
      ),
    ];

    return StepScaffold(
      title: 'How do you eat?',
      subtitle: "We'll suggest protein foods you actually eat.",
      cta: const StepFooter(),
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(height: 10.sp),
          Obx(() {
            final (id, title, sub, icon, color) = options[i];
            return ChoiceTile(
              title: title,
              sub: sub,
              leading: ChoiceIcon(icon, tint: color),
              selected: controller.diet.value == id,
              onTap: () => controller.pickDiet(id),
            );
          }).enter(motion, delay: 140 + i * 60),
        ],
      ],
    );
  }
}
