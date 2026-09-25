import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../resources/images.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/painters.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Step 2: which medicine and in what form.
class MedicinePage extends GetView<OnboardingController> {
  const MedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Which medicine are you on?',
      subtitle: 'Pick the one on your prescription.',
      cta: PillButton(label: 'Continue', onPressed: controller.next),
      children: [
        Obx(() {
          final selected = controller.medicineId.value;
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              for (final m in Catalog.medicines)
                _MedicineTile(medicine: m, selected: m.id == selected, onTap: () => controller.pickMedicine(m.id)),
            ],
          );
        }),
        const SizedBox(height: 20),
        const SectionLabel('How do you take it?'),
        const SizedBox(height: 10),
        Obx(() {
          final form = controller.form.value;
          return Row(
            children: [
              for (final f in Catalog.forms) ...[
                if (f != Catalog.forms.first) const SizedBox(width: 8),
                Expanded(
                  child: _FormTile(
                    label: Catalog.formLabel(f),
                    icon: f == 'vial' ? Img3d.vial : f == 'tablet' ? Img3d.pill : Img3d.syringe,
                    selected: form == f,
                    onTap: () => controller.pickForm(f),
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({required this.medicine, required this.selected, required this.onTap});

  final Medicine medicine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: '${medicine.name}, ${medicine.sub}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? k.selectedBg : k.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? k.selectedBorder : k.card, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  medicine.isTablet
                      ? const ThreeD(Img3d.pill, size: 40)
                      : PenArt(body: medicine.color, cap: medicine.dark, height: 46),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: selected ? 1 : 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                      child: const Center(
                        child: PhosphorIcon(PhosphorIconsBold.check, size: 14, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(medicine.name, style: AppText.h3.copyWith(fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                medicine.sub,
                style: AppText.tiny.copyWith(fontSize: 12, color: k.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormTile extends StatelessWidget {
  const _FormTile({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 84,
          decoration: BoxDecoration(
            color: selected ? k.selectedBg : k.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? k.selectedBorder : k.card, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ThreeD(icon, size: 34),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppText.small.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? k.tintText : k.textSoft,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 3: strength, how often, which day and what time.
class DosePage extends GetView<OnboardingController> {
  const DosePage({super.key});

  Future<void> _pickTime(BuildContext context) async {
    final m = controller.shotMinutes.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      helpText: 'Dose time',
    );
    if (picked != null) controller.shotMinutes.value = picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return StepScaffold(
      title: 'Your dose & shot day',
      subtitle: 'Enter exactly what your doctor prescribed. You can change it any time.',
      cta: PillButton(
        label: controller.editMode ? 'Save changes' : 'Continue',
        onPressed: controller.next,
      ),
      children: [
        Obx(() {
          final med = controller.medicine;
          final dose = controller.strength.value;
          return KCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Current strength', style: AppText.title.copyWith(color: k.muted))),
                    Text('${Catalog.mg(dose)} mg', style: AppText.number(26)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final v in med.strengths)
                      _StrengthBubble(
                        label: Catalog.mg(v),
                        selected: v == dose,
                        onTap: () => controller.strength.value = v,
                      ),
                  ],
                ),
                if (controller.form.value == 'vial') ...[
                  const SizedBox(height: 12),
                  Text(
                    'Using a vial? Record the mg on your prescription. Kindose never converts doses into units.',
                    style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 18),
        const SectionLabel('How often'),
        const SizedBox(height: 10),
        Obx(() {
          final f = controller.frequency.value;
          const options = {'weekly': 'Weekly', '2w': '2 weeks', 'daily': 'Daily', 'custom': 'Custom'};
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in options.entries)
                KChip(label: e.value, selected: f == e.key, onTap: () => controller.frequency.value = e.key),
            ],
          );
        }),
        Obx(() {
          if (controller.frequency.value != 'custom') return const SizedBox.shrink();
          final d = controller.customDays.value;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: KCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Every $d days', style: AppText.title)),
                  CircleIconButton(
                    icon: PhosphorIconsBold.minus,
                    label: 'Fewer days',
                    size: 40,
                    background: k.cardAlt,
                    onTap: () => controller.customDays.value = (d - 1).clamp(2, 30),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: PhosphorIconsBold.plus,
                    label: 'More days',
                    size: 40,
                    background: k.cardAlt,
                    onTap: () => controller.customDays.value = (d + 1).clamp(2, 30),
                  ),
                ],
              ),
            ),
          );
        }),
        Obx(() {
          final f = controller.frequency.value;
          if (f != 'weekly' && f != '2w') return const SizedBox.shrink();
          final day = controller.shotWeekday.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const SectionLabel('Shot day'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var wd = 1; wd <= 7; wd++) ...[
                    if (wd > 1) const SizedBox(width: 6),
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: wd == day,
                        label: Dates.weekdayName(wd),
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => controller.shotWeekday.value = wd,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            height: 44,
                            decoration: BoxDecoration(
                              color: wd == day ? AppColors.lime : k.card,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Dates.weekdayName(wd).substring(0, 1),
                              style: AppText.title.copyWith(color: wd == day ? AppColors.ink : k.text),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        }),
        const SizedBox(height: 18),
        Obx(() => KCard(
              radius: 22,
              onTap: () => _pickTime(context),
              semanticLabel: 'Dose time, ${Dates.timeOfDay(controller.shotMinutes.value)}. Tap to change',
              child: Row(
                children: [
                  const ThreeD(Img3d.alarm, size: 36),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Usual dose time', style: AppText.title)),
                  Text(Dates.timeOfDay(controller.shotMinutes.value), style: AppText.h3.copyWith(color: AppColors.violet)),
                  const SizedBox(width: 6),
                  PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: k.faint),
                ],
              ),
            )),
      ],
    );
  }
}

class _StrengthBubble extends StatelessWidget {
  const _StrengthBubble({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final size = selected ? 62.0 : 48.0;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label milligrams',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? AppColors.violet : k.card,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? AppColors.violet : k.border, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.title.copyWith(
              fontSize: selected ? 17 : 14,
              color: selected ? AppColors.white : k.textSoft,
            ),
          ),
        ),
      ),
    );
  }
}
