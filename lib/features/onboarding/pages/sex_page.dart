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

/// Question 7: sex, only for estimating protein and water goals.
class SexPage extends GetView<OnboardingController> {
  const SexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final motion = !MediaQuery.disableAnimationsOf(context);
    Color tint(Color light, Color accent) => dark ? accent.withValues(alpha: 0.16) : light;

    final options = [
      ('female', 'Female', null, PhosphorIconsBold.genderFemale, tint(AppColors.tangerineSoft, AppColors.tangerine)),
      ('male', 'Male', null, PhosphorIconsBold.genderMale, tint(AppColors.aquaSoft, AppColors.aqua)),
      ('other', 'Other', null, PhosphorIconsBold.genderIntersex, tint(const Color(0xFFF1F7D6), AppColors.lime)),
      ('none', 'Prefer not to say', "We'll use a middle estimate", PhosphorIconsBold.eyeSlash, k.cardAlt),
    ];

    return StepScaffold(
      title: "What's your sex?",
      subtitle: 'Only used to estimate your protein and water goals.',
      cta: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PrivacyNote('Stays on this phone. You can change or remove it in Me.').enter(motion, delay: 420, dy: 0.1),
          SizedBox(height: 10.sp),
          const TapHint('Tap one to continue').enter(motion, delay: 480, dy: 0),
        ],
      ),
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(height: 10.sp),
          Obx(() {
            final (id, title, sub, icon, color) = options[i];
            return ChoiceTile(
              title: title,
              sub: sub,
              leading: ChoiceGlyph.icon(icon, tint: color),
              selected: controller.sex.value == id,
              onTap: () => controller.pickSex(id),
            );
          }).enter(motion, delay: 140 + i * 60),
        ],
      ],
    );
  }
}
