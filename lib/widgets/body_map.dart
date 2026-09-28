import 'package:flutter/material.dart';

import '../resources/catalog.dart';
import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// Front-facing body with the 8 injection spots from [Catalog.sites].
///
/// * [selected] shows an ink dot with a lime tick.
/// * [suggested] gets a lime ring.
/// * [rankOf] returns 1–3 for the last three spots used (shown as numbers),
///   or 0.
///
/// The drawing is 200 × 300 design units, scaled to [width].
class BodyMap extends StatelessWidget {
  const BodyMap({
    super.key,
    required this.selected,
    required this.onPick,
    required this.rankOf,
    this.suggested,
    this.width = 240,
  });

  final String selected;
  final String? suggested;
  final int Function(String id) rankOf;
  final ValueChanged<String> onPick;
  final double width;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final w = width.sp;
    final scale = w / 200;
    final hit = 42.sp;
    final side = AppText.small.copyWith(
      fontSize: 13.sp,
      fontWeight: FontWeight.w800,
      color: k.faint,
    );
    return SizedBox(
      width: w + 60.sp,
      height: 300 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The user's right is on the left of the drawing (facing you).
          Positioned(
            left: 0,
            top: 138 * scale,
            child: ExcludeSemantics(child: Text('R', style: side)),
          ),
          Positioned(
            right: 0,
            top: 138 * scale,
            child: ExcludeSemantics(child: Text('L', style: side)),
          ),
          Positioned(
            left: 30.sp,
            top: 0,
            width: w,
            height: 300 * scale,
            child: CustomPaint(
              painter: _BodyPainter(fill: k.cardAlt, navel: k.border),
            ),
          ),
          for (final s in Catalog.sites)
            Positioned(
              left: 30.sp + s.x * scale - hit / 2,
              top: s.y * scale - hit / 2,
              width: hit,
              height: hit,
              child: _Spot(
                name: s.name,
                selected: s.id == selected,
                suggested: s.id == suggested,
                rank: rankOf(s.id),
                onTap: () => onPick(s.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _Spot extends StatelessWidget {
  const _Spot({
    required this.name,
    required this.selected,
    required this.suggested,
    required this.rank,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final bool suggested;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final ink = dark ? AppColors.lime : AppColors.ink;
    final onInk = dark ? AppColors.ink : AppColors.lime;
    final state = selected
        ? 'selected'
        : suggested
        ? 'suggested next'
        : rank == 1
        ? 'used last time'
        : rank > 1
        ? 'used $rank doses ago'
        : 'not used recently';
    final size = 26.sp;
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $state',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedScale(
            scale: selected ? 1.12 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? ink
                    : rank > 0
                    ? k.border
                    : k.card,
                border: Border.all(
                  color: selected || suggested ? ink : k.faint,
                  width: 2.5,
                ),
                boxShadow: [
                  if (suggested && !selected)
                    BoxShadow(
                      color: AppColors.lime.withValues(alpha: 0.95),
                      spreadRadius: 5.sp,
                    ),
                  if (selected)
                    BoxShadow(
                      color: ink.withValues(alpha: 0.14),
                      spreadRadius: 5.sp,
                    ),
                ],
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 15.sp, color: onInk)
                  : rank > 0
                  ? Text(
                      '$rank',
                      style: AppText.tiny.copyWith(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: k.muted,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple silhouette in 200 × 300 units.
class _BodyPainter extends CustomPainter {
  _BodyPainter({required this.fill, required this.navel});

  final Color fill;
  final Color navel;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 300);
    final p = Paint()..color = fill;
    canvas.drawCircle(const Offset(100, 30), 20, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(91, 48, 18, 14),
        const Radius.circular(5),
      ),
      p,
    );
    // Torso.
    canvas.drawPath(
      Path()
        ..moveTo(60, 64)
        ..quadraticBezierTo(100, 54, 140, 64)
        ..quadraticBezierTo(146, 118, 144, 172)
        ..quadraticBezierTo(100, 186, 56, 172)
        ..quadraticBezierTo(54, 118, 60, 64)
        ..close(),
      p,
    );
    // Arms.
    canvas.drawPath(
      Path()
        ..moveTo(60, 66)
        ..quadraticBezierTo(46, 72, 42, 96)
        ..lineTo(32, 160)
        ..quadraticBezierTo(31, 168, 39, 169)
        ..lineTo(47, 169)
        ..quadraticBezierTo(50, 130, 64, 100)
        ..close(),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(140, 66)
        ..quadraticBezierTo(154, 72, 158, 96)
        ..lineTo(168, 160)
        ..quadraticBezierTo(169, 168, 161, 169)
        ..lineTo(153, 169)
        ..quadraticBezierTo(150, 130, 136, 100)
        ..close(),
      p,
    );
    // Legs.
    canvas.drawPath(
      Path()
        ..moveTo(58, 170)
        ..quadraticBezierTo(80, 180, 99, 178)
        ..lineTo(96, 292)
        ..lineTo(72, 292)
        ..close(),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(142, 170)
        ..quadraticBezierTo(120, 180, 101, 178)
        ..lineTo(104, 292)
        ..lineTo(128, 292)
        ..close(),
      p,
    );
    canvas.drawCircle(const Offset(100, 144), 2.5, Paint()..color = navel);
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.fill != fill || old.navel != navel;
}
