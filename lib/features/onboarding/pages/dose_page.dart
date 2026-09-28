import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_text_field.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_block.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_footer.dart';

/// Question 3: the dose. The medicine's label strengths as big tiles
/// (tap = answer and move on), then "Custom dose" and "I don't know yet".
class DosePage extends GetView<OnboardingController> {
  const DosePage({super.key});

  String get _title => switch (controller.stage.value) {
    'starting' => 'What dose will you start with?',
    'restart' => 'What dose are you restarting on?',
    _ => "What's your current dose?",
  };

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);

    return StepScaffold(
      title: _title,
      subtitle: 'Use the dose on your prescription.',
      cta: Obx(
        () => StepFooter(
          expanded: controller.doseMode.value == 'custom',
          panel: const _CustomDosePanel(),
        ),
      ),
      children: [
        const _MedicineChip().enter(motion, delay: 80, dy: 0.1),
        Obx(() {
          final forms = Catalog.formsFor(controller.medicineId.value);
          if (forms.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(top: 16.sp),
            child: _FormSwitch(forms: forms),
          );
        }),
        SizedBox(height: 16.sp),
        Obx(() {
          final strengths = controller.medicine.strengths;
          if (strengths.isEmpty) return const SizedBox.shrink();
          final mode = controller.doseMode.value;
          final current = controller.strength.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 14.sp),
            child: ChoiceBlockGrid(
              height: 92,
              itemCount: strengths.length,
              itemBuilder: (context, i) => ChoiceBlock(
                label: Catalog.mg(strengths[i]),
                sub: 'mg',
                tag: i == 0 ? 'START' : null,
                semanticLabel:
                    '${Catalog.mg(strengths[i])} milligrams${i == 0 ? ', first dose on the label' : ''}',
                selected: mode == 'label' && current == strengths[i],
                onTap: () => controller.pickDose(strengths[i]),
              ),
            ),
          );
        }),
        Obx(
          () => ChoiceTile(
            title: 'Custom dose',
            sub: 'Type any amount in mg',
            selected: controller.doseMode.value == 'custom',
            onTap: controller.pickCustomDose,
          ),
        ).enter(motion, delay: 420),
        SizedBox(height: 8.sp),
        Obx(
          () => ChoiceTile(
            title: "I don't know yet",
            sub: 'Add it before your first dose',
            selected: controller.doseMode.value == 'unsure',
            onTap: controller.pickDoseUnsure,
          ),
        ).enter(motion, delay: 460),
        SizedBox(height: 16.sp),
        Obx(() {
          final vial = controller.form.value == 'vial';
          final hasStart = controller.medicine.strengths.isNotEmpty;
          return Text(
            [
              if (hasStart)
                "START marks the first dose on the medicine's label.",
              'Kindose records your dose; it never suggests one.',
              if (vial)
                'Using a vial? Enter mg from your prescription, not units.',
            ].join(' '),
            style: AppText.small.copyWith(
              fontSize: 12.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: k.faint,
            ),
          );
        }),
      ],
    );
  }
}

/// "Mounjaro® · weekly pen" reminder of the previous answer.
class _MedicineChip extends GetView<OnboardingController> {
  const _MedicineChip();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Align(
      alignment: Alignment.centerLeft,
      child: Obx(() {
        final m = controller.medicine;
        final name = Catalog.medicineName(
          m.id,
          controller.customMedicine.value,
        );
        final every = switch (controller.frequency.value) {
          'daily' => 'daily ',
          'weekly' => 'weekly ',
          '2w' => 'every 2 weeks · ',
          _ => '',
        };
        final form = Catalog.formLabel(controller.form.value).toLowerCase();
        final icon = controller.form.value == 'tablet'
            ? PhosphorIconsBold.pill
            : controller.form.value == 'vial'
            ? PhosphorIconsBold.testTube
            : PhosphorIconsBold.syringe;
        return Container(
          padding: EdgeInsets.fromLTRB(8.sp, 7.sp, 12.sp, 7.sp),
          decoration: BoxDecoration(
            color: k.cardAlt,
            borderRadius: BorderRadius.circular(14.sp),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22.sp,
                height: 22.sp,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(7.sp),
                ),
                alignment: Alignment.center,
                child: PhosphorIcon(icon, size: 12.sp, color: AppColors.lime),
              ),
              SizedBox(width: 8.sp),
              Flexible(
                child: Text(
                  '$name${m.mark ?? ''} · $every$form',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(
                    fontSize: 13.5.sp,
                    color: k.textSoft,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Pen / Vial / Tablet segmented switch, only for medicines that come in
/// more than one form.
class _FormSwitch extends GetView<OnboardingController> {
  const _FormSwitch({required this.forms});

  final List<String> forms;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.sp, bottom: 8.sp),
          child: Text(
            'How do you take it?',
            style: AppText.small.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: k.textSoft,
            ),
          ),
        ),
        Obx(
          () => KSegmented<String>(
            options: forms,
            selected: controller.form.value,
            onChanged: controller.pickForm,
            labelOf: Catalog.formLabel,
          ),
        ),
      ],
    );
  }
}

/// mg field for "Custom dose", pinned above the keyboard.
class _CustomDosePanel extends GetView<OnboardingController> {
  const _CustomDosePanel();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => StepInputPanel(
        label: 'Your dose',
        onContinue: controller.customDoseMg != null
            ? controller.confirmCustomDose
            : null,
        child: KTextField(
          controller: controller.customDoseField,
          autofocus: true,
          large: true,
          hint: 'e.g. 3.75',
          suffix: 'mg',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d{0,3}([.,]\d{0,3})?'),
            ),
          ],
          onChanged: controller.setCustomDose,
          onSubmitted: (_) => controller.confirmCustomDose(),
        ),
      ),
    );
  }
}
