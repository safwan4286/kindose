import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../widgets/entrance.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_footer.dart';

/// Question 12: usual activity, used to tune protein and water goals.
class ActivityPage extends GetView<OnboardingController> {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final motion = !MediaQuery.disableAnimationsOf(context);
    Color tint(Color light, Color accent) => dark ? accent.withValues(alpha: 0.16) : light;

    final options = [
      ('sed', 'Mostly sitting', 'Little or no exercise', PhosphorIconsBold.armchair, k.cardAlt),
      ('light', 'Lightly active', 'Walks or light exercise 1–3 days a week', PhosphorIconsBold.personSimpleWalk,
          tint(AppColors.aquaSoft, AppColors.aqua)),
      ('mod', 'Moderately active', 'Exercise 3–5 days a week', PhosphorIconsBold.personSimpleBike,
          tint(const Color(0xFFF1F7D6), AppColors.lime)),
      ('active', 'Very active', 'Hard exercise 6–7 days a week', PhosphorIconsBold.barbell,
          tint(AppColors.tangerineSoft, AppColors.tangerine)),
      ('athlete', 'Athlete level', 'Physical job or training twice a day', PhosphorIconsBold.lightning,
          tint(const Color(0xFFFBEFD9), const Color(0xFFE0A23B))),
    ];

    return StepScaffold(
      title: 'How active are you?',
      subtitle: 'Helps set your protein and water goals. Pick your usual week.',
      cta: const StepFooter(),
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(height: 10.sp),
          Obx(() {
            final (id, title, sub, icon, color) = options[i];
            return ChoiceTile(
              title: title,
              sub: sub,
              leading: ChoiceGlyph.icon(icon, tint: color),
              selected: controller.activity.value == id,
              onTap: () => controller.pickActivity(id),
            );
          }).enter(motion, delay: 140 + i * 60),
        ],
      ],
    );
  }
}
