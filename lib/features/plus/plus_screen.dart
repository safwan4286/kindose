import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../legal/legal_sheet.dart';
import 'plus_controller.dart';

class PlusScreen extends GetView<PlusController> {
  const PlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PopScope(
      canPop: !controller.fromOnboarding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.close();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
        backgroundColor: AppColors.hero,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 18, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Floaty(child: ThreeD(Img3d.sparkles, size: 68)),
                          const SizedBox(height: 6),
                          Text(
                            'KINDOSE PLUS',
                            style: AppText.caps.copyWith(fontSize: 13, letterSpacing: 1.2, color: AppColors.lime),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            header: true,
                            child: Text(
                              'Go further with your treatment',
                              style: AppText.h1.copyWith(fontSize: 32, color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleIconButton(
                      icon: PhosphorIconsBold.x,
                      label: 'Close',
                      size: 40,
                      background: AppColors.white.withValues(alpha: 0.1),
                      foreground: AppColors.white,
                      onTap: controller.close,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: k.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                    children: [
                      const _Perk(Img3d.curryRice, 'Snap a meal, get protein in seconds'),
                      const _Perk(Img3d.chartUp, 'Side-effect and protein insights'),
                      const _Perk(Img3d.clipboard, 'Doctor report with trend charts'),
                      const _Perk(Img3d.locked, 'Encrypted backup across devices'),
                      const SizedBox(height: 8),
                      Obx(() => Column(
                            children: [
                              for (final p in PlusController.plans) ...[
                                _PlanTile(
                                  plan: p,
                                  selected: controller.selected.value == p.id,
                                  onTap: () => controller.selected.value = p.id,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          )),
                      const SizedBox(height: 6),
                      Obx(() => SoftButton(
                            label: controller.cta,
                            background: AppColors.violet,
                            foreground: AppColors.white,
                            height: 60,
                            onPressed: controller.subscribe,
                          )),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                            controller.fine,
                            textAlign: TextAlign.center,
                            style: AppText.tiny.copyWith(fontSize: 12, color: k.muted, fontWeight: FontWeight.w500),
                          )),
                      const SizedBox(height: 12),
                      SoftButton(
                        label: 'Continue with free',
                        outlined: true,
                        height: 50,
                        onPressed: controller.close,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(onPressed: controller.restore, child: const Text('Restore')),
                          TextButton(onPressed: showLegalSheet, child: const Text('Terms & privacy')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.icon, this.text);

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ThreeD(icon, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.bodyStrong.copyWith(fontSize: 15))),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  final PlusPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.name}, ${plan.price}. ${plan.sub}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: selected ? AppColors.violet : k.card, width: 2),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: k.card,
                      border: Border.all(
                        color: selected ? AppColors.violet : k.border,
                        width: selected ? 7 : 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: AppText.title.copyWith(fontSize: 16)),
                        Text(plan.sub, style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text(plan.price, style: AppText.h3.copyWith(fontSize: 20)),
                ],
              ),
            ),
            if (plan.best)
              const Positioned(
                right: 14,
                top: -11,
                child: KTag('Best value', bg: AppColors.lime, fg: AppColors.hero),
              ),
          ],
        ),
      ),
    );
  }
}
