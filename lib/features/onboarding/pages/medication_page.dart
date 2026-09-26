import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_text_field.dart';
import '../../../widgets/k_widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_footer.dart';

/// Question 2: which medication. Grouped by active ingredient, brand names
/// carry a ®. Tapping a row moves on; "Something else" asks for a name.
class MedicationPage extends GetView<OnboardingController> {
  const MedicationPage({super.key});

  static const Map<MedGroup, String> _groupLabels = {
    MedGroup.tirzepatide: 'TIRZEPATIDE',
    MedGroup.semaglutide: 'SEMAGLUTIDE',
    MedGroup.other: 'OTHER GLP-1',
    MedGroup.notListed: 'NOT ON THE LIST',
  };

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final starting = controller.stage.value == 'starting';

    final rows = <Widget>[];
    var index = 0;
    for (final group in MedGroup.values) {
      final meds = Catalog.medicines.where((m) => m.group == group).toList();
      if (meds.isEmpty) continue;
      rows.add(
        _GroupLabel(
          _groupLabels[group]!,
          padding: _groupLabels[group] == "TIRZEPATIDE"
              ? EdgeInsets.fromLTRB(4.sp, 0, 4.sp, 0)
              : null,
        ).enter(motion, delay: 100 + index.clamp(0, 8) * 40, dy: 0.1),
      );
      for (final m in meds) {
        final i = index++;
        rows
          ..add(SizedBox(height: 8.sp))
          ..add(
            Obx(
              () => ChoiceTile(
                title: m.title,
                superscript: m.mark,
                sub: m.sub,
                selected: controller.medicineId.value == m.id,
                onTap: () => controller.pickMedicine(m.id),
              ),
            ).enter(motion, delay: 120 + i.clamp(0, 8) * 40),
          );
      }
    }

    return StepScaffold(
      title: starting
          ? 'Which medication will you use?'
          : 'Which medication are you on?',
      subtitle: starting
          ? 'Pick the one your doctor prescribed.'
          : 'Pick the one on your prescription.',
      cta: Obx(
        () => StepFooter(
          expanded: controller.medicineId.value == Catalog.other,
          panel: const _CustomNamePanel(),
        ),
      ),
      children: [
        ...rows,
        SizedBox(height: 18.sp),
        Text(
          "Brand names are trademarks of their owners. Kindose isn't affiliated with them and doesn't recommend any medicine.",
          style: AppText.small.copyWith(
            fontSize: 11.5.sp,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: k.faint,
          ),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(4.sp, 15.sp, 4.sp, 0),
      child: SectionLabel(text, color: context.k.faint),
    );
  }
}

/// Name field for "Something else", pinned above the keyboard.
class _CustomNamePanel extends GetView<OnboardingController> {
  const _CustomNamePanel();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => StepInputPanel(
        label: "What's it called?",
        onContinue: controller.customMedicineValid
            ? controller.confirmCustomMedicine
            : null,
        child: KTextField(
          controller: controller.customMedicineField,
          autofocus: true,
          hint: 'e.g. Victoza, Tirzec, Ozivy',
          textCapitalization: TextCapitalization.words,
          maxLength: OnboardingController.customMedicineMaxLength,
          onChanged: controller.setCustomMedicine,
          onSubmitted: (_) => controller.confirmCustomMedicine(),
        ),
      ),
    );
  }
}
