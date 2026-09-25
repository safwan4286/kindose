import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular progress ring with a round cap.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    this.size = 96,
    this.stroke = 10,
    this.child,
  });

  /// 0.0 – 1.0
  final double value;
  final Color color;
  final Color track;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(v, color, track, stroke),
          child: child,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, base);
    if (value <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Simple injector pen drawn in the medicine's colours.
class PenArt extends StatelessWidget {
  const PenArt({super.key, required this.body, required this.cap, this.height = 70, this.tilt = -0.2});

  final Color body;
  final Color cap;
  final double height;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: tilt,
        child: CustomPaint(
          size: Size(height * 34 / 84, height),
          painter: _PenPainter(body, cap),
        ),
      ),
    );
  }
}

class _PenPainter extends CustomPainter {
  _PenPainter(this.body, this.cap);

  final Color body;
  final Color cap;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 84;
    RRect r(double x, double y, double w, double h, double rad) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x * s, y * s, w * s, h * s), Radius.circular(rad * s));
    canvas.drawRRect(r(9, 2, 16, 16, 5), Paint()..color = cap);
    canvas.drawRRect(r(5, 15, 24, 64, 10), Paint()..color = body);
    canvas.drawRRect(
      r(11, 30, 12, 20, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_PenPainter old) => old.body != body || old.cap != cap;
}
