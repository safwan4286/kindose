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
  const TodaySection({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.sp),
      decoration: BoxDecoration(color: color ?? context.k.card, borderRadius: BorderRadius.circular(22.sp)),
      child: child,
    );
  }
}

TextStyle _value(Color c) => AppText.h1.copyWith(fontSize: 24.sp, height: 1.1, letterSpacing: -0.5, color: c);

class _ValueText extends StatelessWidget {
  const _ValueText(this.value, this.suffix, {this.color});

  final String value;
  final String suffix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Text.rich(TextSpan(children: [
      TextSpan(text: value, style: _value(color ?? k.text)),
      TextSpan(text: ' $suffix', style: AppText.bodyStrong.copyWith(fontSize: 14.sp, color: k.faint)),
    ]));
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
                  decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5.sp)),
                ),
              ),
            ),
          ],
        ),
      ),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14.sp)),
      alignment: Alignment.center,
      child: child,
    );
  }
}

Color _tint(BuildContext context, Color light, Color accent) =>
    context.k.selectedBorder == AppColors.lime ? accent.withValues(alpha: 0.16) : light;

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
              Text(controller.dateLine, style: AppText.caps.copyWith(fontSize: 12.sp, letterSpacing: 1.1, color: k.faint)),
              SizedBox(height: 4.sp),
              Semantics(
                header: true,
                child: Text(controller.greeting, style: AppText.h1.copyWith(fontSize: 30.sp, height: 1.08, color: k.text)),
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
                decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(20.sp)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsFill.flame, size: 18.sp, color: AppColors.tangerine),
                    SizedBox(width: 5.sp),
                    Text('$streak', style: AppText.bodyStrong.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w800, color: k.text)),
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
                child: Text('Get set up', style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: k.text)),
              ),
              Text('$done of ${items.length}', style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: k.muted)),
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
            child: _Bar(value: done / items.length, track: k.border, fill: AppColors.lime),
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
                          border: item.done ? null : Border.all(color: k.border, width: 2),
                        ),
                        child: item.done
                            ? Icon(PhosphorIconsBold.check, size: 14.sp, color: k.selectedBorder == AppColors.lime ? AppColors.ink : AppColors.lime)
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
                            decoration: item.done ? TextDecoration.lineThrough : null,
                            decorationColor: k.faint,
                          ),
                        ),
                      ),
                      if (!item.done) Icon(PhosphorIconsBold.caretRight, size: 16.sp, color: k.faint),
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
                child: Text(label, style: AppText.bodyStrong.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: k.text)),
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
            label: 'Protein ${controller.day.proteinG} of ${controller.proteinGoal} grams. Open protein',
            excludeSemantics: true,
            child: PressScale(
              onTap: controller.openProtein,
              child: Row(
                children: [
                  _IconTile(color: _tint(context, AppColors.tangerineSoft, AppColors.tangerine), child: ThreeD(Img3d.biceps, size: 30.sp)),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Protein', style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: k.muted)),
                        _ValueText('${controller.day.proteinG}', '/ ${controller.proteinGoal} g'),
                      ],
                    ),
                  ),
                  Text(
                    left == 0 ? 'Goal hit!' : '$left g to go',
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: dark ? AppColors.tangerine : AppColors.tangerineText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.sp),
          _Bar(value: controller.proteinProgress, track: _tint(context, AppColors.tangerineSoft, AppColors.tangerine), fill: AppColors.tangerine),
          SizedBox(height: 12.sp),
          SizedBox(
            height: 38.sp,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                chip('+10 g', () => controller.addProtein(10)),
                chip('+20 g', () => controller.addProtein(20)),
                for (final f in foods) chip('${f.name.split(',').first} · ${f.grams} g', () => controller.addProtein(f.grams, f.name)),
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
          Row(
            children: [
              _IconTile(
                color: _tint(context, AppColors.aquaSoft, AppColors.aqua),
                child: SizedBox.square(dimension: 30.sp, child: const CustomPaint(painter: _DropIconPainter())),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Water', style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: k.muted)),
                    _ValueText(controller.litres, '/ ${controller.waterGoalLitres} L'),
                  ],
                ),
              ),
              Text('Tap a glass · 250 ml', style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.faint)),
            ],
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
                  label: i < full ? 'Glass ${i + 1}, full' : 'Glass ${i + 1}, empty',
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
                            empty: _tint(context, AppColors.aquaSoft, AppColors.aqua),
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
  const _GlassPainter({required this.fill, required this.showPlus, required this.empty, required this.edge});

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
      canvas.drawRect(Rect.fromLTRB(0, top, 28, 28), Paint()..color = AppColors.aqua);
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
  bool shouldRepaint(_GlassPainter old) => old.fill != fill || old.showPlus != showPlus || old.empty != empty;
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
              Text(label, style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.muted)),
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
              if (goal != null) col('Goal', controller.fmtWeight(goal), color: k.selectedBorder == AppColors.lime ? AppColors.lime : AppColors.limeText),
              CircleIconButton(
                icon: PhosphorIconsBold.plus,
                label: 'Log weight',
                size: 44.sp,
                background: k.selectedBorder == AppColors.lime ? AppColors.lime : AppColors.ink,
                foreground: k.selectedBorder == AppColors.lime ? AppColors.ink : AppColors.lime,
                onTap: controller.logWeight,
              ),
            ],
          ),
          if (goal != null) ...[
            SizedBox(height: 12.sp),
            _Bar(value: controller.goalProgress, track: k.border, fill: k.selectedBorder),
          ],
          SizedBox(height: 8.sp),
          Row(
            children: [
              Expanded(child: Text(controller.changeSinceStart, style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.muted))),
              Text(controller.lastWeighIn, style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.muted)),
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
                child: Text('How are you feeling?', style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: k.text)),
              ),
              if (note.isNotEmpty) Text(note, style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.faint)),
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
                          border: Border.all(color: selected == i ? k.selectedBorder : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected == i ? 1.12 : 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: ThreeD(Catalog.moods[4 - i].icon, size: 28.sp),
                            ),
                            SizedBox(height: 3.sp),
                            Text(
                              TodayController.faceLabels[i],
                              style: AppText.small.copyWith(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: k.muted),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: selected == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.only(top: 6.sp),
                    child: Semantics(
                      button: true,
                      label: 'Add side effects and notes',
                      excludeSemantics: true,
                      child: PressScale(
                        onTap: controller.openCheckIn,
                        child: SizedBox(
                          height: 40.sp,
                          child: Row(
                            children: [
                              Text(
                                'Add side effects or a note',
                                style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: k.text),
                              ),
                              SizedBox(width: 4.sp),
                              Icon(PhosphorIconsBold.caretRight, size: 14.sp, color: k.text),
                            ],
                          ),
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
                Text(title, style: AppText.caps.copyWith(fontSize: 11.5.sp, letterSpacing: 0.8, color: dark ? AppColors.lime : AppColors.limeText)),
                SizedBox(height: 3.sp),
                Text(text, style: AppText.bodyStrong.copyWith(fontSize: 14.sp, height: 1.45, fontWeight: FontWeight.w600, color: k.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- the log

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
    Color dot(String kind) => switch (kind) {
          'protein' => AppColors.tangerine,
          'water' => AppColors.aqua,
          'dose' => AppColors.lime,
          _ => k.muted,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel("TODAY'S LOG")),
            if (rows.any((r) => r.entryId != null))
              Text('Swipe to remove', style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.faint)),
          ],
        ),
        SizedBox(height: 8.sp),
        TodaySection(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 2.sp),
          child: rows.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.sp),
                  child: Text(
                    'Nothing yet today. Tap + to log anything.',
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(fontSize: 13.5.sp, color: k.muted),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      _row(context, rows[i], dot(rows[i].kind), last: i == rows.length - 1),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, TodayLogRow r, Color dot, {required bool last}) {
    final k = context.k;
    final content = Container(
      padding: EdgeInsets.symmetric(vertical: 11.sp),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: k.border))),
      child: Row(
        children: [
          Container(width: 10.sp, height: 10.sp, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          SizedBox(width: 12.sp),
          SizedBox(
            width: 70.sp,
            child: Text(
              r.at == null ? 'Today' : controller.timeOf(r.at!),
              maxLines: 1,
              style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.faint),
            ),
          ),
          Expanded(
            child: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700, color: k.text)),
          ),
          SizedBox(width: 8.sp),
          Text(r.value, style: AppText.bodyStrong.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: k.text)),
        ],
      ),
    );
    if (r.entryId == null) return content;
    return Dismissible(
      key: ValueKey(r.entryId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.removeRow(r),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 8.sp),
        child: Icon(PhosphorIconsBold.trash, size: 20.sp, color: AppColors.danger),
      ),
      child: content,
    );
  }
}
