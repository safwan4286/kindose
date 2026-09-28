import 'package:flutter/material.dart';

import '../../../resources/colors.dart';
import '../../../widgets/filling_drop.dart';

/// The Kindose drop filled with water: the level eases to [fill] and the
/// surface keeps a slow wave (still when reduce-motion is on).
class WaterDrop extends StatefulWidget {
  const WaterDrop({
    super.key,
    required this.size,
    required this.fill,
    this.animate = true,
  });

  final double size;

  /// 0–1 of the day's goal.
  final double fill;
  final bool animate;

  @override
  State<WaterDrop> createState() => _WaterDropState();
}

class _WaterDropState extends State<WaterDrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _wave.repeat();
  }

  @override
  void didUpdateWidget(WaterDrop old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_wave.isAnimating) _wave.repeat();
    if (!widget.animate && _wave.isAnimating) _wave.stop();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.fill.clamp(0.0, 1.0)),
        duration: Duration(milliseconds: widget.animate ? 700 : 0),
        curve: Curves.easeOutCubic,
        builder: (context, level, _) => AnimatedBuilder(
          animation: _wave,
          builder: (context, _) => FillingDrop(
            size: widget.size,
            fill: level,
            wave: _wave.value,
            shine: 1,
            color: AppColors.aqua,
          ),
        ),
      ),
    );
  }
}
