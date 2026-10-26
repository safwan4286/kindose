import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../resources/water_units.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/day_switcher.dart';
import '../../widgets/entrance.dart';
import '../../widgets/entry_tile.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import '../common/goal_edit.dart';
import 'intake_controller.dart';
import 'widgets/water_drop.dart';
import 'widgets/intake_parts.dart';
import 'widgets/protein_tab.dart';

/// Water card style. true: the card fills with water as you drink.
/// false: the original drop card.
const bool _fillingWaterCard = true;

/// Add-water buttons. true: two per row, each with its amount.
/// false: the original row of four tiles.
const bool _waterButtonRows = true;

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
          SwipeToRemove(
            id: e.id,
            onRemove: () => controller.removeEntry(e),
            child: _EntryRow(entry: e, valueColor: dark ? k.text : valueColor),
          ),
      ],
    );
  }
}

/// The same tile as the Day screen: icon, name, time, amount.
class _EntryRow extends GetView<IntakeController> {
  const _EntryRow({required this.entry, required this.valueColor});

  final LogEntry entry;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final amount = entry.isProtein
        ? '${entry.amount} g'
        : Water.amount(entry.amount);
    final title = controller.entryTitle(entry);
    final milk = title == 'Milk';
    final icon = entry.isProtein
        ? Img3d.biceps
        : (milk ? Img3d.milk : Img3d.droplet);
    final time = controller.timeOf(entry.at);
    return Semantics(
      label: '$time, $title, $amount. Swipe left to remove.',
      excludeSemantics: true,
      child: EntryTile(
        divider: false,
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
        icon: icon,
        tint: dark
            ? k.cardAlt
            : (entry.isProtein ? AppColors.tangerineSoft : AppColors.aquaSoft),
        title: title,
        sub: time,
        amount: '+$amount',
        amountColor: valueColor,
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
          if (_fillingWaterCard)
            _FillingWaterCard(
              ml: controller.waterToday,
              goalMl: controller.waterGoal,
              progress: controller.waterProgress,
              dayTitle: controller.dayTitle,
              line: controller.waterLine,
              amount: controller.litres,
              animate: motion,
              onEditGoal: () => GoalEdit.water(context),
              onAddGlass: () => controller.addDrink(Catalog.waterSizes.first),
            ).enter(motion)
          else
          Semantics(
            label:
                'Water ${controller.dayTitle.toLowerCase()}: ${controller.litres(controller.waterToday)} of ${controller.litres(controller.waterGoal)} ${Water.unitWords}. ${controller.waterLine}',
            onTapHint: 'change your daily goal',
            onTap: () => GoalEdit.water(context),
            excludeSemantics: true,
            // The whole card opens the goal, not just "of 3 L".
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => GoalEdit.water(context),
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
                            GoalLink(
                              text:
                                  'of ${controller.litres(controller.waterGoal)} ${Water.unit}',
                              fontSize: 15,
                              onTap: () => GoalEdit.water(context),
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
            ),
          ).enter(motion),
          const IntakeLabel('Add water', trailing: 'One tap adds it'),
          if (_waterButtonRows)
            _WaterButtons(
              onDrink: controller.addDrink,
              onCustom: () => controller.addCustomWater(context),
            ).enter(motion, delay: 80)
          else
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
                        'Add ${d.label.toLowerCase()}, ${Water.amount(d.mlFor(Water.oz))}',
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

/// Water card that fills from the bottom as the day's water goes in; the
/// surface keeps a slow wave (still when reduce-motion is on). Tapping the
/// card edits the goal; "+ Glass" adds one glass.
class _FillingWaterCard extends StatefulWidget {
  const _FillingWaterCard({
    required this.ml,
    required this.goalMl,
    required this.progress,
    required this.dayTitle,
    required this.line,
    required this.amount,
    required this.animate,
    required this.onEditGoal,
    required this.onAddGlass,
  });

  final int ml;
  final int goalMl;

  /// 0–1 of the goal.
  final double progress;
  final String dayTitle;
  final String line;

  /// Number only ("1.25"); the unit is [Water.unit].
  final String Function(int ml) amount;
  final bool animate;
  final VoidCallback onEditGoal;
  final VoidCallback onAddGlass;

  @override
  State<_FillingWaterCard> createState() => _FillingWaterCardState();
}

class _FillingWaterCardState extends State<_FillingWaterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _wave.repeat();
  }

  @override
  void didUpdateWidget(_FillingWaterCard old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_wave.isAnimating) _wave.repeat();
    if (!widget.animate && _wave.isAnimating) _wave.stop();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final pct = (widget.progress * 100).round();
    final unit = Water.unit;
    return Semantics(
      label:
          'Water ${widget.dayTitle.toLowerCase()}: ${widget.amount(widget.ml)} of ${widget.amount(widget.goalMl)} ${Water.unitWords}. ${widget.line}',
      onTapHint: 'change your daily goal',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onEditGoal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.sp),
          child: Container(
            height: 210.sp,
            color: k.card,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: widget.progress.clamp(0.0, 1.0)),
                    duration: Duration(milliseconds: widget.animate ? 700 : 0),
                    curve: Curves.easeOutCubic,
                    builder: (context, level, _) => AnimatedBuilder(
                      animation: _wave,
                      builder: (context, _) => CustomPaint(
                        painter: _WaterFillPainter(
                          level: level,
                          phase: _wave.value,
                          back: dark
                              ? AppColors.aqua.withValues(alpha: 0.14)
                              : AppColors.aquaSoft,
                          front: AppColors.aqua.withValues(
                            alpha: dark ? 0.3 : 0.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.sp, 18.sp, 16.sp, 16.sp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          'WATER · ${widget.dayTitle.toUpperCase()}',
                          style: intakeCaps(context).copyWith(color: k.faint),
                        ),
                      ),
                      SizedBox(height: 10.sp),
                      ExcludeSemantics(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: widget.amount(widget.ml),
                                style: AppText.number(
                                  44.sp,
                                ).copyWith(color: k.text),
                              ),
                              TextSpan(
                                text: ' $unit',
                                style: AppText.title.copyWith(
                                  fontSize: 18.sp,
                                  color: k.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ExcludeSemantics(
                        child: GoalLink(
                          text:
                              'of ${widget.amount(widget.goalMl)} $unit goal · $pct%',
                          fontSize: 14,
                          onTap: widget.onEditGoal,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: ExcludeSemantics(
                              child: Text(
                                widget.line,
                                style: AppText.small.copyWith(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? AppColors.aqua
                                      : AppColors.aquaText,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.sp),
                          PressScale(
                            semanticLabel:
                                'Add a glass, ${Water.amount(Water.glassMl)}',
                            onTap: widget.onAddGlass,
                            child: Container(
                              height: 38.sp,
                              padding: EdgeInsets.symmetric(horizontal: 14.sp),
                              decoration: BoxDecoration(
                                color: dark ? AppColors.lime : AppColors.ink,
                                borderRadius: BorderRadius.circular(19.sp),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIconsBold.plus,
                                    size: 14.sp,
                                    color: dark
                                        ? AppColors.ink
                                        : AppColors.white,
                                  ),
                                  SizedBox(width: 6.sp),
                                  Text(
                                    'Glass',
                                    style: AppText.bodyStrong.copyWith(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: dark
                                          ? AppColors.ink
                                          : AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two offset waves filling the card to [level] (0–1). A sliver always
/// shows so an empty day still reads as "water goes here".
class _WaterFillPainter extends CustomPainter {
  _WaterFillPainter({
    required this.level,
    required this.phase,
    required this.back,
    required this.front,
  });

  final double level;
  final double phase;
  final Color back;
  final Color front;

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height * (1 - (0.05 + 0.95 * level));
    final amp = 5.0 * (level >= 1 ? 0.4 : 1);
    void wave(Color c, double shift, double lift) {
      double y(double x) =>
          top +
          lift +
          amp *
              math.sin(
                x / size.width * 2 * math.pi * 1.3 +
                    (phase + shift) * 2 * math.pi,
              );
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x < size.width; x += 4) {
        path.lineTo(x, y(x));
      }
      // End exactly on the right edge, whatever the width.
      path.lineTo(size.width, y(size.width));
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }

    wave(back, 0, 0);
    wave(front, 0.35, 6);
  }

  @override
  bool shouldRepaint(_WaterFillPainter old) =>
      old.level != level ||
      old.phase != phase ||
      old.back != back ||
      old.front != front;
}

/// Add-water buttons, two per row: glass and bottle, large bottle and
/// custom. Each names its size and how much one tap adds.
class _WaterButtons extends StatelessWidget {
  const _WaterButtons({required this.onDrink, required this.onCustom});

  final void Function(Drink d) onDrink;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final sizes = Catalog.waterSizes;
    final buttons = <Widget>[
      for (final (i, d) in sizes.indexed)
        _WaterButton(
          label: d.label,
          amount: Water.amount(d.mlFor(Water.oz)),
          level: i,
          onTap: () => onDrink(d),
        ),
      _WaterButton(
        label: 'Custom',
        amount: 'Any amount',
        level: -1,
        onTap: onCustom,
      ),
    ];
    return Column(
      children: [
        for (var r = 0; r < buttons.length; r += 2) ...[
          if (r > 0) SizedBox(height: 8.sp),
          Row(
            children: [
              Expanded(child: buttons[r]),
              SizedBox(width: 8.sp),
              Expanded(
                child: r + 1 < buttons.length
                    ? buttons[r + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({
    required this.label,
    required this.amount,
    required this.level,
    required this.onTap,
  });

  final String label;
  final String amount;

  /// 0 glass, 1 bottle, 2 litre, -1 custom.
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final custom = level < 0;
    final accent = dark ? AppColors.aqua : AppColors.aquaText;
    final h = switch (level) {
      1 => 24.0,
      2 => 27.0,
      _ => 20.0,
    };
    return PressScale(
      pressedScale: 0.96,
      semanticLabel: custom
          ? 'Add a custom amount'
          : 'Add ${label.toLowerCase()}, $amount',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.fromLTRB(10.sp, 10.sp, 12.sp, 10.sp),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(16.sp),
          ),
          child: Row(
            children: [
              Container(
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  color: custom
                      ? k.cardAlt
                      : (dark
                            ? AppColors.aqua.withValues(alpha: 0.16)
                            : AppColors.aquaSoft),
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                alignment: Alignment.center,
                child: custom
                    ? Icon(
                        PhosphorIconsBold.pencilSimple,
                        size: 18.sp,
                        color: k.muted,
                      )
                    : CustomPaint(
                        size: Size((h * 0.75).sp, h.sp),
                        painter: const _GlassPainter(),
                      ),
              ),
              SizedBox(width: 10.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: AppText.bodyStrong.copyWith(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          color: k.text,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.sp),
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: custom ? k.muted : accent,
                      ),
                    ),
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
        padding: EdgeInsets.fromLTRB(6.sp, 14.sp, 6.sp, 8.sp),
        // Icon at the same height on every tile; the name is centred in the
        // space below, so a two-line name ("Large bottle") stays centred.
        child: Column(
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
            Expanded(
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(
                    fontSize: 13.sp,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: k.text,
                  ),
                ),
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
