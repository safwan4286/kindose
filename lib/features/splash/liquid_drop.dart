import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../resources/colors.dart';
import '../../widgets/drop_mark.dart';

/// The splash drop: a lime outline (the native launch image) that fills with
/// liquid. Same 100 × 100 geometry as [DropMarkPainter], so frame one lines
/// up exactly with the launch image.
class LiquidDropPainter extends CustomPainter {
  LiquidDropPainter({
    required this.drip,
    required this.dripY,
    required this.fill,
    required this.wave,
    required this.phase,
    required this.splash,
    required this.smile,
    required this.shine,
    required this.bubbles,
  });

  /// Drip forming under the tip, 0–1 (its size). 0 = none.
  final double drip;

  /// Drip position (box units, y-down) while it falls. Ignored when [drip]
  /// is 0.
  final double dripY;

  /// Liquid level: 0 = empty, 1 = full.
  final double fill;

  /// Wave height in box units (0 = flat surface).
  final double wave;

  /// Wave phase in radians.
  final double phase;

  /// Ring where the drip hit the bottom, 0 = hidden, 1 = spread and gone.
  final double splash;

  final double smile;
  final double shine;

  /// 0–1 progress of the rising bubbles (0 or 1 = none shown).
  final double bubbles;

  static const double _stroke = 4;
  static const double _bottom = 83;
  static const double _top = 14;

  static const Color _deep = Color(0xFFB9E02E);

  /// Back wave: a pale lime, so on ink it reads as foam, not a dark band.
  static const Color _foam = Color(0xFFEFFDB0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final drop = DropMarkPainter.dropPath;

    // ---------------------------------------------------------- liquid
    if (fill > 0) {
      canvas.save();
      canvas.clipPath(drop);
      // Level goes a little past the tip so the top is fully covered.
      final level = _bottom - (_bottom - _top + 6) * fill;

      Path surface(double ph, double amp) {
        final p = Path()..moveTo(18, 100);
        for (var x = 18.0; x <= 82; x += 2) {
          p.lineTo(x, level + amp * math.sin(x / 64 * 2 * math.pi + ph));
        }
        return p
          ..lineTo(82, 100)
          ..close();
      }

      // Back wave: lighter and out of step, for depth.
      canvas.drawPath(
        surface(phase + 2.2, wave * 0.8),
        Paint()..color = _foam.withValues(alpha: 0.7),
      );
      // Front wave with a slight gradient, deeper at the bottom.
      final front = surface(phase, wave);
      canvas.drawPath(
        front,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.lime, _deep],
          ).createShader(const Rect.fromLTWH(0, 14, 100, 70)),
      );
      // A thin light line along the surface while it moves.
      if (wave > 0.2) {
        final line = Path()
          ..moveTo(18, level + wave * math.sin(18 / 64 * 2 * math.pi + phase));
        for (var x = 20.0; x <= 82; x += 2) {
          line.lineTo(x, level + wave * math.sin(x / 64 * 2 * math.pi + phase));
        }
        canvas.drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(
              alpha: 0.35 * (wave / 4).clamp(0.0, 1.0),
            ),
        );
      }
      // A few bubbles rising through the liquid.
      if (bubbles > 0 && bubbles < 1) {
        const seeds = [(38.0, 0.0, 1.6), (55.0, 0.18, 1.2), (47.0, 0.36, 2.0)];
        for (final (x, delay, r) in seeds) {
          final p = ((bubbles - delay) / 0.6).clamp(0.0, 1.0);
          if (p <= 0 || p >= 1) continue;
          final y = _bottom - 4 - (_bottom - 4 - level) * p;
          if (y < level + 1) continue;
          canvas.drawCircle(
            Offset(x + 1.5 * math.sin(p * 9), y),
            r,
            Paint()
              ..color = Colors.white.withValues(
                alpha: 0.45 * math.sin(p * math.pi),
              ),
          );
        }
      }
      canvas.restore();
    }

    // ---------------------------------------------------------- outline
    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = AppColors.lime,
    );

    // ---------------------------------------------------------- drip
    if (drip > 0) {
      final r = 3.4 * drip;
      final c = Offset(50, dripY);
      // A small teardrop: circle plus a point above it.
      final d = Path()
        ..moveTo(c.dx, c.dy - r * 2.1)
        ..quadraticBezierTo(c.dx + r * 1.05, c.dy - r * 0.6, c.dx + r, c.dy)
        ..arcToPoint(Offset(c.dx - r, c.dy), radius: Radius.circular(r))
        ..quadraticBezierTo(
          c.dx - r * 1.05,
          c.dy - r * 0.6,
          c.dx,
          c.dy - r * 2.1,
        )
        ..close();
      canvas.drawPath(d, Paint()..color = AppColors.lime);
    }

    // ---------------------------------------------------------- splash ring
    if (splash > 0 && splash < 1) {
      canvas.save();
      canvas.clipPath(drop);
      final level = _bottom - (_bottom - _top + 6) * fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(50, level),
          width: 6 + 30 * splash,
          height: 2 + 4 * splash,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.6 * (1 - splash)),
      );
      canvas.restore();
    }

    // ---------------------------------------------------------- face
    if (shine > 0) {
      canvas.drawPath(
        DropMarkPainter.shinePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.6 * shine.clamp(0, 1)),
      );
    }
    if (smile > 0) {
      final metric = DropMarkPainter.smilePath.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * smile.clamp(0.0, 1.0)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = AppColors.ink,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LiquidDropPainter old) =>
      old.drip != drip ||
      old.dripY != dripY ||
      old.fill != fill ||
      old.wave != wave ||
      old.phase != phase ||
      old.splash != splash ||
      old.smile != smile ||
      old.shine != shine ||
      old.bubbles != bubbles;
}
