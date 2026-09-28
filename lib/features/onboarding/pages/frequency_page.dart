import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_footer.dart';

/// Question 4: how often. The medicine's usual schedule is tagged but not
/// pre-selected. "Another schedule" opens an every-N-days stepper.
class FrequencyPage extends GetView<OnboardingController> {
  const FrequencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final motion = !MediaQuery.disableAnimationsOf(context);
    Color tint(Color light, Color accent) =>
        dark ? accent.withValues(alpha: 0.16) : light;

    final options = [
      _Option(
        'daily',
        'Daily',
        'Same time every day',
        '1',
        tint(AppColors.aquaSoft, AppColors.aqua),
      ),
      _Option(
        'weekly',
        'Weekly',
        'Same day each week',
        '7',
        tint(const Color(0xFFF1F7D6), AppColors.lime),
      ),
      _Option(
        '2w',
        'Every 2 weeks',
        'Every other week, same day',
        '14',
        k.cardAlt,
      ),
      _Option(
        'custom',
        'Another schedule',
        'Every few days, you choose',
        'N',
        tint(AppColors.tangerineSoft, AppColors.tangerine),
      ),
      _Option(
        'unsure',
        "I don't know yet",
        "We'll ask again before reminders",
        '?',
        k.cardAlt,
      ),
    ];

    return StepScaffold(
      title: controller.stage.value == 'starting'
          ? 'How often will you take it?'
          : 'How often do you take it?',
      subtitle: 'So reminders land on the right day.',
      cta: Obx(
        () => StepFooter(
          expanded:
              controller.frequencyAnswered.value &&
              controller.frequency.value == 'custom',
          panel: const _CustomDaysPanel(),
        ),
      ),
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(height: 10.sp),
          Obx(() {
            final o = options[i];
            final m = controller.medicine;
            final usual =
                (o.id == 'daily' && m.everyDays == 1) ||
                (o.id == 'weekly' && m.everyDays == 7);
            final showTag = usual && m.strengths.isNotEmpty;
            return ChoiceTile(
              title: o.title,
              sub: o.sub,
              tag: showTag
                  ? 'USUAL FOR ${m.name.toUpperCase()}${m.mark ?? ''}'
                  : null,
              leading: ChoiceGlyph(o.glyph, tint: o.tint),
              selected:
                  controller.frequencyAnswered.value &&
                  controller.frequency.value == o.id,
              onTap: () => controller.pickFrequency(o.id),
            );
          }).enter(motion, delay: 140 + i * 60),
        ],
      ],
    );
  }
}

class _Option {
  const _Option(this.id, this.title, this.sub, this.glyph, this.tint);

  final String id;
  final String title;
  final String sub;
  final String glyph;
  final Color tint;
}

/// "Every [− 3 +] days" stepper and Continue, pinned above the bottom edge.
class _CustomDaysPanel extends GetView<OnboardingController> {
  const _CustomDaysPanel();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return StepInputPanel(
      onContinue: controller.confirmCustomFrequency,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.sp, 8.sp, 8.sp, 8.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(20.sp),
        ),
        child: Obx(() {
          final d = controller.customDays.value;
          return Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: 'Every $d days',
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      text: 'Every ',
                      children: [
                        TextSpan(
                          text: '$d',
                          style: AppText.h1.copyWith(
                            fontSize: 24.sp,
                            color: k.text,
                          ),
                        ),
                        const TextSpan(text: ' days'),
                      ],
                    ),
                    style: AppText.title.copyWith(
                      fontSize: 17.sp,
                      color: k.text,
                    ),
                  ),
                ),
              ),
              CircleIconButton(
                icon: PhosphorIconsBold.minus,
                label: 'Fewer days',
                size: 44.sp,
                background: k.cardAlt,
                onTap: d > OnboardingController.minCustomDays
                    ? () => controller.stepCustomDays(-1)
                    : null,
              ),
              SizedBox(width: 8.sp),
              CircleIconButton(
                icon: PhosphorIconsBold.plus,
                label: 'More days',
                size: 44.sp,
                background: k.cardAlt,
                onTap: d < OnboardingController.maxCustomDays
                    ? () => controller.stepCustomDays(1)
                    : null,
              ),
            ],
          );
        }),
      ),
    );
  }
}
