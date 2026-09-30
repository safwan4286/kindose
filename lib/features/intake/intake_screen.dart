import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/day_switcher.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'intake_controller.dart';
import 'widgets/water_drop.dart';
import 'widgets/intake_parts.dart';
import 'widgets/protein_tab.dart';

/// Protein and water. One tap adds, every add can be undone.
class IntakeScreen extends GetView<IntakeController> {
  const IntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Scaffold(
      backgroundColor: k.bg,
      body: KSafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 10.sp),
              child: Row(
                children: [
                  BackCircle(onTap: popRoute),
                  SizedBox(width: 12.sp),
                  // One screen per card: Protein or Water (no tabs).
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        controller.isProtein ? 'Protein' : 'Water',
                        style: AppText.h2.copyWith(
                          fontSize: 22.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                  ),
                  DaySwitcher(nav: controller),
                ],
              ),
            ),
            PastDayBanner(nav: controller),
            Expanded(
              child: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  child: controller.isProtein
                      ? const ProteinTab(key: ValueKey('protein'))
                      : const _WaterTab(key: ValueKey('water')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ shared

/// "Today" heading; the swipe hint shows only when there is something
/// to swipe.
class _TodayLabel extends GetView<IntakeController> {
  const _TodayLabel({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    final has = controller.entriesFor(kind).isNotEmpty;
    return IntakeLabel(
      controller.dayTitle,
      trailing: has ? 'Swipe left to remove' : null,
    );
  });
}

class _EntryList extends GetView<IntakeController> {
  const _EntryList({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.watch();
      return _build(context);
    });
  }

  Widget _build(BuildContext context) {
    final k = context.k;
    final entries = controller.entriesFor(kind);
    if (entries.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(22.sp),
        ),
        child: Text(
          kind == 'protein'
              ? (controller.isToday
                    ? 'Nothing yet today. Tap + on a food to add it.'
                    : 'Nothing logged this day. Tap + on a food to add it.')
              : (controller.isToday
                    ? 'Nothing yet today. Tap a glass to add it.'
                    : 'Nothing logged this day. Tap a glass to add it.'),
          style: AppText.small.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: k.muted,
          ),
        ),
      );
    }
    final valueColor = kind == 'protein'
        ? AppColors.tangerineText
        : AppColors.aquaText;
    final dark = k.selectedBorder == AppColors.lime;
    return IntakeCard(
      children: [
        for (final e in entries)
          Dismissible(
            key: ValueKey(e.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => controller.removeEntry(e),
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 18.sp),
              color: AppColors.dangerSoft,
              child: Icon(
                PhosphorIconsBold.trash,
                size: 20.sp,
                color: AppColors.danger,
              ),
            ),
            child: _EntryRow(entry: e, valueColor: dark ? k.text : valueColor),
          ),
      ],
    );
  }
}

class _EntryRow extends GetView<IntakeController> {
  const _EntryRow({required this.entry, required this.valueColor});

  final LogEntry entry;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final unit = entry.isProtein ? 'g' : 'ml';
    final title = controller.entryTitle(entry);
    return Semantics(
      label:
          '${controller.timeOf(entry.at)}, $title, ${entry.amount} $unit. Swipe left to remove.',
      excludeSemantics: true,
      child: Container(
        color: k.card,
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        child: Row(
          children: [
            SizedBox(
              width: 66.sp,
              child: Text(
                controller.timeOf(entry.at),
                style: AppText.small.copyWith(
                  fontSize: 12.5.sp,
                  color: k.faint,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 14.5.sp,
                  color: k.text,
                ),
              ),
            ),
            SizedBox(width: 8.sp),
            Text(
              '+${entry.amount} $unit',
              style: AppText.title.copyWith(
                fontSize: 14.5.sp,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- water

class _WaterTab extends GetView<IntakeController> {
  const _WaterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final k = context.k;
    return Obx(() {
      controller.watch();
      final dark = k.selectedBorder == AppColors.lime;
      final tileBg = dark ? k.card : AppColors.aquaSoft;
      return ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 32.sp),
        children: [
          Semantics(
            label:
                'Water ${controller.dayTitle.toLowerCase()}: ${controller.litres(controller.waterToday)} of ${controller.litres(controller.waterGoal)} litres. ${controller.waterLine}',
            excludeSemantics: true,
            child: Container(
              padding: EdgeInsets.fromLTRB(18.sp, 20.sp, 18.sp, 20.sp),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(24.sp),
              ),
              child: Row(
                children: [
                  WaterDrop(
                    size: 128.sp,
                    fill: controller.waterProgress,
                    animate: motion,
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WATER · ${controller.dayTitle.toUpperCase()}',
                          style: intakeCaps(context).copyWith(color: k.faint),
                        ),
                        SizedBox(height: 6.sp),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 5.sp,
                          children: [
                            Text(
                              controller.litres(controller.waterToday),
                              style: AppText.number(
                                40.sp,
                              ).copyWith(color: k.text),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 3.sp),
                              child: Text(
                                'of ${controller.litres(controller.waterGoal)} L',
                                style: AppText.title.copyWith(
                                  fontSize: 15.sp,
                                  color: k.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.sp),
                        Text(
                          controller.waterLine,
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            color: dark ? AppColors.aqua : AppColors.aquaText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).enter(motion),
          const IntakeLabel('Add water', trailing: 'One tap adds it'),
          Row(
            children: [
              for (final (i, d) in Catalog.waterSizes.indexed) ...[
                if (i > 0) SizedBox(width: 8.sp),
                Expanded(
                  child: _WaterTile(
                    label: d.label,
                    level: i,
                    bg: tileBg,
                    semantic:
                        'Add ${d.label.toLowerCase()}, ${d.ml} millilitres',
                    onTap: () => controller.addDrink(d),
                  ),
                ),
              ],
              SizedBox(width: 8.sp),
              Expanded(
                child: _WaterTile(
                  label: 'Custom',
                  level: -1,
                  bg: tileBg,
                  semantic: 'Add a custom amount',
                  onTap: () => controller.addCustomWater(context),
                ),
              ),
            ],
          ).enter(motion, delay: 80),
          // const IntakeLabel('Other drinks count too'),
          // Wrap(
          //   spacing: 8.sp,
          //   runSpacing: 8.sp,
          //   children: [
          //     for (final d in controller.otherDrinks)
          //       PressScale(
          //         semanticLabel:
          //             'Add ${d.label.toLowerCase()}, ${d.ml} millilitres',
          //         onTap: () => controller.addDrink(d),
          //         child: Container(
          //           height: 40.sp,
          //           padding: EdgeInsets.symmetric(horizontal: 14.sp),
          //           decoration: BoxDecoration(
          //             color: k.card,
          //             borderRadius: BorderRadius.circular(20.sp),
          //             border: Border.all(color: k.border, width: 1.5),
          //           ),
          //           child: Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Text(
          //                 d.label,
          //                 style: AppText.small.copyWith(
          //                   fontSize: 13.5.sp,
          //                   fontWeight: FontWeight.w800,
          //                   color: k.text,
          //                 ),
          //               ),
          //               Text(
          //                 ' · ${d.ml} ml',
          //                 style: AppText.small.copyWith(
          //                   fontSize: 13.5.sp,
          //                   fontWeight: FontWeight.w600,
          //                   color: k.faint,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //   ],
          // ).enter(motion, delay: 120),
          SizedBox(height: 16.sp),
          Container(
            padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 16.sp, 14.sp),
            decoration: BoxDecoration(
              color: k.cardAlt,
              borderRadius: BorderRadius.circular(18.sp),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThreeD(Img3d.droplet, size: 30.sp),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Small sips, often. ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'Many people feel less thirsty on these medicines, so a glass at each meal and between meals helps.',
                        ),
                      ],
                    ),
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: k.textSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _TodayLabel(kind: 'water'),
          const _EntryList(kind: 'water'),
          if (controller.entriesFor('water').isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: LinkButton(
                label: 'Undo last',
                color: k.text,
                onTap: () => controller.undoLast('water'),
              ),
            ),
        ],
      );
    });
  }
}

class _WaterTile extends StatelessWidget {
  const _WaterTile({
    required this.label,
    required this.level,
    required this.bg,
    required this.semantic,
    required this.onTap,
  });

  final String label;

  /// 0 glass, 1 bottle, 2 litre, -1 custom.
  final int level;
  final Color bg;
  final String semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final h = switch (level) {
      1 => 28.0,
      2 => 32.0,
      _ => 24.0,
    };
    return PressScale(
      pressedScale: 0.94,
      semanticLabel: semantic,
      onTap: onTap,
      child: Container(
        height: 96.sp,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.sp),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32.sp,
              child: Center(
                child: level < 0
                    ? Icon(
                        PhosphorIconsBold.pencilSimple,
                        size: 22.sp,
                        color: AppColors.aqua,
                      )
                    : CustomPaint(
                        size: Size((h * 0.75).sp, h.sp),
                        painter: const _GlassPainter(),
                      ),
              ),
            ),
            SizedBox(height: 6.sp),
            Text(
              label,
              style: AppText.small.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: k.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glass = Path()
      ..moveTo(w * 0.08, h * 0.06)
      ..lineTo(w * 0.92, h * 0.06)
      ..lineTo(w * 0.8, h * 0.96)
      ..lineTo(w * 0.2, h * 0.96)
      ..close();
    canvas.drawPath(glass, Paint()..color = AppColors.white);
    canvas.save();
    canvas.clipPath(glass);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.42, w, h),
      Paint()..color = AppColors.aqua,
    );
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.aqua,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => false;
}
