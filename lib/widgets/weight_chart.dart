import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../resources/colors.dart';
import '../resources/date_utils.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// Weight over time: hairline grid, 2.5px ink line, tappable dots with a
/// tooltip, optional dashed goal line and "dose changed" markers.
/// Values are already in the unit to show.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.dates,
    required this.values,
    required this.unit,
    required this.selected,
    required this.onPick,
    this.goal,
    this.markers = const [],
    this.height = 190,
  });

  final List<DateTime> dates;
  final List<double> values;
  final String unit;

  /// Index of the highlighted point; -1 = last.
  final int selected;
  final ValueChanged<int> onPick;
  final double? goal;

  /// (date, label) — a vertical line where the dose changed.
  final List<(DateTime, String)> markers;
  final double height;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final h = height.sp;
    final labelW = 34.sp;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth - labelW;
      final g = goal;
      final all = [...values, if (g != null) g];
      final lo = (all.reduce(math.min) - 0.5).floorToDouble();
      final hi = (all.reduce(math.max) + 0.5).ceilToDouble();
      final top = 22.sp, bottom = h - 48.sp;
      final first = dates.first;
      final spanDays = math.max(1, Dates.daysBetween(first, dates.last));
      double x(DateTime d) => values.length == 1 ? w / 2 : 8 + (w - 16) * Dates.daysBetween(first, d) / spanDays;
      double y(double v) => top + (hi - v) / (hi - lo) * (bottom - top);
      final sel = selected < 0 || selected >= values.length ? values.length - 1 : selected;
      final tipText = '${Dates.short(dates[sel])} · ${values[sel].toStringAsFixed(1)} $unit';
      final tipW = 128.sp;
      final tipX = (x(dates[sel]) - tipW / 2).clamp(0.0, math.max(0.0, w - tipW));
      final tipY = math.max(0.0, y(values[sel]) - 44.sp);
      final shownMarkers = markers.where((m) => !m.$1.isBefore(first)).toList();

      return SizedBox(
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ChartPainter(
                  xs: [for (final d in dates) x(d)],
                  ys: [for (final v in values) y(v)],
                  gridYs: [top, (top + bottom) / 2, bottom],
                  plotWidth: w,
                  goalY: g == null ? null : y(g),
                  markerXs: [for (final m in shownMarkers) x(m.$1)],
                  markerTop: 18.sp,
                  markerBottom: bottom + 2,
                  grid: k.border,
                  line: k.text,
                  goalColor: k.faint,
                ),
              ),
            ),
            for (final (v, yy) in [(hi, top), ((hi + lo) / 2, (top + bottom) / 2), (lo, bottom)])
              Positioned(
                right: 0,
                top: yy - 8.sp,
                child: ExcludeSemantics(
                  child: Text(v.toStringAsFixed(0), style: AppText.tiny.copyWith(fontSize: 11.sp, color: k.faint)),
                ),
              ),
            if (g != null)
              Positioned(
                left: 0,
                top: y(g) - 18.sp,
                child: Text('Goal ${g.toStringAsFixed(0)} $unit', style: AppText.tiny.copyWith(fontSize: 11.sp, color: k.muted)),
              ),
            for (final m in shownMarkers)
              Positioned(
                left: math.min(x(m.$1) + 6, w - 110.sp),
                top: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.sp, vertical: 2.sp),
                  decoration: BoxDecoration(
                    color: k.selectedBorder == AppColors.lime ? k.cardAlt : AppColors.limeSoft,
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: Text(
                    m.$2,
                    style: AppText.tiny.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w800, color: k.selectedBorder == AppColors.lime ? k.text : AppColors.limeText),
                  ),
                ),
              ),
            for (var i = 0; i < values.length; i++)
              Positioned(
                left: x(dates[i]) - 16,
                top: y(values[i]) - 16,
                width: 32,
                height: 32,
                child: Semantics(
                  button: true,
                  selected: i == sel,
                  label: '${Dates.long(dates[i])}, ${values[i].toStringAsFixed(1)} $unit',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(i),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: i == sel ? 13 : 9,
                        height: i == sel ? 13 : 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == sel ? AppColors.lime : k.card,
                          border: Border.all(color: k.text, width: 2.5),
                          boxShadow: [BoxShadow(color: k.card, spreadRadius: 2)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: tipX.toDouble(),
              top: tipY,
              width: tipW,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 6.sp),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: k.text, borderRadius: BorderRadius.circular(10.sp)),
                    child: Text(tipText, maxLines: 1, style: AppText.tiny.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w800, color: k.bg)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: labelW,
              top: bottom + 10.sp,
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(child: Text(Dates.short(first), style: AppText.tiny.copyWith(fontSize: 11.sp, color: k.faint))),
                    Text(
                      Dates.sameDay(dates.last, DateTime.now()) ? 'Today' : Dates.short(dates.last),
                      style: AppText.tiny.copyWith(fontSize: 11.sp, color: k.faint),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.xs,
    required this.ys,
    required this.gridYs,
    required this.plotWidth,
    required this.goalY,
    required this.markerXs,
    required this.markerTop,
    required this.markerBottom,
    required this.grid,
    required this.line,
    required this.goalColor,
  });

  final List<double> xs;
  final List<double> ys;
  final List<double> gridYs;
  final double plotWidth;
  final double? goalY;
  final List<double> markerXs;
  final double markerTop;
  final double markerBottom;
  final Color grid;
  final Color line;
  final Color goalColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final gy in gridYs) {
      canvas.drawLine(Offset(0, gy), Offset(plotWidth, gy), gp);
    }
    final g = goalY;
    if (g != null) {
      final p = Paint()
        ..color = goalColor
        ..strokeWidth = 2;
      for (var dx = 0.0; dx < plotWidth; dx += 10) {
        canvas.drawLine(Offset(dx, g), Offset(math.min(dx + 5, plotWidth), g), p);
      }
    }
    final mp = Paint()
      ..color = line.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (final mx in markerXs) {
      canvas.drawLine(Offset(mx, markerTop), Offset(mx, markerBottom), mp);
    }
    if (xs.length >= 2) {
      final path = Path()..moveTo(xs[0], ys[0]);
      for (var i = 1; i < xs.length; i++) {
        path.lineTo(xs[i], ys[i]);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.xs != xs || old.ys != ys || old.goalY != goalY || old.line != line || old.markerXs != markerXs;
}
