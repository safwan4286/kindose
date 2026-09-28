import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/date_utils.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../widgets/entrance.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_block.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_footer.dart';

/// Question 6 (already taking / restarting): roughly when treatment began,
/// so the app can say "Week 16". One tap on a month answers it.
class TreatmentStartPage extends GetView<OnboardingController> {
  const TreatmentStartPage({super.key});

  static const int _months = 12;

  List<DateTime> _recentMonths() {
    final now = DateTime.now();
    return [
      for (var i = 0; i < _months; i++) DateTime(now.year, now.month - i),
    ];
  }

  String _monthLabel(DateTime m) {
    final now = DateTime.now();
    final name = Dates.monthShort(m.month);
    return m.year == now.year
        ? name
        : "$name '${(m.year % 100).toString().padLeft(2, '0')}";
  }

  Future<void> _pickOlder(BuildContext context) async {
    final now = DateTime.now();
    final lastInGrid = DateTime(now.year, now.month - _months + 1);
    final latest = DateTime(
      lastInGrid.year,
      lastInGrid.month,
    ).subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate:
          controller.treatmentStartMode.value == 'older' &&
              controller.treatmentStart.value != null
          ? controller.treatmentStart.value!
          : latest,
      firstDate: DateTime(now.year - 10),
      lastDate: latest,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Month you started',
    );
    if (picked != null) controller.pickStartOlder(picked);
  }

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final months = _recentMonths();
    final restart = controller.stage.value == 'restart';

    return StepScaffold(
      title: restart
          ? 'When did you first start?'
          : 'When did you start treatment?',
      subtitle: "Roughly is fine. We'll count your weeks from it.",
      cta: const StepFooter(),
      children: [
        Obx(() {
          final mode = controller.treatmentStartMode.value;
          final picked = controller.treatmentStart.value;
          return ChoiceBlockGrid(
            height: 80,
            itemCount: months.length,
            itemBuilder: (context, i) {
              final m = months[i];
              final start = OnboardingController.approxStart(m);
              final week = OnboardingController.weekNumber(start);
              return ChoiceBlock(
                label: _monthLabel(m),
                sub: i == 0 ? 'Weeks 1–4' : '≈ Week $week',
                semanticLabel:
                    '${Dates.monthShort(m.month)} ${m.year}, about week $week',
                selected:
                    mode == 'month' &&
                    picked != null &&
                    picked.year == m.year &&
                    picked.month == m.month,
                onTap: () => controller.pickStartMonth(m),
              );
            },
          );
        }),
        SizedBox(height: 14.sp),
        Obx(() {
          final older = controller.treatmentStartMode.value == 'older';
          final picked = controller.treatmentStart.value;
          return ChoiceTile(
            title: 'More than a year ago',
            sub: older && picked != null
                ? '${Dates.monthShort(picked.month)} ${picked.year} · ≈ Week ${OnboardingController.weekNumber(picked)}'
                : 'Pick the month',
            selected: older,
            onTap: () => _pickOlder(context),
          );
        }).enter(motion, delay: 520),
        SizedBox(height: 8.sp),
        Obx(
          () => ChoiceTile(
            title: "I'd rather not say",
            sub: 'Week counts start from today',
            selected: controller.treatmentStartMode.value == 'skip',
            onTap: controller.skipStart,
          ),
        ).enter(motion, delay: 560),
      ],
    );
  }
}
