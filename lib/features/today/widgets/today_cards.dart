import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/images.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/drop_mark.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';
import '../today_controller.dart';

/// White rounded card used by every Today section.
class TodaySection extends StatelessWidget {
  const TodaySection({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: color ?? context.k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: child,
    );
  }
}

TextStyle _value(Color c) => AppText.h1.copyWith(
  fontSize: 24.sp,
  height: 1.1,
  letterSpacing: -0.5,
  color: c,
);

class _ValueText extends StatelessWidget {
  const _ValueText(this.value, this.suffix, {this.color});

  final String value;
  final String suffix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: value, style: _value(color ?? k.text)),
          TextSpan(
            text: ' $suffix',
            style: AppText.bodyStrong.copyWith(fontSize: 14.sp, color: k.faint),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.track, required this.fill});

  final double value;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.sp),
      child: SizedBox(
        height: 10.sp,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v.clamp(0.0, 1.0),
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(5.sp),
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

/// Small arrow that says "tap to open the full screen".
class _OpenArrow extends StatelessWidget {
  const _OpenArrow();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      width: 28.sp,
      height: 28.sp,
      margin: EdgeInsets.only(left: 8.sp),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: k.cardAlt, shape: BoxShape.circle),
      child: Icon(PhosphorIconsBold.caretRight, size: 14.sp, color: k.muted),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.sp,
      height: 44.sp,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14.sp),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

Color _tint(BuildContext context, Color light, Color accent) =>
    context.k.selectedBorder == AppColors.lime
    ? accent.withValues(alpha: 0.16)
    : light;

// ------------------------------------------------------------------ header

class TodayHeader extends GetView<TodayController> {
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final streak = controller.streak;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tap the date to see any day's log.
              Semantics(
                button: true,
                label: '${controller.dateLine}. Open day view',
                excludeSemantics: true,
                child: PressScale(
                  onTap: controller.openDay,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.sp),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.dateLine,
                          style: AppText.caps.copyWith(
                            fontSize: 12.sp,
                            letterSpacing: 1.1,
                            color: k.faint,
                          ),
                        ),
                        SizedBox(width: 6.sp),
                        Icon(
                          PhosphorIconsBold.calendarDots,
                          size: 14.sp,
                          color: k.muted,
                        ),
                        Icon(
                          PhosphorIconsBold.caretRight,
                          size: 11.sp,
                          color: k.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.sp),
              Semantics(
                header: true,
                child: Text(
                  controller.greeting,
                  style: AppText.h1.copyWith(
                    fontSize: 30.sp,
                    height: 1.08,
                    color: k.text,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (streak > 0)
          Semantics(
            label: '$streak day streak',
            button: true,
            excludeSemantics: true,
            child: PressScale(
              onTap: () {
                Haptics.instance.selectionClick();
                _showStreak(streak);
              },
              child: Container(
                height: 40.sp,
                padding: EdgeInsets.symmetric(horizontal: 12.sp),
                decoration: BoxDecoration(
                  color: k.card,
                  borderRadius: BorderRadius.circular(20.sp),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsFill.flame,
                      size: 18.sp,
                      color: AppColors.tangerine,
                    ),
                    SizedBox(width: 5.sp),
                    Text(
                      '$streak',
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: k.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showStreak(int n) {
    Get.rawSnackbar(
      messageText: Text(
        '$n ${n == 1 ? 'day' : 'days'} in a row with something logged. Keep it going!',
        style: AppText.bodyStrong.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.ink,
      borderRadius: 18,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      duration: const Duration(milliseconds: 2400),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// ------------------------------------------------------------------ set up

class SetupCard extends GetView<TodayController> {
  const SetupCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final items = controller.setupItems;
    final done = controller.setupDone;
    return TodaySection(
      padding: EdgeInsets.fromLTRB(16.sp, 12.sp, 8.sp, 6.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Get set up',
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: k.text,
                  ),
                ),
              ),
              Text(
                '$done of ${items.length}',
                style: AppText.small.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: k.muted,
                ),
              ),
              CircleIconButton(
                icon: PhosphorIconsBold.x,
                label: 'Hide set-up list',
                size: 40.sp,
                background: Colors.transparent,
                foreground: k.faint,
                onTap: controller.dismissSetup,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.sp),
            child: _Bar(
              value: done / items.length,
              track: k.border,
              fill: AppColors.lime,
            ),
          ),
          SizedBox(height: 4.sp),
          for (final item in items)
            Semantics(
              button: !item.done,
              label: '${item.label}${item.done ? ', done' : ''}',
              excludeSemantics: true,
              child: PressScale(
                onTap: item.done ? null : item.onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 9.sp),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 26.sp,
                        height: 26.sp,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.done ? k.selectedBorder : null,
                          border: item.done
                              ? null
                              : Border.all(color: k.border, width: 2),
                        ),
                        child: item.done
                            ? Icon(
                                PhosphorIconsBold.check,
                                size: 14.sp,
                                color: k.selectedBorder == AppColors.lime
                                    ? AppColors.ink
                                    : AppColors.lime,
                              )
                            : null,
                      ),
                      SizedBox(width: 12.sp),
                      Expanded(
                        child: Text(
                          item.label,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: item.done ? k.faint : k.text,
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: k.faint,
                          ),
                        ),
                      ),
                      if (!item.done)
                        Icon(
                          PhosphorIconsBold.caretRight,
                          size: 16.sp,
                          color: k.faint,
                        ),
                      SizedBox(width: 8.sp),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- protein

class ProteinCard extends GetView<TodayController> {
  const ProteinCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final left = controller.proteinLeft;
    final foods = controller.quickFoods;

    Widget chip(String label, VoidCallback onTap) => Padding(
      padding: EdgeInsets.only(right: 8.sp),
      child: Semantics(
        button: true,
        label: 'Add $label',
        excludeSemantics: true,
        child: PressScale(
          onTap: onTap,
          child: Container(
            height: 38.sp,
            padding: EdgeInsets.symmetric(horizontal: 12.sp),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19.sp),
              border: Border.all(color: k.border, width: 1.5),
            ),
            child: Text(
              label,
              style: AppText.bodyStrong.copyWith(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: k.text,
              ),
            ),
          ),
        ),
      ),
    );

    return TodaySection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label:
                'Protein ${controller.day.proteinG} of ${controller.proteinGoal} grams. Open protein',
            excludeSemantics: true,
            child: PressScale(
              onTap: controller.openProtein,
              child: Row(
                children: [
                  _IconTile(
                    color: _tint(
                      context,
                      AppColors.tangerineSoft,
                      AppColors.tangerine,
                    ),
                    child: ThreeD(Img3d.biceps, size: 30.sp),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protein',
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: k.muted,
                          ),
                        ),
                        _ValueText(
                          '${controller.day.proteinG}',
                          '/ ${controller.proteinGoal} g',
                        ),
                      ],
                    ),
                  ),
                  Text(
                    left == 0 ? 'Goal hit!' : '$left g to go',
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: dark
                          ? AppColors.tangerine
                          : AppColors.tangerineText,
                    ),
                  ),
                  const _OpenArrow(),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.sp),
          _Bar(
            value: controller.proteinProgress,
            track: _tint(context, AppColors.tangerineSoft, AppColors.tangerine),
            fill: AppColors.tangerine,
          ),
          SizedBox(height: 12.sp),
          SizedBox(
            height: 38.sp,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                chip('+10 g', () => controller.addProtein(10)),
                chip('+20 g', () => controller.addProtein(20)),
                for (final f in foods)
                  chip(
                    '${f.name.split(',').first} · ${f.grams} g',
                    () => controller.addProtein(f.grams, f.name),
                  ),
                chip('More…', controller.openProtein),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- water

class WaterCard extends GetView<TodayController> {
  const WaterCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final full = controller.glassesFull;
    final count = controller.glassCount;
    return TodaySection(
      child: Column(
        children: [
          Semantics(
            button: true,
            label:
                'Water ${controller.litres} of ${controller.waterGoalLitres} litres. Open water',
            excludeSemantics: true,
            child: PressScale(
              onTap: controller.openWater,
              child: Row(
                children: [
                  _IconTile(
                    color: _tint(context, AppColors.aquaSoft, AppColors.aqua),
                    child: SizedBox.square(
                      dimension: 30.sp,
                      child: const CustomPaint(painter: _DropIconPainter()),
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Water',
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: k.muted,
                          ),
                        ),
                        _ValueText(
                          controller.litres,
                          '/ ${controller.waterGoalLitres} L',
                        ),
                      ],
                    ),
                  ),
                  Text(
                    controller.waterGoalHit ? 'Goal hit!' : '250 ml a glass',
                    style: AppText.small.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: controller.waterGoalHit
                          ? (k.selectedBorder == AppColors.lime
                                ? AppColors.aqua
                                : AppColors.aquaText)
                          : k.faint,
                    ),
                  ),
                  const _OpenArrow(),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.sp),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            childAspectRatio: 0.95,
            children: [
              for (var i = 0; i < count; i++)
                Semantics(
                  button: true,
                  label: i < full
                      ? 'Glass ${i + 1}, full'
                      : 'Glass ${i + 1}, empty',
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: () => controller.tapGlass(i),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: i < full ? 1 : 0),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => CustomPaint(
                          size: Size.square(30.sp),
                          painter: _GlassPainter(
                            fill: v,
                            showPlus: i == full,
                            empty: _tint(
                              context,
                              AppColors.aquaSoft,
                              AppColors.aqua,
                            ),
                            edge: k.waterEdge,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter({
    required this.fill,
    required this.showPlus,
    required this.empty,
    required this.edge,
  });

  final double fill;
  final bool showPlus;
  final Color empty;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28;
    canvas.scale(s);
    final glass = Path()
      ..moveTo(5, 4)
      ..lineTo(23, 4)
      ..lineTo(21, 23.2)
      ..quadraticBezierTo(20.8, 25, 19, 25)
      ..lineTo(9, 25)
      ..quadraticBezierTo(7.2, 25, 7, 23.2)
      ..close();
    canvas.drawPath(glass, Paint()..color = empty);
    if (fill > 0) {
      canvas.save();
      canvas.clipPath(glass);
      final top = 25 - 16 * fill;
      canvas.drawRect(
        Rect.fromLTRB(0, top, 28, 28),
        Paint()..color = AppColors.aqua,
      );
      canvas.restore();
    }
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = edge,
    );
    if (showPlus && fill == 0) {
      final p = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.aqua;
      canvas.drawLine(const Offset(14, 11), const Offset(14, 19), p);
      canvas.drawLine(const Offset(10, 15), const Offset(18, 15), p);
    }
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.fill != fill || old.showPlus != showPlus || old.empty != empty;
}

class _DropIconPainter extends CustomPainter {
  const _DropIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawPath(DropMarkPainter.dropPath, Paint()..color = AppColors.aqua);
    canvas.drawPath(
      DropMarkPainter.shinePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_DropIconPainter old) => false;
}

// ------------------------------------------------------------------ weight

class WeightCard extends GetView<TodayController> {
  const WeightCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final now = controller.latestKg;
    final goal = controller.goalKg;
    Widget col(String label, String value, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.small.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: k.muted,
            ),
          ),
          _ValueText(value, controller.unit, color: color),
        ],
      ),
    );
    return TodaySection(
      child: Column(
        children: [
          Row(
            children: [
              col('Now', now == null ? '—' : controller.fmtWeight(now)),
              if (goal != null)
                col(
                  'Goal',
                  controller.fmtWeight(goal),
                  color: k.selectedBorder == AppColors.lime
                      ? AppColors.lime
                      : AppColors.limeText,
                ),
              CircleIconButton(
                icon: PhosphorIconsBold.plus,
                label: 'Log weight',
                size: 44.sp,
                background: k.selectedBorder == AppColors.lime
                    ? AppColors.lime
                    : AppColors.ink,
                foreground: k.selectedBorder == AppColors.lime
                    ? AppColors.ink
                    : AppColors.lime,
                onTap: controller.logWeight,
              ),
            ],
          ),
          if (goal != null) ...[
            SizedBox(height: 12.sp),
            _Bar(
              value: controller.goalProgress,
              track: k.border,
              fill: k.selectedBorder,
            ),
          ],
          SizedBox(height: 8.sp),
          Row(
            children: [
              Expanded(
                child: Text(
                  controller.changeSinceStart,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: k.muted,
                  ),
                ),
              ),
              Text(
                controller.lastWeighIn,
                style: AppText.small.copyWith(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: k.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------- feel

class FeelCard extends GetView<TodayController> {
  const FeelCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final selected = controller.selectedFace;
    final note = controller.feelNote;
    return TodaySection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'How are you feeling?',
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: k.text,
                  ),
                ),
              ),
              if (note.isNotEmpty)
                Text(
                  note,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: k.faint,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.sp),
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) SizedBox(width: 6.sp),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected == i,
                    label: TodayController.faceLabels[i],
                    excludeSemantics: true,
                    child: PressScale(
                      onTap: () => controller.pickFace(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 66.sp,
                        decoration: BoxDecoration(
                          color: selected == i ? k.selectedBg : k.bg,
                          borderRadius: BorderRadius.circular(16.sp),
                          border: Border.all(
                            color: selected == i
                                ? k.selectedBorder
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected == i ? 1.12 : 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: ThreeD(
                                Catalog.moods[4 - i].icon,
                                size: 28.sp,
                              ),
                            ),
                            SizedBox(height: 3.sp),
                            Text(
                              TodayController.faceLabels[i],
                              style: AppText.small.copyWith(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: k.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Always there: quiet grey before a face is picked, bold after,
          // so someone who only wants to log a side effect can find it.
          Padding(
            padding: EdgeInsets.only(top: 6.sp),
            child: Semantics(
              button: true,
              label: 'Add side effects or a note',
              excludeSemantics: true,
              child: PressScale(
                onTap: controller.openCheckIn,
                child: SizedBox(
                  height: 40.sp,
                  child: Row(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        style: AppText.small.copyWith(
                          fontSize: 13.5.sp,
                          fontWeight: selected == null
                              ? FontWeight.w700
                              : FontWeight.w800,
                          color: selected == null ? k.muted : k.text,
                        ),
                        child: Text(
                          selected == null
                              ? 'Side effects or a note'
                              : 'Add side effects or a note',
                        ),
                      ),
                      SizedBox(width: 4.sp),
                      Icon(
                        PhosphorIconsBold.caretRight,
                        size: 14.sp,
                        color: selected == null ? k.muted : k.text,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------- tip

class TipCard extends GetView<TodayController> {
  const TipCard({super.key});

  static const Map<String, String> _icons = {
    'muscle': Img3d.biceps,
    'nausea': Img3d.nauseated,
    'noise': Img3d.brain,
    'remember': Img3d.alarm,
    'nerves': Img3d.anxious,
    'progress': Img3d.chartDown,
    'cost': Img3d.moneyBag,
  };

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final (title, text) = controller.tip;
    return TodaySection(
      color: dark ? AppColors.lime.withValues(alpha: 0.12) : AppColors.limeSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThreeD(_icons[controller.tipFocus] ?? Img3d.biceps, size: 40.sp),
          SizedBox(width: 12.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.caps.copyWith(
                    fontSize: 11.5.sp,
                    letterSpacing: 0.8,
                    color: dark ? AppColors.lime : AppColors.limeText,
                  ),
                ),
                SizedBox(height: 3.sp),
                Text(
                  text,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 14.sp,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: k.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- the log

/// Compact "Today's log" row. The full list (with edit and remove) lives
/// in the Day view, so Today stays short.
class TodayLogCard extends GetView<TodayController> {
  const TodayLogCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final k = context.k;
    final rows = controller.logRows;
    int count(String kind) => rows.where((r) => r.kind == kind).length;
    final parts = <(String, Color)>[
      if (count('dose') > 0) ('Dose', AppColors.lime),
      if (count('protein') > 0)
        ('${count('protein')} protein', AppColors.tangerine),
      if (count('water') > 0) ('${count('water')} water', AppColors.aqua),
      if (count('weight') > 0) ('Weigh-in', k.muted),
    ];
    final summary = rows.isEmpty
        ? 'Nothing yet. Tap + to log anything.'
        : parts.map((p) => p.$1).join(' · ');

    return Semantics(
      button: true,
      label: "Today's log. ${rows.length} entries. $summary. Open",
      excludeSemantics: true,
      child: PressScale(
        onTap: controller.openDay,
        child: TodaySection(
          child: Row(
            children: [
              _IconTile(
                color: k.cardAlt,
                child: Icon(
                  PhosphorIconsBold.listBullets,
                  size: 20.sp,
                  color: k.text,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rows.isEmpty
                          ? "Today's log"
                          : "Today's log · ${rows.length} ${rows.length == 1 ? 'entry' : 'entries'}",
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: k.text,
                      ),
                    ),
                    SizedBox(height: 3.sp),
                    if (rows.isEmpty)
                      Text(
                        summary,
                        style: AppText.small.copyWith(
                          fontSize: 12.5.sp,
                          color: k.muted,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10.sp,
                        runSpacing: 2.sp,
                        children: [
                          for (final (label, color) in parts)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7.sp,
                                  height: 7.sp,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 5.sp),
                                Text(
                                  label,
                                  style: AppText.small.copyWith(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: k.muted,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const _OpenArrow(),
            ],
          ),
        ),
      ),
    );
  }
}
