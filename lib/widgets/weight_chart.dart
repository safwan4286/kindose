import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../resources/colors.dart';
import '../resources/date_utils.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// Weight over time: a smooth line with a soft lime fill, round-number
/// axis, short dose-change tags and a dot on the latest weigh-in. Touch or
/// drag across it for a crosshair and a "13 Oct · 79.2 kg" pill (hidden
/// again shortly after letting go). The goal line shows only when it fits
/// without squashing the line. Values are already in the unit to show.
class WeightChart extends StatefulWidget {
  const WeightChart({
    super.key,
    required this.dates,
    required this.values,
    required this.unit,
    this.goal,
    this.markers = const [],
    this.height = 184,
    // Kept for older call sites; the chart keeps its own touch state now.
    this.selected = -1,
    this.onPick,
  });

  final List<DateTime> dates;
  final List<double> values;
  final String unit;
  final double? goal;

  /// (date, label) where the dose changed, e.g. "7.5 mg".
  final List<(DateTime, String)> markers;
  final double height;
  final int selected;
  final ValueChanged<int>? onPick;

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  /// Point under the finger, or null when not touching.
  int? _touch;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _pick(int i) {
    _hide?.cancel();
    if (_touch != i) {
      Haptics.instance.selectionClick();
      setState(() => _touch = i);
    }
  }

  void _release() {
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _touch = null);
    });
  }

  /// Round-number grid lines covering [lo]–[hi], 3 to 5 of them.
  static List<double> _ticks(double lo, double hi) {
    var span = hi - lo;
    if (span < 1) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
      span = 1;
    }
    const steps = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0];
    final step = steps.firstWhere((s) => span / s <= 4, orElse: () => 100);
    final a = (lo / step).floor() * step;
    final b = (hi / step).ceil() * step;
    return [for (var v = a; v <= b + 1e-9; v += step) v];
  }

  static String _fmtTick(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final dates = widget.dates;
    final values = widget.values;
    final h = widget.height.sp;
    final labelW = 30.sp;
    final motion = !MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth - labelW;
        final top = 26.sp, bottom = h - 22.sp;

        var lo = values.reduce(math.min);
        var hi = values.reduce(math.max);
        // Goal only when it fits without squashing the line.
        final g = widget.goal;
        final span = math.max(1.0, hi - lo);
        final showGoal = g != null && g >= lo - span * 0.6 && g <= hi + span;
        if (showGoal) {
          lo = math.min(lo, g!);
          hi = math.max(hi, g);
        }
        final ticks = _ticks(lo - 0.2, hi + 0.2);
        lo = ticks.first;
        hi = ticks.last;

        final first = dates.first;
        final last = dates.last;
        final spanDays = math.max(1, Dates.daysBetween(first, last));
        double x(DateTime d) => values.length == 1
            ? w / 2
            : 6 + (w - 12) * Dates.daysBetween(first, d) / spanDays;
        double y(double v) => top + (hi - v) / (hi - lo) * (bottom - top);

        final xs = [for (final d in dates) x(d)];
        final ys = [for (final v in values) y(v)];
        final markers = widget.markers
            .where((m) => !m.$1.isBefore(first) && !m.$1.isAfter(last))
            .toList();

        // Tags left to right, skipping one that would overlap the last.
        final tags = <(double, String)>[];
        var lastTagX = -999.0;
        for (final m in markers) {
          final mx = x(m.$1);
          if (mx - lastTagX >= 52.sp) {
            tags.add((mx, m.$2));
            lastTagX = mx;
          }
        }

        final touch = _touch;
        final sel = touch == null || touch >= values.length ? null : touch;
        final tipText = sel == null
            ? ''
            : '${Dates.short(dates[sel])} · ${values[sel].toStringAsFixed(1)} ${widget.unit}';
        final tipW = tipText.length * 6.6.sp + 22.sp;
        final tipX = sel == null
            ? 0.0
            : (xs[sel] - tipW / 2).clamp(0.0, math.max(0.0, w - tipW));

        int nearest(double px) {
          var best = 0;
          for (var i = 1; i < xs.length; i++) {
            if ((xs[i] - px).abs() < (xs[best] - px).abs()) best = i;
          }
          return best;
        }

        final mid = DateTime.fromMillisecondsSinceEpoch(
          (first.millisecondsSinceEpoch + last.millisecondsSinceEpoch) ~/ 2,
        );
        final tickStyle = AppText.tiny.copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: k.faint,
        );

        return Semantics(
          label:
              'Weight chart. ${values.first.toStringAsFixed(1)} ${widget.unit} on ${Dates.long(first)}, '
              '${values.last.toStringAsFixed(1)} ${widget.unit} on ${Dates.long(last)}.',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (e) => _pick(nearest(e.localPosition.dx)),
            onTapUp: (_) => _release(),
            onHorizontalDragStart: (e) => _pick(nearest(e.localPosition.dx)),
            onHorizontalDragUpdate: (e) => _pick(nearest(e.localPosition.dx)),
            onHorizontalDragEnd: (_) => _release(),
            onHorizontalDragCancel: _release,
            child: SizedBox(
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChartPainter(
                        xs: xs,
                        ys: ys,
                        gridYs: [for (final t in ticks) y(t)],
                        plotWidth: w,
                        plotBottom: bottom,
                        goalY: showGoal ? y(g!) : null,
                        markerXs: [for (final m in markers) x(m.$1)],
                        markerTop: top - 4,
                        touchX: sel == null ? null : xs[sel],
                        touchY: sel == null ? null : ys[sel],
                        grid: k.border,
                        line: k.text,
                        fill: AppColors.lime.withValues(
                          alpha: dark ? 0.22 : 0.5,
                        ),
                        markerLine: k.faint.withValues(alpha: 0.6),
                        goalColor: dark ? AppColors.lime : AppColors.limeText,
                        dot: AppColors.lime,
                        surface: k.card,
                      ),
                    ),
                  ),
                  // Y axis, right.
                  for (final t in ticks)
                    Positioned(
                      right: 0,
                      top: y(t) - 7.sp,
                      child: ExcludeSemantics(
                        child: Text(_fmtTick(t), style: tickStyle),
                      ),
                    ),
                  // X axis: start, middle, end.
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Text(Dates.short(first), style: tickStyle),
                  ),
                  if (spanDays >= 6)
                    Positioned(
                      left: 0,
                      right: labelW,
                      bottom: 0,
                      child: Text(
                        Dates.short(mid),
                        textAlign: TextAlign.center,
                        style: tickStyle,
                      ),
                    ),
                  Positioned(
                    right: labelW,
                    bottom: 0,
                    child: Text(Dates.short(last), style: tickStyle),
                  ),
                  if (showGoal)
                    Positioned(
                      left: 2,
                      top: y(g!) - 17.sp,
                      child: Text(
                        'Goal ${_fmtTick(g)}',
                        style: tickStyle.copyWith(
                          color: dark ? AppColors.lime : AppColors.limeText,
                        ),
                      ),
                    ),
                  // Dose tags; they step aside while the pill shows.
                  for (final (tx, label) in tags)
                    Positioned(
                      left: math.min(tx - 2, w - 52.sp),
                      top: 0,
                      child: AnimatedOpacity(
                        opacity: sel == null ? 1 : 0,
                        duration: Duration(milliseconds: motion ? 150 : 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.sp,
                            vertical: 2.sp,
                          ),
                          decoration: BoxDecoration(
                            color: dark ? k.cardAlt : AppColors.limeSoft,
                            borderRadius: BorderRadius.circular(7.sp),
                          ),
                          child: Text(
                            label,
                            style: AppText.tiny.copyWith(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w800,
                              color: dark ? AppColors.lime : AppColors.limeText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (sel != null)
                    Positioned(
                      left: tipX.toDouble(),
                      top: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 22.sp,
                          padding: EdgeInsets.symmetric(horizontal: 10.sp),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: k.text,
                            borderRadius: BorderRadius.circular(11.sp),
                          ),
                          child: Text(
                            tipText,
                            style: AppText.small.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: k.card,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.xs,
    required this.ys,
    required this.gridYs,
    required this.plotWidth,
    required this.plotBottom,
    required this.goalY,
    required this.markerXs,
    required this.markerTop,
    required this.touchX,
    required this.touchY,
    required this.grid,
    required this.line,
    required this.fill,
    required this.markerLine,
    required this.goalColor,
    required this.dot,
    required this.surface,
  });

  final List<double> xs;
  final List<double> ys;
  final List<double> gridYs;
  final double plotWidth;
  final double plotBottom;
  final double? goalY;
  final List<double> markerXs;
  final double markerTop;
  final double? touchX;
  final double? touchY;
  final Color grid;
  final Color line;
  final Color fill;
  final Color markerLine;
  final Color goalColor;
  final Color dot;
  final Color surface;

  /// Smooth line through the points that never overshoots them
  /// (monotone cubic, Fritsch–Carlson).
  Path _smooth() {
    final n = xs.length;
    final p = Path()..moveTo(xs[0], ys[0]);
    if (n == 1) return p;
    final dx = List<double>.generate(n - 1, (i) => xs[i + 1] - xs[i]);
    final s = List<double>.generate(
      n - 1,
      (i) => dx[i] == 0 ? 0 : (ys[i + 1] - ys[i]) / dx[i],
    );
    final m = List<double>.filled(n, 0);
    m[0] = s[0];
    m[n - 1] = s[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = s[i - 1] * s[i] <= 0 ? 0 : (s[i - 1] + s[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      final h = dx[i] / 3;
      p.cubicTo(
        xs[i] + h,
        ys[i] + m[i] * h,
        xs[i + 1] - h,
        ys[i + 1] - m[i + 1] * h,
        xs[i + 1],
        ys[i + 1],
      );
    }
    return p;
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p, double on, double off) {
    final len = (b - a).distance;
    if (len == 0) return;
    final dir = (b - a) / len;
    for (var d = 0.0; d < len; d += on + off) {
      c.drawLine(a + dir * d, a + dir * math.min(d + on, len), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final gy in gridYs) {
      canvas.drawLine(Offset(0, gy), Offset(plotWidth, gy), gridPaint);
    }

    final mPaint = Paint()
      ..color = markerLine
      ..strokeWidth = 1;
    for (final mx in markerXs) {
      _dashed(canvas, Offset(mx, markerTop), Offset(mx, plotBottom), mPaint, 2, 3);
    }

    final g = goalY;
    if (g != null) {
      _dashed(
        canvas,
        Offset(0, g),
        Offset(plotWidth, g),
        Paint()
          ..color = goalColor
          ..strokeWidth = 1.5,
        4,
        4,
      );
    }

    final path = _smooth();
    if (xs.length > 1) {
      final area = Path.from(path)
        ..lineTo(xs.last, plotBottom)
        ..lineTo(xs.first, plotBottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fill, fill.withValues(alpha: 0)],
          ).createShader(Rect.fromLTRB(0, gridYs.first, plotWidth, plotBottom)),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );

    final tx = touchX;
    final ty = touchY;
    if (tx != null && ty != null) {
      canvas.drawLine(
        Offset(tx, markerTop),
        Offset(tx, plotBottom),
        Paint()
          ..color = line.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
    }

    // Latest weigh-in: lime dot with an ink ring.
    final lx = xs.last, ly = ys.last;
    canvas.drawCircle(Offset(lx, ly), 7.5, Paint()..color = surface);
    canvas.drawCircle(Offset(lx, ly), 5.5, Paint()..color = dot);
    canvas.drawCircle(
      Offset(lx, ly),
      5.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = line,
    );

    if (tx != null && ty != null && (tx != lx || ty != ly)) {
      canvas.drawCircle(Offset(tx, ty), 5, Paint()..color = surface);
      canvas.drawCircle(
        Offset(tx, ty),
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = line,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}
