import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../resources/water_units.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/weight_chart.dart';
import '../home/home_screen.dart';
import 'progress_controller.dart';
import 'widgets/feel_heatmap.dart';

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
              Text(
                'WEEK $week OF TREATMENT',
                style: _caps(context),
              ).enter(motion),
            SizedBox(height: 4.sp),
            Semantics(
              header: true,
              child: Text(
                'Progress',
                style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text),
              ),
            ).enter(motion),
            SizedBox(height: 16.sp),
            _RangeSwitch(controller: controller).enter(motion, delay: 40),
            SizedBox(height: 14.sp),
            _WeightCard(controller: controller).enter(motion, delay: 60),
            SizedBox(height: 12.sp),
            _WeighInsLink(controller: controller).enter(motion, delay: 80),
            SizedBox(height: 12.sp),
            if (controller.hasDoses) ...[
              // Locked ranges (3 months / all time) cover the doses card
              // too, not only the chart.
              Stack(
                children: [
                  _DosesCard(controller: controller),
                  if (controller.locked)
                    Positioned.fill(
                      child: _LockOverlay(onTap: controller.openPlus),
                    ),
                ],
              ).enter(motion, delay: 100),
              SizedBox(height: 12.sp),
            ],
            _BarsCard(
              title: 'Protein · last 7 days',
              goalLabel: 'Goal ${controller.profile?.proteinGoalG ?? 100} g',
              headline: controller.barsHeadline(
                controller.proteinBars,
                water: false,
              ),
              bars: controller.proteinBars,
              onDayTap: (d) => controller.openIntake('protein', d),
              color: AppColors.tangerine,
              valueLabel: (v) => '${v.round()} g',
              shortLabel: (v) => '${v.round()}',
            ).enter(motion, delay: 140),
            SizedBox(height: 12.sp),
            _BarsCard(
              title: 'Water · last 7 days',
              goalLabel:
                  'Goal ${Water.totalWithUnit(controller.profile?.waterGoalMl ?? 2500)}',
              headline: controller.barsHeadline(
                controller.waterBars,
                water: true,
              ),
              bars: controller.waterBars,
              onDayTap: (d) => controller.openIntake('water', d),
              color: AppColors.aqua,
              valueLabel: (v) => Water.totalWithUnit(v.round()),
              shortLabel: (v) => Water.total(v.round()),
            ).enter(motion, delay: 170),
            SizedBox(height: 12.sp),
            _FeelCard(controller: controller).enter(motion, delay: 200),
            SizedBox(height: 12.sp),
            _ReportNudge(onTap: controller.openReport)
                .enter(motion, delay: 230),
          ],
        );
      }),
    );
  }

  int? _treatmentWeek() {
    final t = controller.tracker;
    final start =
        controller.profile?.treatmentStartedAt ??
        (t.doses.isEmpty ? null : t.doses.last.takenAt);
    if (start == null || start.isAfter(DateTime.now())) return null;
    return Dates.daysBetween(start, DateTime.now()) ~/ 7 + 1;
  }
}

TextStyle _caps(BuildContext c) => AppText.caps.copyWith(
  fontSize: 12.sp,
  letterSpacing: 1.1,
  color: c.k.faint,
);

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: context.k.card,
        borderRadius: BorderRadius.circular(24.sp),
      ),
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
      decoration: BoxDecoration(
        color: k.cardAlt,
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Row(
        children: [
          for (final r in ProgressRange.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: controller.range.value == r,
                inMutuallyExclusiveGroup: true,
                label:
                    '${_labels[r]}${r != ProgressRange.month && !plus ? ', Plus' : ''}',
                excludeSemantics: true,
                child: PressScale(
                  pressedScale: 0.95,
                  onTap: () => controller.pickRange(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 38.sp,
                    decoration: BoxDecoration(
                      color: controller.range.value == r
                          ? k.card
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.sp),
                      boxShadow: controller.range.value == r
                          ? [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.08),
                                blurRadius: 6.sp,
                                offset: Offset(0, 2.sp),
                              ),
                            ]
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
                            color: controller.range.value == r
                                ? k.text
                                : k.muted,
                          ),
                        ),
                        if (r != ProgressRange.month && !plus) ...[
                          SizedBox(width: 4.sp),
                          Icon(
                            PhosphorIconsFill.lockSimple,
                            size: 12.sp,
                            color: k.text,
                          ),
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
    final chips = [
      controller.bmiLabel,
      controller.toGoalLabel,
    ].whereType<String>().toList();
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
                  label: controller.noChange
                      ? 'Weight since you started: no change yet. ${controller.changeLine}'
                      : controller.hasWeights
                      ? 'Weight since you started: ${controller.changeNumber} ${controller.unit}. ${controller.changeLine}'
                      : 'No weigh-ins yet',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WEIGHT · SINCE YOU STARTED', style: _caps(context)),
                      SizedBox(height: 6.sp),
                      if (controller.noChange)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.sp),
                          child: Text(
                            'No change yet',
                            style: AppText.h2.copyWith(
                              fontSize: 26.sp,
                              color: k.text,
                            ),
                          ),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              controller.changeNumber,
                              style: AppText.number(40.sp)
                                  .copyWith(color: k.text),
                            ),
                            SizedBox(width: 6.sp),
                            Text(
                              controller.unit,
                              style: AppText.title.copyWith(
                                fontSize: 16.sp,
                                color: k.muted,
                              ),
                            ),
                          ],
                        ),
                      if (controller.changeLine.isNotEmpty) ...[
                        SizedBox(height: 4.sp),
                        Text(
                          controller.changeLine,
                          style: AppText.small.copyWith(
                            fontSize: 13.sp,
                            color: k.muted,
                          ),
                        ),
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
                  child: Text(
                    '+ Log',
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: k.text,
                    ),
                  ),
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
                  markers: [
                    for (final m in controller.doseMarkers) (m.date, m.label),
                  ],
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
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: k.muted,
                    ),
                  ),
                ),
              if (controller.locked)
                Positioned.fill(
                  child: _LockOverlay(onTap: controller.openPlus),
                ),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.sp,
                      vertical: 5.sp,
                    ),
                    decoration: BoxDecoration(
                      color: k.bg,
                      borderRadius: BorderRadius.circular(10.sp),
                    ),
                    child: Text(
                      c,
                      style: AppText.small.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: k.textSoft,
                      ),
                    ),
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
              Text(
                'See your whole journey',
                style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
              ),
              SizedBox(height: 4.sp),
              Text(
                '3 months, all time and dose markers with Kindose Plus.',
                textAlign: TextAlign.center,
                style: AppText.small.copyWith(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: k.muted,
                ),
              ),
              SizedBox(height: 10.sp),
              PressScale(
                semanticLabel: 'See Plus',
                onTap: onTap,
                child: Container(
                  height: 38.sp,
                  padding: EdgeInsets.symmetric(horizontal: 16.sp),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(19.sp),
                  ),
                  child: Text(
                    'See Plus',
                    style: AppText.small.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lime,
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
              child: Text(
                value,
                style: AppText.h3.copyWith(fontSize: 22.sp, color: k.text),
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.small.copyWith(
                fontSize: 12.sp,
                color: lime && !dark ? AppColors.limeText : k.muted,
              ),
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
              stat(
                controller.onTimeValue,
                controller.onTimeSub,
                lime: controller.onTimeGood,
              ),
              SizedBox(width: 8.sp),
              stat(controller.currentDose, controller.currentDoseSince),
              SizedBox(width: 8.sp),
              stat(controller.nextDoseValue, 'next dose'),
            ],
          ),
          if (controller.showSites) ...[
            SizedBox(height: 14.sp),
            Text(
              'Spots used · ${controller.rangeWord}',
              style: AppText.small.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: k.textSoft,
              ),
            ),
            SizedBox(height: 8.sp),
            for (final (label, n) in areas)
              Padding(
                padding: EdgeInsets.only(bottom: 7.sp),
                child: Semantics(
                  label: '$label: $n',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56.sp,
                        child: Text(
                          label,
                          style: AppText.small.copyWith(
                            fontSize: 12.5.sp,
                            color: k.muted,
                          ),
                        ),
                      ),
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
                                    decoration: BoxDecoration(
                                      color: k.text,
                                      borderRadius: BorderRadius.circular(5.sp),
                                    ),
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
                        child: Text(
                          '$n',
                          textAlign: TextAlign.right,
                          style: AppText.small.copyWith(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 4.sp),
            Text(
              controller.sitesNote,
              style: AppText.small.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: k.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One row under the weight chart: opens the Weigh-ins screen (every
/// entry, edit, delete, add a past one).
class _WeighInsLink extends StatelessWidget {
  const _WeighInsLink({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      label: 'Weigh-ins, ${controller.weighInsSummary}',
      excludeSemantics: true,
      child: PressScale(
        pressedScale: 0.98,
        onTap: controller.openWeighIns,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 14.sp, 14.sp),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(20.sp),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weigh-ins',
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: k.text,
                      ),
                    ),
                    Text(
                      controller.weighInsSummary,
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: k.muted,
                      ),
                    ),
                  ],
                ),
              ),
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 16.sp,
                color: k.faint,
              ),
            ],
          ),
        ),
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
    required this.onDayTap,
    required this.color,
    required this.valueLabel,
    required this.shortLabel,
  });

  /// Tapping a bar opens that day's Protein or Water screen.
  final void Function(DateTime day) onDayTap;
  final String title;
  final String goalLabel;
  final String headline;
  final List<DayBar> bars;
  final Color color;
  final String Function(double) valueLabel;

  /// The amount printed over each bar, without its unit (the goal names it).
  final String Function(double) shortLabel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final goal = bars.isEmpty ? 1.0 : bars.first.goal;
    // A full slot is the goal: hitting it fills the bar, and days over it
    // stay full (the label above shows the real amount).
    final maxV = goal <= 0 ? 1.0 : goal;
    final chartH = 96.sp;
    final barW = 22.sp;
    // Space for the amount over a bar.
    final labelH = 18.sp;
    final today = Dates.dateOnly(DateTime.now());
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title.toUpperCase(), style: _caps(context))),
              Text(
                goalLabel,
                style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint),
              ),
            ],
          ),
          SizedBox(height: 6.sp),
          Text(
            headline,
            style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
          ),
          SizedBox(height: 12.sp),
          SizedBox(
            height: labelH + chartH + 24.sp,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, b) in bars.indexed) ...[
                  if (i > 0) SizedBox(width: 4.sp),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          '${Dates.weekdayName(b.date.weekday)} ${valueLabel(b.value)}'
                          '${b.hit ? ', goal reached' : ''}. Opens that day',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onDayTap(b.date),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // The day's amount, so no tap is needed to
                            // read it. Goal days are bold in the colour.
                            SizedBox(
                              height: labelH,
                              child: b.value <= 0
                                  ? null
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shortLabel(b.value),
                                        style: AppText.tiny.copyWith(
                                          fontSize: 11.sp,
                                          fontWeight: b.hit
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: b.hit ? color : k.muted,
                                        ),
                                      ),
                                    ),
                            ),
                            // Every day has a slot, so empty days read
                            // as "nothing logged", not as a gap.
                            Container(
                              width: barW,
                              height: chartH,
                              alignment: Alignment.bottomCenter,
                              decoration: BoxDecoration(
                                // Quiet, so the filled days lead.
                                color: k.border.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(barW / 2),
                              ),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: (b.value / maxV).clamp(0.0, 1.0),
                                ),
                                duration: Duration(milliseconds: 450 + i * 40),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, _) => v <= 0
                                    ? const SizedBox.shrink()
                                    : Container(
                                        // A little still shows as a
                                        // round dot, not a sliver.
                                        height: (chartH * v).clamp(
                                          barW,
                                          chartH,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(
                                            alpha: b.hit ? 1.0 : 0.62,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            barW / 2,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 4.sp),
                            SizedBox(
                              height: 20.sp,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  Dates.sameDay(b.date, today)
                                      ? 'Today'
                                      : Dates.weekdayShort(b.date.weekday)
                                            .substring(0, 1),
                                  style: AppText.tiny.copyWith(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Dates.sameDay(b.date, today)
                                        ? k.text
                                        : k.faint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How-you-felt style. true: recent check-ins as mood faces plus what came
/// up, with the month calendar behind "Full month". false: the original
/// month calendar only.
const bool _feelFaces = true;

/// The heatmap card (filter chips, Grid / Trend, day details). Takes
/// precedence over [_feelFaces]; false falls back to the styles above.
const bool _feelHeatmap = true;

class _FeelCard extends StatefulWidget {
  const _FeelCard({required this.controller});

  final ProgressController controller;

  @override
  State<_FeelCard> createState() => _FeelCardState();
}

/// Tap a day to open its check-in.
/// ‹ › step through earlier 4-week periods.
class _FeelCardState extends State<_FeelCard> {
  ProgressController get controller => widget.controller;

  /// The month calendar opened from "Full month" (faces view only).
  bool _month = false;

  /// Fine → severe, one warm hue light to dark. "Fine" is tinted enough to
  /// stand apart from an empty day.
  static const List<Color> _heat = [
    Color(0xFFFCE4D6),
    Color(0xFFF7B895),
    Color(0xFFE3713D),
    Color(0xFF9A3F17),
  ];

  void _tap(FeelCell c) {
    if (c.inFuture) return;
    controller.openCheckIn(c.date);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final cells = controller.feelCells;
    final pattern = controller.patternLine;
    final today = Dates.dateOnly(DateTime.now());
    final locked = controller.feelLocked;
    if (_feelHeatmap && !locked) {
      return _Card(
        child: FeelHeatmap(
          controller: controller,
          heat: _heat,
          patternCard: controller.isDaily
              ? null
              : _patternCard(context, pattern),
        ),
      );
    }
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HOW YOU FELT · ${controller.feelRange.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _caps(context),
                ),
              ),
              _arrow(
                context,
                PhosphorIconsBold.caretLeft,
                'Earlier weeks',
                controller.canFeelBack ? controller.feelBack : null,
              ),
              SizedBox(width: 6.sp),
              _arrow(
                context,
                PhosphorIconsBold.caretRight,
                'Later weeks',
                controller.feelPage.value > 0 ? controller.feelForward : null,
              ),
            ],
          ),
          SizedBox(height: 6.sp),
          Text(
            locked
                ? 'Earlier months are part of Plus.'
                : controller.feelHeadline,
            style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
          ),
          SizedBox(height: 12.sp),
          if (locked)
            PillButton(label: 'See Plus', onPressed: controller.openPlus)
          else ...[
            if (_feelFaces && !_month) ...[
              _faces(context, cells, today),
              _effects(context),
              SizedBox(height: 10.sp),
              _monthLink(context, 'Full month'),
            ] else ...[
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final (i, n) in names.indexed) ...[
                    if (i > 0) SizedBox(width: 5.sp),
                    Expanded(
                      child: Text(
                        n,
                        textAlign: TextAlign.center,
                        style: AppText.tiny.copyWith(
                          fontSize: 11.sp,
                          color: k.faint,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 5.sp),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 5.sp,
              crossAxisSpacing: 5.sp,
              children: [for (final c in cells) _cell(context, c, today)],
            ),
            SizedBox(height: 12.sp),
            // One line: the scale, then the dose mark.
            ExcludeSemantics(
              child: Row(
                children: [
                  _legendText(context, 'Fine'),
                  SizedBox(width: 6.sp),
                  for (final c in _heat) ...[
                    Container(
                      width: 14.sp,
                      height: 10.sp,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(3.sp),
                      ),
                    ),
                    SizedBox(width: 3.sp),
                  ],
                  SizedBox(width: 3.sp),
                  _legendText(context, 'Severe'),
                  const Spacer(),
                  if (!controller.isDaily) ...[
                    Container(
                      width: 6.sp,
                      height: 6.sp,
                      decoration: BoxDecoration(
                        color: k.text,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.sp),
                    _legendText(context, 'dose day'),
                  ],
                ],
              ),
            ),
          
              if (_feelFaces) ...[
                SizedBox(height: 10.sp),
                _monthLink(context, 'Show less'),
              ],
            ],
          ],
          if (controller.feelPage.value == 0 && !controller.checkedInToday) ...[
            SizedBox(height: 14.sp),
            PillButton(
              label: 'Check in today',
              onPressed: controller.openCheckIn,
            ),
          ],
          if (!controller.isDaily) ...[
            SizedBox(height: 14.sp),
            _patternCard(context, pattern),
          ],
        ],
      ),
    );
  }

  Widget _patternCard(BuildContext context, String? pattern) {
    final k = context.k;
    return PressScale(
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
            border: k.selectedBorder == AppColors.lime
                ? Border.all(color: k.border)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'YOUR PATTERN',
                          style: AppText.caps.copyWith(
                            fontSize: 12.sp,
                            letterSpacing: 1,
                            color: AppColors.lime,
                          ),
                        ),
                        // The badge sells Plus, so only without it.
                        if (!controller.isPlus) ...[
                          SizedBox(width: 8.sp),
                          const PlusTag(onDark: true),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      controller.isPlus
                          ? (pattern ??
                                'Check in on 3 dose weeks to see which day is hardest for you.')
                          : 'See which day after your dose is hardest for you.',
                      style: AppText.small.copyWith(
                        fontSize: 13.5.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (!controller.isPlus)
                Icon(
                  PhosphorIconsBold.caretRight,
                  size: 18.sp,
                  color: AppColors.lime,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A cell with its date: check-ins take their level's colour, other days
  /// are the date alone, today has a ring, and days still to come are
  /// blank. The 1st names its month.
  Widget _cell(BuildContext context, FeelCell c, DateTime today) {
    final k = context.k;
    final isToday = Dates.sameDay(c.date, today);
    final filled = !c.inFuture && c.level >= 0;
    final onDark = filled && c.level >= 2;
    return Semantics(
      button: !c.inFuture,
      label: c.inFuture
          ? ''
          : '${Dates.shortWithDay(c.date)}: ${c.level < 0 ? 'no check-in' : ['fine', 'mild', 'moderate', 'severe'][c.level]}${c.doseDay ? ', dose day' : ''}. Opens the check-in',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(c),
        child: Container(
          decoration: BoxDecoration(
            // Only check-ins get a colour; other days are just their date,
            // and days still to come are left blank.
            color: filled ? _heat[c.level] : Colors.transparent,
            borderRadius: BorderRadius.circular(9.sp),
            border: isToday ? Border.all(color: k.text, width: 2) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!c.inFuture)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.sp),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      c.date.day == 1
                          ? '1 ${Dates.monthShort(c.date.month)}'
                          : '${c.date.day}',
                      style: AppText.tiny.copyWith(
                        fontSize: 11.sp,
                        fontWeight: isToday || c.date.day == 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        // Dates read on every shade: white on the dark
                        // ones, deep tangerine on the light ones.
                        color: onDark
                            ? AppColors.white
                            : (filled
                                  ? AppColors.tangerineText
                                  : (isToday ? k.text : k.faint)),
                      ),
                    ),
                  ),
                ),
              if (c.doseDay)
                Positioned(
                  bottom: 4.sp,
                  child: Container(
                    width: 5.sp,
                    height: 5.sp,
                    decoration: BoxDecoration(
                      color: onDark ? AppColors.white : k.text,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) => CircleIconButton(
    icon: icon,
    label: label,
    size: 30.sp,
    background: context.k.text.withValues(alpha: 0.06),
    onTap: onTap,
  );

  /// The latest check-ins as mood faces, oldest on the left; a "…" where
  /// days were skipped, and today as an empty ring until checked in.
  Widget _faces(BuildContext context, List<FeelCell> cells, DateTime today) {
    final k = context.k;
    final todayCell = cells.firstWhereOrNull(
      (c) => Dates.sameDay(c.date, today),
    );
    final checked = [
      for (final c in cells)
        if (!c.inFuture && c.level >= 0) c,
    ];
    if (checked.isEmpty && todayCell == null) return const SizedBox.shrink();
    // Newest first, then flipped: null is a gap.
    final items = <FeelCell?>[];
    DateTime? prev;
    if (todayCell != null && todayCell.level < 0) {
      items.add(todayCell);
      prev = today;
    }
    for (final c in checked.reversed) {
      if (items.length >= 7) break;
      if (prev != null && Dates.daysBetween(c.date, prev) > 1) {
        if (items.length >= 6) break;
        items.add(null);
      }
      items.add(c);
      prev = c.date;
    }
    final row = items.reversed.toList();
    final size = 36.sp;
    Widget face(FeelCell c) {
      final isToday = Dates.sameDay(c.date, today);
      final empty = c.level < 0;
      return Semantics(
        button: true,
        label: empty
            ? 'Today: no check-in. Opens the check-in'
            : '${Dates.shortWithDay(c.date)}: '
                  '${Catalog.moods[controller.feelMood(c)].label}. Opens the check-in',
        excludeSemantics: true,
        child: PressScale(
          onTap: () => controller.openCheckIn(c.date),
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: empty ? Colors.transparent : _heat[c.level],
                  border: isToday
                      ? Border.all(color: k.text, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: empty
                    ? Icon(PhosphorIconsBold.plus, size: 16.sp, color: k.text)
                    : ThreeD(
                        Catalog.moods[controller.feelMood(c)].icon,
                        size: 23.sp,
                      ),
              ),
              SizedBox(height: 4.sp),
              Text(
                isToday ? 'Today' : '${c.date.day}',
                style: AppText.tiny.copyWith(
                  fontSize: 11.sp,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: isToday ? k.text : k.faint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: i >= row.length
                  ? const SizedBox.shrink()
                  : (row[i] == null
                        ? SizedBox(
                            height: size,
                            child: Center(
                              child: Text(
                                '…',
                                style: AppText.title.copyWith(
                                  fontSize: 16.sp,
                                  color: k.faint,
                                ),
                              ),
                            ),
                          )
                        : face(row[i]!)),
            ),
          ),
      ],
    );
  }

  /// "What came up": the side effects of these weeks, by days, each bar
  /// in the colour of its worst day.
  Widget _effects(BuildContext context) {
    final k = context.k;
    final list = controller.feelEffects();
    if (list.isEmpty) return const SizedBox.shrink();
    final most = list.first.$2;
    return Padding(
      padding: EdgeInsets.only(top: 14.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: k.border.withValues(alpha: 0.6)),
          SizedBox(height: 12.sp),
          Text('WHAT CAME UP', style: _caps(context)),
          SizedBox(height: 8.sp),
          for (final (id, days, worst) in list)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.sp),
              child: Semantics(
                label:
                    '${Catalog.symptomLabel(id)}, $days ${days == 1 ? 'day' : 'days'}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    SizedBox(
                      width: 92.sp,
                      child: Text(
                        Catalog.symptomLabel(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong.copyWith(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: k.text,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.sp),
                        child: SizedBox(
                          height: 8.sp,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(
                                  color: k.border.withValues(alpha: 0.55),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: days / most,
                                heightFactor: 1,
                                child: ColoredBox(
                                  color: _heat[worst.clamp(1, 3)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56.sp,
                      child: Text(
                        '$days ${days == 1 ? 'day' : 'days'}',
                        textAlign: TextAlign.right,
                        style: AppText.small.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: k.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _monthLink(BuildContext context, String label) => PressScale(
    semanticLabel: label == 'Full month'
        ? 'Show the full month'
        : 'Hide the full month',
    onTap: () => setState(() => _month = !_month),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Text(
        label == 'Full month' ? 'Full month ›' : 'Show less',
        style: AppText.title.copyWith(
          fontSize: 13.sp,
          color: context.k.muted,
        ),
      ),
    ),
  );

  Widget _legendText(BuildContext context, String text) => Text(
    text,
    style: AppText.tiny.copyWith(fontSize: 11.5.sp, color: context.k.muted),
  );
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
          decoration: BoxDecoration(
            color: dark ? k.card : AppColors.limeSoft,
            borderRadius: BorderRadius.circular(22.sp),
          ),
          child: Row(
            children: [
              ThreeD(Img3d.clipboard, size: 40.sp),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seeing your doctor soon?',
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: k.text,
                      ),
                    ),
                    Text(
                      'All of this fits on one page for them.',
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: dark ? k.muted : AppColors.limeText,
                      ),
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
