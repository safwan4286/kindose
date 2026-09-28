import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/weight_chart.dart';
import '../home/home_screen.dart';
import 'progress_controller.dart';

/// Progress tab: weight trend, doses and spots, protein & water week, and
/// how you felt over 4 weeks. 4 weeks are free; longer ranges need Plus.
class ProgressScreen extends GetView<ProgressController> {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      bottom: false,
      child: Obx(() {
        controller.watch();
        final week = _treatmentWeek();
        return ListView(
          padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, kNavClearance),
          children: [
            if (week != null)
              Text('WEEK $week OF TREATMENT', style: _caps(context)).enter(motion),
            SizedBox(height: 4.sp),
            Semantics(
              header: true,
              child: Text('Progress', style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text)),
            ).enter(motion),
            SizedBox(height: 16.sp),
            _RangeSwitch(controller: controller).enter(motion, delay: 40),
            SizedBox(height: 14.sp),
            _WeightCard(controller: controller).enter(motion, delay: 60),
            SizedBox(height: 12.sp),
            if (controller.hasDoses) ...[
              _DosesCard(controller: controller).enter(motion, delay: 100),
              SizedBox(height: 12.sp),
            ],
            _BarsCard(
              title: 'Protein · last 7 days',
              goalLabel: 'Goal ${controller.profile?.proteinGoalG ?? 100} g',
              headline: controller.barsHeadline(controller.proteinBars, water: false),
              bars: controller.proteinBars,
              color: AppColors.tangerine,
              valueLabel: (v) => '${v.round()} g',
            ).enter(motion, delay: 140),
            SizedBox(height: 12.sp),
            _BarsCard(
              title: 'Water · last 7 days',
              goalLabel: 'Goal ${((controller.profile?.waterGoalMl ?? 2500) / 1000).toStringAsFixed(1)} L',
              headline: controller.barsHeadline(controller.waterBars, water: true),
              bars: controller.waterBars,
              color: AppColors.aqua,
              valueLabel: (v) => '${(v / 1000).toStringAsFixed(1)} L',
            ).enter(motion, delay: 170),
            SizedBox(height: 12.sp),
            _FeelCard(controller: controller).enter(motion, delay: 200),
            SizedBox(height: 12.sp),
            _ReportNudge(onTap: controller.openReport).enter(motion, delay: 230),
          ],
        );
      }),
    );
  }

  int? _treatmentWeek() {
    final t = controller.tracker;
    final start = controller.profile?.treatmentStartedAt ?? (t.doses.isEmpty ? null : t.doses.last.takenAt);
    if (start == null || start.isAfter(DateTime.now())) return null;
    return Dates.daysBetween(start, DateTime.now()) ~/ 7 + 1;
  }
}

TextStyle _caps(BuildContext c) => AppText.caps.copyWith(fontSize: 12.sp, letterSpacing: 1.1, color: c.k.faint);

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(16.sp),
      decoration: BoxDecoration(color: context.k.card, borderRadius: BorderRadius.circular(24.sp)),
      child: child,
    );
  }
}

class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({required this.controller});

  final ProgressController controller;

  static const Map<ProgressRange, String> _labels = {
    ProgressRange.month: '4 weeks',
    ProgressRange.quarter: '3 months',
    ProgressRange.all: 'All time',
  };

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final plus = controller.isPlus;
    return Container(
      padding: EdgeInsets.all(4.sp),
      decoration: BoxDecoration(color: k.cardAlt, borderRadius: BorderRadius.circular(20.sp)),
      child: Row(
        children: [
          for (final r in ProgressRange.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: controller.range.value == r,
                inMutuallyExclusiveGroup: true,
                label: '${_labels[r]}${r != ProgressRange.month && !plus ? ', Plus' : ''}',
                excludeSemantics: true,
                child: PressScale(
                  pressedScale: 0.95,
                  onTap: () => controller.pickRange(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 38.sp,
                    decoration: BoxDecoration(
                      color: controller.range.value == r ? k.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.sp),
                      boxShadow: controller.range.value == r
                          ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 6.sp, offset: Offset(0, 2.sp))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _labels[r] ?? '',
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            color: controller.range.value == r ? k.text : k.muted,
                          ),
                        ),
                        if (r != ProgressRange.month && !plus) ...[
                          SizedBox(width: 4.sp),
                          Icon(PhosphorIconsFill.lockSimple, size: 12.sp, color: k.text),
                        ],
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

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final pts = controller.points;
    final chips = [controller.bmiLabel, controller.toGoalLabel].whereType<String>().toList();
    return _Card(
      padding: EdgeInsets.fromLTRB(16.sp, 18.sp, 16.sp, 14.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  label: controller.hasWeights
                      ? 'Weight since you started: ${controller.changeNumber} ${controller.unit}. ${controller.changeLine}'
                      : 'No weigh-ins yet',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WEIGHT · SINCE YOU STARTED', style: _caps(context)),
                      SizedBox(height: 6.sp),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(controller.changeNumber, style: AppText.number(40.sp).copyWith(color: k.text)),
                          SizedBox(width: 6.sp),
                          Text(controller.unit, style: AppText.title.copyWith(fontSize: 16.sp, color: k.muted)),
                        ],
                      ),
                      if (controller.changeLine.isNotEmpty) ...[
                        SizedBox(height: 4.sp),
                        Text(controller.changeLine, style: AppText.small.copyWith(fontSize: 13.sp, color: k.muted)),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.sp),
              PressScale(
                semanticLabel: 'Log weight',
                onTap: controller.logWeight,
                child: Container(
                  height: 36.sp,
                  padding: EdgeInsets.symmetric(horizontal: 12.sp),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.sp),
                    border: Border.all(color: k.border, width: 1.5),
                  ),
                  child: Text('+ Log', style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: k.text)),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.sp),
          Stack(
            children: [
              if (pts.length >= 2)
                WeightChart(
                  dates: [for (final p in pts) p.date],
                  values: [for (final p in pts) controller.shown(p.kg)],
                  unit: controller.unit,
                  selected: controller.selected.value,
                  onPick: controller.pickPoint,
                  goal: controller.showGoalLine ? controller.goalShown : null,
                  markers: [for (final m in controller.doseMarkers) (m.date, m.label)],
                )
              else
                Container(
                  height: 120.sp,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 24.sp),
                  child: Text(
                    pts.isEmpty
                        ? 'No weigh-ins in this range yet. Weigh in once a week to see your trend.'
                        : 'One more weigh-in and your trend line appears.',
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: k.muted),
                  ),
                ),
              if (controller.locked) Positioned.fill(child: _LockOverlay(onTap: controller.openPlus)),
            ],
          ),
          if (chips.isNotEmpty) ...[
            SizedBox(height: 4.sp),
            Wrap(
              spacing: 8.sp,
              runSpacing: 6.sp,
              children: [
                for (final c in chips)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 5.sp),
                    decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(10.sp)),
                    child: Text(c, style: AppText.small.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w800, color: k.textSoft)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LockOverlay extends StatelessWidget {
  const _LockOverlay({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.sp),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: k.card.withValues(alpha: 0.72),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 20.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('See your whole journey', style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
              SizedBox(height: 4.sp),
              Text(
                '3 months, all time and dose markers with Kindose Plus.',
                textAlign: TextAlign.center,
                style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: k.muted),
              ),
              SizedBox(height: 10.sp),
              PressScale(
                semanticLabel: 'Try Plus free',
                onTap: onTap,
                child: Container(
                  height: 38.sp,
                  padding: EdgeInsets.symmetric(horizontal: 16.sp),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(19.sp)),
                  child: Text('Try Plus free', style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: AppColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DosesCard extends StatelessWidget {
  const _DosesCard({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final areas = controller.siteAreas;
    final maxN = areas.fold<int>(1, (m, a) => a.$2 > m ? a.$2 : m);
    Widget stat(String value, String sub, {bool lime = false}) => Expanded(
          child: Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: lime && !dark ? AppColors.limeSoft : k.bg,
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: AppText.h3.copyWith(fontSize: 22.sp, color: k.text)),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(fontSize: 12.sp, color: lime && !dark ? AppColors.limeText : k.muted),
                ),
              ],
            ),
          ),
        );
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DOSES', style: _caps(context)),
          SizedBox(height: 10.sp),
          Row(
            children: [
              stat(controller.onTimeValue, controller.onTimeSub, lime: true),
              SizedBox(width: 8.sp),
              stat(controller.currentDose, controller.currentDoseSince),
              SizedBox(width: 8.sp),
              stat(controller.nextDoseValue, 'next dose'),
            ],
          ),
          if (controller.showSites) ...[
            SizedBox(height: 14.sp),
            Text('Spots used · ${controller.rangeWord}', style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: k.textSoft)),
            SizedBox(height: 8.sp),
            for (final (label, n) in areas)
              Padding(
                padding: EdgeInsets.only(bottom: 7.sp),
                child: Semantics(
                  label: '$label: $n',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      SizedBox(width: 56.sp, child: Text(label, style: AppText.small.copyWith(fontSize: 12.5.sp, color: k.muted))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5.sp),
                          child: SizedBox(
                            height: 10.sp,
                            child: Stack(
                              children: [
                                Positioned.fill(child: ColoredBox(color: k.bg)),
                                FractionallySizedBox(
                                  widthFactor: n / maxN,
                                  heightFactor: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: k.text, borderRadius: BorderRadius.circular(5.sp)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.sp),
                      SizedBox(
                        width: 18.sp,
                        child: Text('$n', textAlign: TextAlign.right, style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: k.text)),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 4.sp),
            Text(controller.sitesNote, style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: k.muted)),
          ],
        ],
      ),
    );
  }
}

class _BarsCard extends StatelessWidget {
  const _BarsCard({
    required this.title,
    required this.goalLabel,
    required this.headline,
    required this.bars,
    required this.color,
    required this.valueLabel,
  });

  final String title;
  final String goalLabel;
  final String headline;
  final List<DayBar> bars;
  final Color color;
  final String Function(double) valueLabel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final goal = bars.isEmpty ? 1.0 : bars.first.goal;
    final maxV = [goal * 1.2, ...bars.map((b) => b.value)].reduce((a, b) => a > b ? a : b);
    final chartH = 96.sp;
    final today = Dates.dateOnly(DateTime.now());
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title.toUpperCase(), style: _caps(context))),
              Text(goalLabel, style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint)),
            ],
          ),
          SizedBox(height: 6.sp),
          Text(headline, style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
          SizedBox(height: 12.sp),
          Semantics(
            label: [for (final b in bars) '${Dates.weekdayName(b.date.weekday)} ${valueLabel(b.value)}'].join(', '),
            excludeSemantics: true,
            child: SizedBox(
              height: chartH + 18.sp,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: chartH - chartH * goal / maxV,
                    child: CustomPaint(size: Size(double.infinity, 2), painter: _DashPainter(k.faint)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, b) in bars.indexed) ...[
                        if (i > 0) SizedBox(width: 6.sp),
                        Expanded(
                          child: Tooltip(
                            message: '${Dates.weekdayShort(b.date.weekday)}: ${valueLabel(b.value)}',
                            triggerMode: TooltipTriggerMode.tap,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: (b.value / maxV).clamp(0.0, 1.0)),
                                  duration: Duration(milliseconds: 450 + i * 40),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, _) => Container(
                                    height: chartH * v,
                                    decoration: BoxDecoration(
                                      color: b.hit ? color : color.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(6.sp), bottom: Radius.circular(3.sp)),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4.sp),
                                Text(
                                  Dates.sameDay(b.date, today) ? 'Tdy' : Dates.weekdayShort(b.date.weekday).substring(0, 1),
                                  style: AppText.tiny.copyWith(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Dates.sameDay(b.date, today) ? k.text : k.faint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5 > size.width ? size.width : x + 5, 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _FeelCard extends StatelessWidget {
  const _FeelCard({required this.controller});

  final ProgressController controller;

  /// Fine → severe, one warm hue light to dark.
  static const List<Color> _heat = [Color(0xFFFFF4EC), Color(0xFFF7B895), Color(0xFFE3713D), Color(0xFF9A3F17)];

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final cells = controller.feelCells;
    final pattern = controller.patternLine;
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW YOU FELT · 4 WEEKS', style: _caps(context)),
          SizedBox(height: 6.sp),
          Text(controller.feelHeadline, style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
          SizedBox(height: 12.sp),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final (i, n) in names.indexed) ...[
                  if (i > 0) SizedBox(width: 5.sp),
                  Expanded(child: Text(n, textAlign: TextAlign.center, style: AppText.tiny.copyWith(fontSize: 11.sp, color: k.faint))),
                ],
              ],
            ),
          ),
          SizedBox(height: 5.sp),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5.sp,
            crossAxisSpacing: 5.sp,
            children: [
              for (final c in cells)
                Semantics(
                  label: c.inFuture
                      ? ''
                      : '${Dates.shortWithDay(c.date)}: ${c.level < 0 ? 'no check-in' : ['fine', 'mild', 'moderate', 'severe'][c.level]}${c.doseDay ? ', dose day' : ''}',
                  excludeSemantics: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.inFuture || c.level < 0 ? Colors.transparent : _heat[c.level],
                      borderRadius: BorderRadius.circular(9.sp),
                      border: c.inFuture
                          ? null
                          : c.level < 0
                              ? Border.all(color: k.border, width: 1.5)
                              : (c.level == 0 ? Border.all(color: const Color(0xFFF3DCCD)) : null),
                    ),
                    alignment: Alignment.center,
                    child: c.doseDay
                        ? Container(
                            width: 7.sp,
                            height: 7.sp,
                            decoration: BoxDecoration(color: c.level >= 2 ? AppColors.white : AppColors.ink, shape: BoxShape.circle),
                          )
                        : null,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.sp),
          ExcludeSemantics(
            child: Wrap(
              spacing: 10.sp,
              runSpacing: 6.sp,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _legend(context, 'No check-in', border: k.border),
                for (final (i, l) in ['Fine', 'Mild', 'Moderate', 'Severe'].indexed) _legend(context, l, fill: _heat[i]),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7.sp, height: 7.sp, decoration: BoxDecoration(color: k.text, shape: BoxShape.circle)),
                    SizedBox(width: 4.sp),
                    Text('Dose', style: AppText.tiny.copyWith(fontSize: 11.5.sp, color: k.muted)),
                  ],
                ),
              ],
            ),
          ),
          if (!controller.isDaily) ...[
            SizedBox(height: 14.sp),
            PressScale(
              semanticLabel: controller.isPlus
                  ? 'Your pattern: ${pattern ?? 'not enough check-ins yet'}'
                  : 'Your pattern, a Kindose Plus feature. Opens Plus',
              onTap: controller.isPlus ? () {} : controller.openPlus,
              child: ExcludeSemantics(
                child: Container(
                  padding: EdgeInsets.all(14.sp),
                  decoration: BoxDecoration(
                    color: AppColors.hero,
                    borderRadius: BorderRadius.circular(18.sp),
                    border: k.selectedBorder == AppColors.lime ? Border.all(color: k.border) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('YOUR PATTERN', style: AppText.caps.copyWith(fontSize: 12.sp, letterSpacing: 1, color: AppColors.lime)),
                                SizedBox(width: 8.sp),
                                const PlusTag(onDark: true),
                              ],
                            ),
                            SizedBox(height: 4.sp),
                            Text(
                              controller.isPlus
                                  ? (pattern ?? 'Check in on 3 dose weeks to see which day is hardest for you.')
                                  : 'See which day after your dose is hardest for you.',
                              style: AppText.small.copyWith(fontSize: 13.5.sp, color: AppColors.white),
                            ),
                          ],
                        ),
                      ),
                      if (!controller.isPlus) Icon(PhosphorIconsBold.caretRight, size: 18.sp, color: AppColors.lime),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, {Color? fill, Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.sp,
          height: 12.sp,
          decoration: BoxDecoration(
            color: fill ?? Colors.transparent,
            borderRadius: BorderRadius.circular(4.sp),
            border: border == null ? null : Border.all(color: border, width: 1.5),
          ),
        ),
        SizedBox(width: 4.sp),
        Text(label, style: AppText.tiny.copyWith(fontSize: 11.5.sp, color: context.k.muted)),
      ],
    );
  }
}

class _ReportNudge extends StatelessWidget {
  const _ReportNudge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return PressScale(
      semanticLabel: 'Seeing your doctor soon? Open your doctor report',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(color: dark ? k.card : AppColors.limeSoft, borderRadius: BorderRadius.circular(22.sp)),
          child: Row(
            children: [
              ThreeD(Img3d.clipboard, size: 40.sp),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seeing your doctor soon?', style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
                    Text(
                      'All of this fits on one page for them.',
                      style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: dark ? k.muted : AppColors.limeText),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsBold.caretRight, size: 18.sp, color: k.text),
            ],
          ),
        ),
      ),
    );
  }
}
