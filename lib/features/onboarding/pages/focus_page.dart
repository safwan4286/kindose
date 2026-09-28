import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_tile.dart';

/// Question 14 (last): what Kindose should help with. Multi-select with
/// checkboxes; Continue needs at least one.
class FocusPage extends GetView<OnboardingController> {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final motion = !MediaQuery.disableAnimationsOf(context);
    Color tint(Color light, Color accent) =>
        dark ? accent.withValues(alpha: 0.16) : light;

    final tints = <String, Color>{
      'muscle': tint(AppColors.tangerineSoft, AppColors.tangerine),
      'nausea': tint(const Color(0xFFF1F7D6), AppColors.lime),
      'noise': k.cardAlt,
      'remember': tint(AppColors.aquaSoft, AppColors.aqua),
      'nerves': tint(const Color(0xFFFBEFD9), const Color(0xFFE0A23B)),
      'progress': tint(const Color(0xFFF1F7D6), AppColors.lime),
      'cost': k.cardAlt,
    };
    final items = Catalog.focusItems;

    return StepScaffold(
      title: 'What should Kindose help with?',
      subtitle: "Pick all that apply. We'll put these first.",
      cta: Obx(() {
        final n = controller.focus.length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                n == 0 ? 'Pick at least one' : '$n selected',
                style: AppText.small.copyWith(
                  fontSize: 12.5.sp,
                  color: k.faint,
                ),
              ),
            ),
            SizedBox(height: 8.sp),
            PillButton(
              label: 'Continue',
              onPressed: n == 0 ? null : controller.confirmFocus,
            ),
          ],
        );
      }),
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: 10.sp),
          Obx(() {
            final f = items[i];
            return ChoiceTile(
              title: f.title,
              sub: f.sub,
              multi: true,
              leading: ChoiceIcon(f.icon, tint: tints[f.id] ?? k.cardAlt),
              selected: controller.focus.contains(f.id),
              onTap: () => controller.toggleFocus(f.id),
            );
          }).enter(motion, delay: 140 + i.clamp(0, 6) * 50),
        ],
      ],
    );
  }
}
