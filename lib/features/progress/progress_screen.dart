import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../resources/water_units.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
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
              onDayTap: controller.openDay,
              color: AppColors.tangerine,
              valueLabel: (v) => '${v.round()} g',
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
              onDayTap: controller.openDay,
              color: AppColors.aqua,
              valueLabel: (v) => Water.totalWithUnit(v.round()),
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

class _BarsCard extends StatefulWidget {
  const _BarsCard({
    required this.title,
    required this.goalLabel,
    required this.headline,
    required this.bars,
    required this.onDayTap,
    required this.color,
    required this.valueLabel,
  });

  /// "Open day" on a selected bar opens that day's view.
  final void Function(DateTime day) onDayTap;
  final String title;
  final String goalLabel;
  final String headline;
  final List<DayBar> bars;
  final Color color;
  final String Function(double) valueLabel;

  @override
  State<_BarsCard> createState() => _BarsCardState();
}

/// Tapping a bar selects it and shows that day's amount in place of the
/// headline; tapping it again clears it.
class _BarsCardState extends State<_BarsCard> {
  int? _sel;

  void _tap(int i) {
    Haptics.instance.selectionClick();
    setState(() => _sel = _sel == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final bars = widget.bars;
    final color = widget.color;
    final valueLabel = widget.valueLabel;
    final sel = _sel != null && _sel! < bars.length ? bars[_sel!] : null;
    final goal = bars.isEmpty ? 1.0 : bars.first.goal;
    // A full slot is the goal: hitting it fills the bar, and days over it
    // stay full (the tick marks them; tapping shows the real amount).
    final maxV = goal <= 0 ? 1.0 : goal;
    final chartH = 96.sp;
    final barW = 22.sp;
    // Space for the goal tick over a bar.
    final tickH = 16.sp;
    final today = Dates.dateOnly(DateTime.now());
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title.toUpperCase(), style: _caps(context)),
              ),
              Text(
                widget.goalLabel,
                style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint),
              ),
            ],
          ),
          SizedBox(height: 6.sp),
          if (sel == null)
            Text(
              widget.headline,
              style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${Dates.sameDay(sel.date, today) ? 'Today' : Dates.weekdayName(sel.date.weekday)}'
                    ' · ${valueLabel(sel.value)}${sel.hit ? ' · goal reached' : ''}',
                    style: AppText.title.copyWith(
                      fontSize: 15.sp,
                      color: k.text,
                    ),
                  ),
                ),
                SizedBox(width: 10.sp),
                PressScale(
                  semanticLabel: 'Open this day',
                  onTap: () => widget.onDayTap(sel.date),
                  child: Text(
                    'Open day ›',
                    style: AppText.title.copyWith(
                      fontSize: 13.sp,
                      color: k.muted,
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 12.sp),
          Semantics(
            label: [
              for (final b in bars)
                '${Dates.weekdayName(b.date.weekday)} ${valueLabel(b.value)}',
            ].join(', '),
            hint: 'Tap a day to see its amount',
            excludeSemantics: true,
            child: SizedBox(
              height: tickH + chartH + 24.sp,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, b) in bars.indexed) ...[
                    if (i > 0) SizedBox(width: 4.sp),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _tap(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // A tick over days that reached the goal.
                            SizedBox(
                              height: tickH,
                              child: b.hit
                                  ? Icon(
                                      PhosphorIconsBold.check,
                                      size: 12.sp,
                                      color: color.withValues(
                                        alpha: _sel == null || _sel == i
                                            ? 1.0
                                            : 0.35,
                                      ),
                                    )
                                  : null,
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
                                          // A selected bar keeps its
                                          // colour; the others fade back.
                                          color: color.withValues(
                                            alpha:
                                                (b.hit ? 1.0 : 0.62) *
                                                (_sel == null || _sel == i
                                                    ? 1.0
                                                    : 0.35),
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeelCard extends StatefulWidget {
  const _FeelCard({required this.controller});

  final ProgressController controller;

  @override
  State<_FeelCard> createState() => _FeelCardState();
}

/// Tap a day to see it in place of the headline; tap it again to clear.
/// ‹ › step through earlier 4-week periods.
class _FeelCardState extends State<_FeelCard> {
  DateTime? _sel;

  ProgressController get controller => widget.controller;

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
    Haptics.instance.selectionClick();
    setState(
      () => _sel = _sel != null && Dates.sameDay(_sel!, c.date) ? null : c.date,
    );
  }

  void _page(VoidCallback go) {
    setState(() => _sel = null);
    go();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final cells = controller.feelCells;
    final pattern = controller.patternLine;
    final today = Dates.dateOnly(DateTime.now());
    final locked = controller.feelLocked;
    final sel = _sel == null
        ? null
        : cells.firstWhereOrNull((c) => Dates.sameDay(c.date, _sel!));
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
                controller.canFeelBack
                    ? () => _page(controller.feelBack)
                    : null,
              ),
              SizedBox(width: 6.sp),
              _arrow(
                context,
                PhosphorIconsBold.caretRight,
                'Later weeks',
                controller.feelPage.value > 0
                    ? () => _page(controller.feelForward)
                    : null,
              ),
            ],
          ),
          SizedBox(height: 6.sp),
          if (sel != null)
            _dayLine(context, sel, today)
          else
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

  /// A soft cell with its date: empty days are a quiet tint, check-ins take
  /// their level's colour, today and the picked day have a ring, and days
  /// still to come are an outline only. The 1st names its month.
  Widget _cell(BuildContext context, FeelCell c, DateTime today) {
    final k = context.k;
    final isToday = Dates.sameDay(c.date, today);
    final filled = !c.inFuture && c.level >= 0;
    final onDark = filled && c.level >= 2;
    final picked = _sel != null && Dates.sameDay(_sel!, c.date);
    final faded = _sel != null && !picked;
    return Semantics(
      button: !c.inFuture,
      label: c.inFuture
          ? ''
          : '${Dates.shortWithDay(c.date)}: ${c.level < 0 ? 'no check-in' : ['fine', 'mild', 'moderate', 'severe'][c.level]}${c.doseDay ? ', dose day' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(c),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: faded ? 0.45 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: c.inFuture
                  ? Colors.transparent
                  : (filled
                        ? _heat[c.level]
                        : k.border.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(9.sp),
              border: isToday || picked
                  ? Border.all(color: k.text, width: 2)
                  : (c.inFuture
                        ? Border.all(color: k.border.withValues(alpha: 0.7))
                        : null),
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

  /// "Tue, 13 Oct · Mild · Nausea · dose day" with Open day / Check in.
  Widget _dayLine(BuildContext context, FeelCell c, DateTime today) {
    final k = context.k;
    final log = controller.tracker.dayLog(c.date);
    final isToday = Dates.sameDay(c.date, today);
    final parts = <String>[
      isToday ? 'Today' : Dates.shortWithDay(c.date),
      c.level < 0
          ? 'No check-in'
          : ['Fine', 'Mild', 'Moderate', 'Severe'][c.level],
      for (final s in log.symptoms.take(2)) Catalog.symptomLabel(s),
      if (c.doseDay) 'dose day',
    ];
    final checkIn = isToday && c.level < 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            parts.join(' · '),
            style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
          ),
        ),
        SizedBox(width: 10.sp),
        PressScale(
          semanticLabel: checkIn ? 'Check in today' : 'Open this day',
          onTap: checkIn
              ? controller.openCheckIn
              : () => controller.openDay(c.date),
          child: Text(
            checkIn ? 'Check in ›' : 'Open day ›',
            style: AppText.title.copyWith(fontSize: 13.sp, color: k.muted),
          ),
        ),
      ],
    );
  }

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
