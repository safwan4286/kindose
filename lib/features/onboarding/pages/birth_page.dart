import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/wheel_picker.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Question 8: date of birth on three wheels, with a live age tag and the
/// 18+ check (Continue stays off for under-18s).
class BirthPage extends GetView<OnboardingController> {
  const BirthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final now = DateTime.now();
    final firstYear = now.year - OnboardingController.oldestYears;
    final yearCount = now.year - firstYear + 1;

    return StepScaffold(
      title: 'When were you born?',
      subtitle: 'Age helps set your goals. Kindose is for adults 18 and over.',
      cta: Obx(
        () => PillButton(
          label: 'Continue',
          onPressed: controller.isAdult ? controller.confirmBirth : null,
        ),
      ),
      children: [
        Obx(() {
          final y = controller.birthYear.value;
          final m = controller.birthMonth.value;
          final days = OnboardingController.daysInMonth(y, m);
          return WheelPickerCard(
            flex: const [8, 12, 10],
            columns: [
              WheelColumn(
                semanticLabel: 'Day',
                count: days,
                selected: controller.birthDay.value - 1,
                labelBuilder: (i) => (i + 1).toString().padLeft(2, '0'),
                onChanged: (i) => controller.setBirthDay(i + 1),
              ),
              WheelColumn(
                semanticLabel: 'Month',
                count: 12,
                selected: m - 1,
                labelBuilder: (i) => Dates.monthShort(i + 1),
                onChanged: (i) => controller.setBirthMonth(i + 1),
              ),
              WheelColumn(
                semanticLabel: 'Year',
                count: yearCount,
                selected: (y - firstYear).clamp(0, yearCount - 1),
                labelBuilder: (i) => '${firstYear + i}',
                onChanged: (i) => controller.setBirthYear(firstYear + i),
              ),
            ],
          );
        }).enter(motion, delay: 120),
        SizedBox(height: 16.sp),
        Center(child: const _AgeTag().enter(motion, delay: 220, dy: 0.1)),
      ],
    );
  }
}

/// "You're 31", or a gentle red notice for under-18s.
class _AgeTag extends GetView<OnboardingController> {
  const _AgeTag();

  @override
  Widget build(BuildContext context) {
    final dark = context.k.selectedBorder == AppColors.lime;
    return Obx(() {
      final adult = controller.isAdult;
      final age = controller.age;
      final bg = adult
          ? (dark ? AppColors.lime.withValues(alpha: 0.16) : const Color(0xFFF1F7D6))
          : (dark ? AppColors.danger.withValues(alpha: 0.25) : AppColors.dangerSoft);
      final fg = adult ? (dark ? AppColors.lime : AppColors.limeText) : (dark ? AppColors.dangerSoft : AppColors.dangerText);
      final text = adult ? "You're $age" : 'Kindose is for adults 18 and over';
      return Semantics(
        liveRegion: true,
        label: text,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 8.sp),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14.sp)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!adult) ...[
                PhosphorIcon(PhosphorIconsBold.info, size: 16.sp, color: fg),
                SizedBox(width: 6.sp),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(text, key: ValueKey(text), style: AppText.title.copyWith(fontSize: 15.sp, color: fg)),
              ),
            ],
          ),
        ),
      );
    });
  }
}
