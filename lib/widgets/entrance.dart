import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fade + slide-up entrance used across the app. Pass `motion: false`
/// (from `MediaQuery.disableAnimationsOf`) to show the widget as-is.
///
/// It plays only when a screen first appears. Lists rebuild items that
/// scroll back into view; those show straight away instead of fading in
/// again (which looked like a flicker).
extension Entrance on Widget {
  Widget enter(bool motion, {int delay = 0, double dy = 0.18}) {
    if (!motion) return this;
    return _Entrance(delay: delay, dy: dy, child: this);
  }
}

/// When each vertical list first showed an entrance item.
final Expando<DateTime> _firstSeen = Expando<DateTime>('entranceFirstSeen');

/// Items built this long after their list first appeared are treated as
/// "scrolled back into view" and skip the animation.
const Duration _window = Duration(milliseconds: 900);

class _Entrance extends StatefulWidget {
  const _Entrance({required this.delay, required this.dy, required this.child});

  final int delay;
  final double dy;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> {
  bool? _play;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play ??= _shouldPlay();
  }

  bool _shouldPlay() {
    // Horizontal scrollers (onboarding PageView) don't count: each page
    // still animates the first time it is shown.
    final list = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (list == null) return true;

    final now = DateTime.now();
    final first = _firstSeen[list] ??= now;
    if (now.difference(first) > _window) return false;

    // Already scrolled: this item is coming back into view.
    final position = list.position;
    if (position.hasPixels && position.pixels.abs() > 1) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_play != true) return widget.child;
    return widget.child
        .animate(delay: widget.delay.ms)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(
          begin: widget.dy,
          end: 0,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
