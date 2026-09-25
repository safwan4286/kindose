import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/mood_row.dart';
import 'check_in_controller.dart';
import '../../widgets/toast.dart';

class CheckInScreen extends GetView<CheckInController> {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final label = controller.dayLabel;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Row(
                children: [
                  BackCircle(onTap: () => popRoute()),
                  Expanded(
                    child: Center(
                      child: label.isEmpty
                          ? const SizedBox.shrink()
                          : Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(17)),
                              child: Text(label, style: AppText.small.copyWith(color: k.textSoft, fontWeight: FontWeight.w800)),
                            ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                children: [
                  Semantics(header: true, child: Text('How are you feeling?', style: AppText.h1)),
                  const SizedBox(height: 14),
                  Obx(() => MoodRow(
                        selected: controller.mood.value,
                        onPick: (m) => controller.mood.value = m,
                        height: 82,
                      )),
                  const SizedBox(height: 16),
                  Text('Anything bothering you?', style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Obx(() {
                    final on = controller.symptoms.toSet();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in Catalog.symptoms.entries)
                          KChip(label: e.value, selected: on.contains(e.key), onTap: () => controller.toggleSymptom(e.key)),
                      ],
                    );
                  }),
                  const SizedBox(height: 14),
                  Obx(() => KCard(
                        radius: 24,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          children: [
                            if (controller.symptoms.contains('nausea')) ...[
                              _Scale(
                                title: 'Nausea',
                                icon: Img3d.nauseated,
                                options: const ['Mild', 'Moderate', 'Severe'],
                                value: controller.nausea.value,
                                onPick: (v) => controller.setLevel(controller.nausea, v),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _Scale(
                              title: 'Food noise',
                              icon: Img3d.brain,
                              options: const ['Quiet', 'Some', 'Loud'],
                              value: controller.foodNoise.value,
                              onPick: (v) => controller.setLevel(controller.foodNoise, v),
                            ),
                            const SizedBox(height: 12),
                            _Scale(
                              title: 'Appetite',
                              icon: Img3d.curryRice,
                              options: const ['Low', 'Normal', 'High'],
                              value: controller.appetite.value,
                              onPick: (v) => controller.setLevel(controller.appetite, v),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.noteCtrl,
                    focusNode: controller.noteFocus,
                    maxLines: 3,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Add a note (optional)'),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const ThreeD(Img3d.thermometer, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            const TextSpan(
                              children: [
                                TextSpan(text: 'Get medical help now ', style: TextStyle(fontWeight: FontWeight.w800)),
                                TextSpan(
                                  text: 'for severe stomach pain, repeated vomiting, dehydration, vision changes or chest pain.',
                                ),
                              ],
                            ),
                            style: AppText.small.copyWith(color: AppColors.dangerText, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Obx(() => PillButton(
                    label: 'Save check-in',
                    icon: PhosphorIconsBold.check,
                    busy: controller.saving.value,
                    onPressed: controller.save,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scale extends StatelessWidget {
  const _Scale({
    required this.title,
    required this.icon,
    required this.options,
    required this.value,
    required this.onPick,
  });

  final String title;
  final String icon;
  final List<String> options;
  final int? value;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ThreeD(icon, size: 22),
            const SizedBox(width: 8),
            Text(title, style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        KSegmented<int>(
          options: List<int>.generate(options.length, (i) => i),
          selected: value,
          onChanged: onPick,
          labelOf: (i) => options[i],
        ),
      ],
    );
  }
}
