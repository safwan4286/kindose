import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../resources/colors.dart';
import 'drop_mark.dart';

/// A smooth line from today's value (top left) to the goal (bottom right),
/// ending in the Kindose drop. No dates on purpose: it shows the direction,
/// not a promised pace. Pass [progress] 0–1 to draw it in.
class GoalCurve extends StatelessWidget {
  const GoalCurve({
    super.key,
    required this.height,
    this.progress = 1,
    this.rising = false,
    this.line = AppColors.lime,
    this.dotBorder = AppColors.ink,
    this.guide = AppColors.heroMuted,
  });

  final double height;
  final double progress;

  /// Goal above today (gaining): the curve goes up instead of down.
  final bool rising;
  final Color line;
  final Color dotBorder;
  final Color guide;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _GoalCurvePainter(
            progress: progress.clamp(0.0, 1.0),
            rising: rising,
            line: line,
            dotBorder: dotBorder,
            guide: guide,
          ),
        ),
      ),
    );
  }
}

class _GoalCurvePainter extends CustomPainter {
  _GoalCurvePainter({
    required this.progress,
    required this.rising,
    required this.line,
    required this.dotBorder,
    required this.guide,
  });

  final double progress;
  final bool rising;
  final Color line;
  final Color dotBorder;
  final Color guide;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pad = w * 0.045;
    final high = h * 0.38;
    final low = h * 0.75;
    final start = Offset(pad, rising ? low : high);
    final end = Offset(w - pad, rising ? high : low);

    final curve = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + (end.dx - start.dx) * 0.29, start.dy + (end.dy - start.dy) * 0.07,
        start.dx + (end.dx - start.dx) * 0.55, end.dy - (end.dy - start.dy) * 0.04,
        end.dx, end.dy,
      );

    // Dashed goal guide.
    final dash = Paint()
      ..color = guide.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (var x = start.dx; x < end.dx; x += 9) {
      canvas.drawLine(Offset(x, end.dy), Offset(math.min(x + 4, end.dx), end.dy), dash);
    }

    // Soft area under the line, fading down.
    final areaAlpha = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    if (areaAlpha > 0) {
      final area = Path.from(curve)
        ..lineTo(end.dx, h)
        ..lineTo(start.dx, h)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, high),
            Offset(0, h),
            [line.withValues(alpha: 0.22 * areaAlpha), line.withValues(alpha: 0)],
          ),
      );
    }

    // The line, drawn in with [progress].
    final metric = curve.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = line,
    );

    // Start dot.
    canvas.drawCircle(start, 6.5, Paint()..color = dotBorder);
    canvas.drawCircle(start, 5, Paint()..color = AppColors.white);

    // Drop at the goal pops in once the line arrives.
    final pop = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    if (pop > 0) {
      final s = 36 / 100 * Curves.easeOutBack.transform(pop);
      canvas.save();
      // Drop's bottom (y≈83 of 100) sits on the end point.
      canvas.translate(end.dx - 50 * s, end.dy - 83 * s);
      canvas.scale(s);
      canvas.drawPath(DropMarkPainter.dropPath, Paint()..color = line);
      canvas.drawPath(
        DropMarkPainter.dropPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = dotBorder,
      );
      canvas.drawPath(
        DropMarkPainter.smilePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = AppColors.ink,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GoalCurvePainter old) =>
      old.progress != progress || old.rising != rising || old.line != line;
}
