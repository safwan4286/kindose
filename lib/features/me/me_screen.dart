import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../home/home_screen.dart';
import '../legal/legal_sheet.dart';
import 'me_controller.dart';

class MeScreen extends GetView<MeController> {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        controller.tracker.profile.value;
        final dark = controller.isDark;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, kNavClearance),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text('Me', style: AppText.h1)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const ThreeD(Img3d.locked, size: 18),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Stored only on this phone · no account',
                              style: AppText.small.copyWith(color: k.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  toggled: dark,
                  label: 'Dark mode',
                  excludeSemantics: true,
                  child: Material(
                    color: dark ? AppColors.lime : k.card,
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: controller.toggleDark,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              dark ? PhosphorIconsFill.moon : PhosphorIconsDuotone.sun,
                              size: 18,
                              color: dark ? AppColors.ink : k.text,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dark ? 'Dark' : 'Light',
                              style: AppText.small.copyWith(fontWeight: FontWeight.w800, color: dark ? AppColors.ink : k.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            KCard(
              color: AppColors.hero,
              radius: 24,
              onTap: controller.openPlus,
              semanticLabel: 'Try Kindose Plus, 7 days free',
              child: Row(
                children: [
                  const ThreeD(Img3d.sparkles, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Try Kindose Plus', style: AppText.title.copyWith(fontSize: 16, color: AppColors.white)),
                        Text(
                          'Meal photos, trends, encrypted backup',
                          style: AppText.small.copyWith(color: AppColors.heroMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const KTag('7 days free', bg: AppColors.lime, fg: AppColors.hero),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Treatment'),
            const SizedBox(height: 8),
            _Group(children: [
              _Row(
                icon: Img3d.syringe,
                tile: k.tint,
                title: 'Medicine & dose',
                sub: controller.medicineSub,
                onTap: controller.editPlan,
              ),
              _Row(
                icon: Img3d.alarm,
                tile: k.proteinTrack,
                title: 'Dose day & time',
                sub: controller.scheduleSub,
                onTap: controller.editPlan,
              ),
              _Row(
                icon: Img3d.egg,
                tile: k.cardAlt,
                title: 'Protein goal',
                sub: controller.goalsSub,
                onTap: () => controller.editProteinGoal(context),
              ),
              _Row(
                icon: Img3d.droplet,
                tile: k.cardAlt,
                title: 'Water goal',
                sub: 'Tap to change',
                onTap: () => controller.editWaterGoal(context),
              ),
              _Row(
                icon: Img3d.seedling,
                tile: k.cardAlt,
                title: 'Maintenance mode',
                sub: 'For tapering or after stopping',
                trailing: const PlusTag(),
                onTap: controller.openPlus,
                last: true,
              ),
            ]),
            const SizedBox(height: 16),
            const SectionLabel('Preferences'),
            const SizedBox(height: 8),
            _Group(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Expanded(child: Text('Weight unit', style: AppText.title)),
                    SizedBox(
                      width: 110,
                      child: KSegmented<bool>(
                        options: const [true, false],
                        selected: controller.useKg,
                        onChanged: controller.setUseKg,
                        labelOf: (v) => v ? 'kg' : 'lb',
                        dense: true,
                        darkSelected: true,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            const SectionLabel('Your data'),
            const SizedBox(height: 8),
            _Group(children: [
              _DataRow(
                title: controller.exporting.value ? 'Preparing…' : 'Export as CSV',
                tag: const KTag('Free', bg: AppColors.limeSoft, fg: AppColors.limeText),
                onTap: controller.exporting.value ? null : controller.exportCsv,
              ),
              _DataRow(
                title: 'Export as JSON',
                tag: const KTag('Free', bg: AppColors.limeSoft, fg: AppColors.limeText),
                onTap: controller.exporting.value ? null : controller.exportJson,
              ),
              _DataRow(title: 'Encrypted backup', tag: const PlusTag(), onTap: controller.openPlus),
              _DataRow(title: 'Terms, privacy & credits', onTap: showLegalSheet),
              _DataRow(
                title: 'Delete all my data',
                danger: true,
                onTap: () => controller.confirmDeleteAll(context),
                last: true,
              ),
            ]),
            const SizedBox(height: 16),
            Text(
              "Kindose is a personal log, not a medical device. It doesn't give dosing advice. "
              'Talk to your doctor about your treatment.',
              textAlign: TextAlign.center,
              style: AppText.tiny.copyWith(color: k.faint, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: context.k.card,
        child: Column(children: children),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tile,
    required this.title,
    required this.sub,
    required this.onTap,
    this.trailing,
    this.last = false,
  });

  final String icon;
  final Color tile;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: k.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(12)),
                child: Center(child: ThreeD(icon, size: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.title),
                    if (sub.isNotEmpty)
                      Text(sub, style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
              PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: k.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.title, required this.onTap, this.tag, this.danger = false, this.last = false});

  final String title;
  final VoidCallback? onTap;
  final Widget? tag;
  final bool danger;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: k.border))),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.title.copyWith(color: danger ? const Color(0xFFE5484D) : k.text),
                ),
              ),
              if (tag != null) tag!,
              if (tag == null && !danger) PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: k.faint),
            ],
          ),
        ),
      ),
    );
  }
}
