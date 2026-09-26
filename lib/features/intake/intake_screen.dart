import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import 'intake_controller.dart';
import '../../widgets/toast.dart';
import '../../widgets/safe_bottom.dart';

class IntakeScreen extends GetView<IntakeController> {
  const IntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Scaffold(
      body: KSafeArea(
        child: Obx(() {
          final isP = controller.isProtein;
          final strong = isP ? AppColors.tangerine : AppColors.aqua;
          final soft = isP ? k.proteinTrack : (k.bg == KColors.dark.bg ? const Color(0xFF12394A) : AppColors.aquaSoft);
          final base = controller.todayBase;
          final add = controller.amount;
          final goal = controller.goal;
          double pct(int v) => goal == 0 ? 0 : (v / goal).clamp(0.0, 1.0);
          final fromTo = isP
              ? '$base g → ${base + add} g today'
              : '${controller.formatWater(base)} → ${controller.formatWater(base + add)} today';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: Row(
                  children: [
                    BackCircle(onTap: () => popRoute()),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(22)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Tab(
                                label: 'Protein',
                                icon: Img3d.egg,
                                selected: isP,
                                bg: k.proteinTrack,
                                fg: isP && k.bg != KColors.dark.bg ? AppColors.tangerineText : AppColors.tangerine,
                                onTap: () => controller.tab.value = 'protein',
                              ),
                              _Tab(
                                label: 'Water',
                                icon: Img3d.droplet,
                                selected: !isP,
                                bg: soft,
                                fg: k.bg == KColors.dark.bg ? AppColors.aqua : AppColors.aquaText,
                                onTap: () => controller.tab.value = 'water',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  children: [
                    KCard(
                      radius: 28,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleIconButton(
                                icon: PhosphorIconsBold.minus,
                                label: 'Less',
                                size: 54,
                                background: k.cardAlt,
                                onTap: controller.decrease,
                              ),
                              Expanded(
                                child: Semantics(
                                  liveRegion: true,
                                  label: '$add ${isP ? 'grams' : 'millilitres'}',
                                  excludeSemantics: true,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('$add', style: AppText.number(64)),
                                        const SizedBox(width: 4),
                                        Text(isP ? 'g' : 'ml', style: AppText.title.copyWith(fontSize: 20, color: k.muted)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              CircleIconButton(
                                icon: PhosphorIconsBold.plus,
                                label: 'More',
                                size: 54,
                                background: k.cardAlt,
                                onTap: controller.increase,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 12,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: ColoredBox(color: soft)),
                                  FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    heightFactor: 1,
                                    widthFactor: pct(base + add),
                                    child: ColoredBox(color: strong.withValues(alpha: 0.45)),
                                  ),
                                  FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    heightFactor: 1,
                                    widthFactor: pct(base),
                                    child: ColoredBox(color: strong),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: Text(fromTo, style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w800))),
                              Text(
                                'Goal ${isP ? '$goal g' : controller.formatWater(goal)}',
                                style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isP) ...[
                      const SizedBox(height: 14),
                      KCard(
                        color: AppColors.hero,
                        radius: 24,
                        padding: const EdgeInsets.all(16),
                        onTap: () => Get.toNamed<void>(Routes.plus),
                        semanticLabel: 'Snap your meal, a Plus feature',
                        child: Row(
                          children: [
                            const ThreeD(Img3d.curryRice, size: 52),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Snap your meal', style: AppText.title.copyWith(fontSize: 16, color: AppColors.white)),
                                  Text(
                                    'We estimate the protein. You confirm.',
                                    style: AppText.small.copyWith(color: AppColors.heroMuted, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const PlusTag(onDark: true),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SectionLabel(isP ? 'Your usuals' : 'Quick sizes'),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.7,
                      children: isP
                          ? [
                              for (final f in controller.usualFoods)
                                _Usual(
                                  icon: f.icon,
                                  name: f.name,
                                  qty: '~${f.grams} g protein',
                                  selected: controller.proteinPick.value == f.id,
                                  accent: AppColors.tangerine,
                                  onTap: () => controller.pickFood(f),
                                ),
                            ]
                          : [
                              for (final w in IntakeController.waterSizes)
                                _Usual(
                                  icon: w.icon,
                                  name: w.name,
                                  qty: '${w.ml} ml',
                                  selected: controller.waterPick.value == w.id,
                                  accent: AppColors.aqua,
                                  onTap: () => controller.pickWater(w),
                                ),
                            ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: PillButton(
                  label: isP ? 'Add $add g protein' : 'Add $add ml water',
                  icon: PhosphorIconsBold.check,
                  busy: controller.saving.value,
                  onPressed: controller.save,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 36,
          padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
          decoration: BoxDecoration(
            color: selected ? bg : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThreeD(icon, size: 22),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.small.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? fg : context.k.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Usual extends StatelessWidget {
  const _Usual({
    required this.icon,
    required this.name,
    required this.qty,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String icon;
  final String name;
  final String qty;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $qty',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? accent : k.card, width: 2),
          ),
          child: Row(
            children: [
              ThreeD(icon, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.small.copyWith(fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(qty, style: AppText.tiny.copyWith(fontSize: 12, color: k.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
