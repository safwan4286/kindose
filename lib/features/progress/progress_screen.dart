import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../home/home_screen.dart';
import '../home/weight_sheet.dart';
import 'progress_controller.dart';

class ProgressScreen extends GetView<ProgressController> {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        // Touch reactive sources used by the getters below.
        controller.tracker.weights.length;
        controller.tracker.doses.length;
        controller.tracker.days.length;
        controller.tracker.profile.value;
        final r = controller.range.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, kNavClearance),
          children: [
            Row(
              children: [
                Expanded(child: Semantics(header: true, child: Text('Progress', style: AppText.h1))),
                SizedBox(
                  width: 170,
                  child: KSegmented<ProgressRange>(
                    options: ProgressRange.values,
                    selected: r,
                    onChanged: (v) => controller.range.value = v,
                    labelOf: (v) => switch (v) {
                      ProgressRange.month => '1M',
                      ProgressRange.quarter => '3M',
                      ProgressRange.all => 'All',
                    },
                    dense: true,
                    darkSelected: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _ChartCard(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Start',
                    value: controller.first == null ? '—' : '${controller.fmt(controller.first!.kg)} ${controller.unit}',
                    sub: controller.first == null ? '' : Dates.short(controller.first!.date),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'To goal', value: controller.toGoalLabel, sub: 'left')),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'Per week', value: controller.perWeekLabel, sub: 'average')),
              ],
            ),
            const SizedBox(height: 12),
            _StripCard(
              icon: Img3d.egg,
              title: 'Protein goal',
              trailing: '${controller.proteinDaysHit} of 7 days',
              bars: controller.proteinBars,
              color: AppColors.tangerine,
              track: k.proteinTrack,
            ),
            const SizedBox(height: 12),
            _StripCard(
              icon: Img3d.nauseated,
              title: 'Nausea',
              trailing: controller.nauseaNote,
              bars: controller.nauseaBars,
              color: AppColors.violet,
              track: k.tint,
            ),
          ],
        );
      }),
    );
  }
}

class _ChartCard extends GetView<ProgressController> {
  const _ChartCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final avg = controller.weeklyAverageKg;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(color: AppColors.hero, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEKLY AVERAGE', style: AppText.caps.copyWith(color: AppColors.heroMuted)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avg == null ? '—' : controller.fmt(avg),
                style: AppText.number(44).copyWith(color: AppColors.white),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(controller.unit, style: AppText.title.copyWith(color: AppColors.heroMuted)),
              ),
              const Spacer(),
              if (controller.changeLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.isDown ? AppColors.lime : const Color(0xFF22213F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.changeLabel,
                    style: AppText.small.copyWith(
                      fontWeight: FontWeight.w800,
                      color: controller.isDown ? AppColors.hero : AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (controller.hasTrend)
            Semantics(
              label: 'Weight chart with ${controller.points.length} weigh-ins',
              excludeSemantics: true,
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeightChartPainter(
                    points: controller.points,
                    doses: controller.doseDates,
                    start: controller.rangeStart,
                    end: DateTime.now(),
                    toShown: controller.shown,
                  ),
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(minHeight: 150),
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF22213F), borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ThreeD(Img3d.chartDown, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Log a weigh-in to start your trend line',
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  SoftButton(
                    label: 'Log weight',
                    height: 36,
                    background: AppColors.lime,
                    foreground: AppColors.hero,
                    onPressed: showWeightSheet,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const _DoseDiamond(),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dose taken',
                  style: AppText.tiny.copyWith(fontSize: 12, color: AppColors.heroMuted),
                ),
              ),
              if (controller.hasTrend)
                TextButton(
                  onPressed: showWeightSheet,
                  style: TextButton.styleFrom(foregroundColor: AppColors.lime, visualDensity: VisualDensity.compact),
                  child: const Text('+ Weigh-in'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoseDiamond extends StatelessWidget {
  const _DoseDiamond();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(width: 9, height: 9, color: AppColors.violet),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({
    required this.points,
    required this.doses,
    required this.start,
    required this.end,
    required this.toShown,
  });

  final List<WeightEntry> points;
  final List<DateTime> doses;
  final DateTime start;
  final DateTime end;
  final double Function(double kg) toShown;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPad = 18.0;
    final chartH = size.height - bottomPad;
    final totalMs = math.max(1, end.difference(start).inMilliseconds);
    double xOf(DateTime d) => (d.difference(start).inMilliseconds / totalMs).clamp(0.0, 1.0) * size.width;

    final values = points.map((p) => toShown(p.kg)).toList();
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if (maxV - minV < 1) {
      minV -= 0.5;
      maxV += 0.5;
    }
    final padV = (maxV - minV) * 0.15;
    minV -= padV;
    maxV += padV;
    double yOf(double v) => chartH - (v - minV) / (maxV - minV) * chartH;

    // Grid lines.
    final grid = Paint()
      ..color = AppColors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartH * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Area + line.
    final path = Path();
    final area = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(xOf(points[i].date), yOf(values[i]));
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
        area.moveTo(o.dx, chartH);
        area.lineTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
        area.lineTo(o.dx, o.dy);
      }
    }
    area
      ..lineTo(xOf(points.last.date), chartH)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lime.withValues(alpha: 0.28), AppColors.lime.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = AppColors.lime;
    final hole = Paint()..color = AppColors.hero;
    for (var i = 0; i < points.length; i++) {
      final o = Offset(xOf(points[i].date), yOf(values[i]));
      canvas.drawCircle(o, 4.5, dot);
      canvas.drawCircle(o, 2, hole);
    }

    // Dose markers along the bottom.
    final diamond = Paint()..color = AppColors.violet;
    for (final d in doses) {
      final x = xOf(d);
      canvas.save();
      canvas.translate(x, size.height - 6);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), diamond);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.points != points || old.doses != doses || old.start != start;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KCard(
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.tiny.copyWith(fontSize: 12, color: k.muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.h3.copyWith(fontSize: 18)),
          ),
          Text(sub, style: AppText.tiny.copyWith(color: k.faint), maxLines: 1),
        ],
      ),
    );
  }
}

class _StripCard extends StatelessWidget {
  const _StripCard({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.bars,
    required this.color,
    required this.track,
  });

  final String icon;
  final String title;
  final String trailing;
  final List<DayBar> bars;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ThreeD(icon, size: 28),
              const SizedBox(width: 8),
              Text(title, style: AppText.title),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trailing,
                  textAlign: TextAlign.right,
                  style: AppText.small.copyWith(color: k.muted),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: math.max(0.06, bars[i].value),
                              widthFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bars[i].value == 0 ? Colors.transparent : color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(bars[i].label, style: AppText.tiny.copyWith(color: k.faint)),
                      ],
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
