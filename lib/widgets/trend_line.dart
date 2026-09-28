import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../resources/colors.dart';

/// Small line chart for a few values (oldest first), with an optional
/// dashed goal line. The last point is drawn big and lime when
/// [highlightLast] is on (e.g. the weight about to be saved).
///
/// Decorative: wrap it in Semantics with a text summary where it's used.
class TrendLine extends StatelessWidget {
  const TrendLine({
    super.key,
    required this.values,
    this.goal,
    this.height = 90,
    this.highlightLast = true,
  });

  final List<double> values;
  final double? goal;
  final double height;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 600),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => CustomPaint(
            painter: _TrendPainter(
              values: values,
              goal: goal,
              progress: t,
              line: k.text,
              dot: k.card,
              goalColor: k.faint,
              highlightLast: highlightLast,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.goal,
    required this.progress,
    required this.line,
    required this.dot,
    required this.goalColor,
    required this.highlightLast,
  });

  final List<double> values;
  final double? goal;
  final double progress;
  final Color line;
  final Color dot;
  final Color goalColor;
  final bool highlightLast;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final g = goal;
    final all = [...values, if (g != null) g];
    final lo = all.reduce(math.min) - 1;
    final hi = all.reduce(math.max) + 1;
    const pad = 8.0;
    double y(double v) => pad + (hi - v) / (hi - lo) * (size.height - pad * 2);
    double x(int i) => values.length == 1 ? size.width / 2 : pad + i * (size.width - pad * 2) / (values.length - 1);

    if (g != null) {
      final gy = y(g);
      final p = Paint()
        ..color = goalColor
        ..strokeWidth = 2;
      for (var dx = 0.0; dx < size.width; dx += 10) {
        canvas.drawLine(Offset(dx, gy), Offset(math.min(dx + 5, size.width), gy), p);
      }
    }

    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    final metric = path.computeMetrics().toList();
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in metric) {
      canvas.drawPath(m.extractPath(0, m.length * progress), stroke);
    }

    for (var i = 0; i < values.length; i++) {
      final last = i == values.length - 1;
      if (i / math.max(1, values.length - 1) > progress + 0.001) break;
      final c = Offset(x(i), y(values[i]));
      final big = last && highlightLast;
      canvas.drawCircle(c, big ? 6.5 : 3.5, Paint()..color = big ? AppColors.lime : dot);
      canvas.drawCircle(
        c,
        big ? 6.5 : 3.5,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = big ? 2.5 : 2,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.goal != goal || old.progress != progress || old.line != line;
}
