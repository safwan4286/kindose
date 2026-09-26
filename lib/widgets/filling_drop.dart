import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../resources/colors.dart';
import 'drop_mark.dart';

/// The Kindose drop as a progress indicator: an ink outline that fills with
/// lime from the bottom, with a small moving wave on top. At the end the
/// smile draws in and the shine appears, so it becomes the logo.
/// Same geometry as [DropMark] (100-unit box).
class FillingDrop extends StatelessWidget {
  const FillingDrop({
    super.key,
    required this.size,
    required this.fill,
    this.wave = 0,
    this.smile = 0,
    this.shine = 0,
    this.squash = 0,
  });

  final double size;

  /// 0 = empty, 1 = full.
  final double fill;

  /// Wave phase 0–1 (loop it for motion).
  final double wave;
  final double smile;
  final double shine;

  /// 0–1 landing squash, peaks in the middle.
  final double squash;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final s = math.sin(squash.clamp(0.0, 1.0) * math.pi);
    return Transform(
      alignment: const Alignment(0, 0.7),
      transform: Matrix4.diagonal3Values(1 + 0.08 * s, 1 - 0.08 * s, 1),
      child: CustomPaint(
        size: Size.square(size),
        painter: _FillingDropPainter(
          fill: fill,
          wave: wave,
          smile: smile,
          shine: shine,
          inside: k.card,
          outline: k.text,
        ),
      ),
    );
  }
}

class _FillingDropPainter extends CustomPainter {
  _FillingDropPainter({
    required this.fill,
    required this.wave,
    required this.smile,
    required this.shine,
    required this.inside,
    required this.outline,
  });

  final double fill;
  final double wave;
  final double smile;
  final double shine;
  final Color inside;
  final Color outline;

  // The drop spans y = 14 (tip) to y = 83 (bottom) in the 100 box.
  static const double _top = 12;
  static const double _bottom = 84;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final drop = DropMarkPainter.dropPath;

    canvas.drawPath(drop, Paint()..color = inside);

    // Lime liquid clipped to the drop, with a sine wave on its surface.
    canvas.save();
    canvas.clipPath(drop);
    final level = _bottom - (_bottom - _top) * fill.clamp(0.0, 1.0);
    final amp = fill >= 1 ? 0.0 : 2.2;
    final liquid = Path()..moveTo(0, 100);
    for (var x = 0.0; x <= 100; x += 2) {
      final y = level + amp * math.sin((x / 20 + wave * 2) * math.pi);
      liquid.lineTo(x, y);
    }
    liquid
      ..lineTo(100, 100)
      ..close();
    canvas.drawPath(liquid, Paint()..color = AppColors.lime);
    canvas.restore();

    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = outline,
    );

    if (shine > 0) {
      canvas.drawPath(
        DropMarkPainter.shinePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round
          ..color = AppColors.white.withValues(alpha: 0.75 * shine.clamp(0.0, 1.0)),
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
  bool shouldRepaint(_FillingDropPainter old) =>
      old.fill != fill || old.wave != wave || old.smile != smile || old.shine != shine || old.outline != outline;
}
