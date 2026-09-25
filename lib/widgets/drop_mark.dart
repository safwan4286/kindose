import 'package:flutter/material.dart';

import '../resources/colors.dart';

/// The Kindose drop, drawn in code so it stays sharp at any size and can be
/// animated. Geometry uses the same 100 × 100 box as the logo SVGs in
/// assets/brand, so it lines up exactly with the native splash image.
class DropMark extends StatelessWidget {
  const DropMark({
    super.key,
    this.size = 120,
    this.smile = 1,
    this.shine = 1,
    this.ripple = 0,
  });

  final double size;

  /// 0 = no smile, 1 = smile fully drawn.
  final double smile;

  /// Opacity of the white highlight, 0–1.
  final double shine;

  /// Ring under the drop after it lands, 0 = hidden, 1 = fully spread and gone.
  final double ripple;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: DropMarkPainter(smile: smile, shine: shine, ripple: ripple),
      ),
    );
  }
}

class DropMarkPainter extends CustomPainter {
  DropMarkPainter({required this.smile, required this.shine, required this.ripple});

  final double smile;
  final double shine;
  final double ripple;

  static Path get dropPath => Path()
    ..moveTo(50, 14)
    ..cubicTo(50, 14, 26, 43, 26, 59)
    ..arcToPoint(const Offset(74, 59), radius: const Radius.circular(24), clockwise: false)
    ..cubicTo(74, 43, 50, 14, 50, 14)
    ..close();

  static Path get smilePath => Path()
    ..moveTo(40.5, 60)
    ..quadraticBezierTo(50, 69, 59.5, 60);

  static Path get shinePath => Path()
    ..moveTo(38.5, 42)
    ..quadraticBezierTo(34.2, 48.5, 33.6, 55);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    if (ripple > 0 && ripple < 1) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.lime.withValues(alpha: 0.55 * (1 - ripple));
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 85), width: 34 + 44 * ripple, height: 8 + 8 * ripple),
        ring,
      );
    }

    canvas.drawPath(dropPath, Paint()..color = AppColors.lime);

    if (shine > 0) {
      canvas.drawPath(
        shinePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.6 * shine.clamp(0.0, 1.0)),
      );
    }

    if (smile > 0) {
      final metric = smilePath.computeMetrics().first;
      final partial = metric.extractPath(0, metric.length * smile.clamp(0.0, 1.0));
      canvas.drawPath(
        partial,
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
  bool shouldRepaint(DropMarkPainter old) =>
      old.smile != smile || old.shine != shine || old.ripple != ripple;
}
