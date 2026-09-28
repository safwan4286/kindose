import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fade + slide-up entrance used across onboarding. Pass `motion: false`
/// (from `MediaQuery.disableAnimationsOf`) to show the widget as-is.
extension Entrance on Widget {
  Widget enter(bool motion, {int delay = 0, double dy = 0.18}) {
    if (!motion) return this;
    return animate(delay: delay.ms)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(
          begin: dy,
          end: 0,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
