import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/drop_mark.dart';
import 'splash_controller.dart';
import '../../services/theme/system_ui.dart';

/// Brand moment. Frame one is exactly the native splash (lime drop centred
/// on ink, no smile, same 120 pt size), so the hand-off has no jump. The
/// drop crouches, hops, lands with a squash and ripple, smiles, then rises
/// as the wordmark fades in. 1.7 s the first time, 1.1 s once there is a
/// plan; a tap skips it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Kept as fixed logical pixels (no .sp) on purpose: it must match the
  // 120 pt / 120 dp native splash image exactly, or the drop jumps on hand-off.
  static const double _dropSize = 120;

  /// How far the drop rises at the end to make room for the wordmark.
  static const double _rise = 48;

  /// Height of the hop, above the resting spot.
  static const double _hopHeight = 34;

  final SplashController _controller = Get.find<SplashController>();
  late final AnimationController _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: _controller.returning ? 1100 : 1700),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) _controller.goNext();
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = 1;
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        _controller.goNext,
      );
    } else {
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Progress of [t] inside [begin]–[end], eased, clamped to 0–1.
  double _seg(
    double t,
    double begin,
    double end, [
    Curve curve = Curves.linear,
  ]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }

  static double _lerp(double a, double b, double p) => a + (b - a) * p;

  /// Hop: up and back down between 0.10 and 0.38 (0 before and after).
  double _hop(double t) {
    if (t <= 0.10 || t >= 0.38) return 0;
    final p = (t - 0.10) / 0.28;
    // Ease out going up, ease in coming down, like a thrown ball.
    final up = p < 0.5
        ? Curves.easeOut.transform(p * 2)
        : 1 - Curves.easeIn.transform((p - 0.5) * 2);
    return -_hopHeight * up;
  }

  /// (scaleX, scaleY): crouch → stretch in the air → squash on landing →
  /// small overshoot → rest. Exactly (1, 1) at the start and the end.
  Offset _squash(double t) {
    if (t < 0.10) {
      final p = _seg(t, 0, 0.10, Curves.easeOut);
      return Offset(_lerp(1, 1.06, p), _lerp(1, 0.92, p));
    }
    if (t < 0.24) {
      final p = _seg(t, 0.10, 0.24, Curves.easeOut);
      return Offset(_lerp(1.06, 0.95, p), _lerp(0.92, 1.07, p));
    }
    if (t < 0.38) {
      final p = _seg(t, 0.24, 0.38, Curves.easeIn);
      return Offset(_lerp(0.95, 1, p), _lerp(1.07, 1, p));
    }
    if (t < 0.46) {
      final p = _seg(t, 0.38, 0.46, Curves.easeOut);
      return Offset(_lerp(1, 1.12, p), _lerp(1, 0.86, p));
    }
    if (t < 0.55) {
      final p = _seg(t, 0.46, 0.55, Curves.easeInOut);
      return Offset(_lerp(1.12, 0.97, p), _lerp(0.86, 1.04, p));
    }
    final p = _seg(t, 0.55, 0.62, Curves.easeOut);
    return Offset(_lerp(0.97, 1, p), _lerp(1.04, 1, p));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: KSystemUi.style(darkBackground: true),
      child: Scaffold(
        backgroundColor: AppColors.hero,
        // A tap skips the animation (goNext is safe to call twice).
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _controller.goNext,
          child: Semantics(
            label: 'Kindose, your GLP-1 companion',
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final t = _anim.value;
                final squash = _squash(t);
                final dropY =
                    _hop(t) - _rise * _seg(t, 0.62, 0.86, Curves.easeOutCubic);
                final word = _seg(t, 0.66, 0.88, Curves.easeOut);
                final tag = _seg(t, 0.74, 0.95, Curves.easeOut);
                final glow = _seg(t, 0.38, 0.75, Curves.easeOut);

                return SizedBox.expand(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft lime glow behind the drop.
                      Transform.translate(
                        offset: Offset(0, dropY),
                        child: Opacity(
                          opacity: glow,
                          child: Container(
                            width: 420.sp,
                            height: 420.sp,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.lime.withValues(alpha: 0.16),
                                  AppColors.lime.withValues(alpha: 0),
                                ],
                                stops: const [0, 0.62],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // The drop, centred like the native splash.
                      Transform.translate(
                        offset: Offset(0, dropY),
                        child: Transform(
                          alignment: const Alignment(0, 0.68),
                          transform: Matrix4.diagonal3Values(
                            squash.dx,
                            squash.dy,
                            1,
                          ),
                          child: DropMark(
                            size: _dropSize,
                            smile: _seg(t, 0.44, 0.62, Curves.easeOut),
                            shine: _seg(t, 0.56, 0.70),
                            ripple: _seg(t, 0.38, 0.72),
                          ),
                        ),
                      ),
                      // Wordmark and tagline, placed just under the drop's final spot.
                      Transform.translate(
                        offset: Offset(
                          0,
                          _dropSize / 2 - _rise + 12 * (1 - word),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: FractionalTranslation(
                            translation: const Offset(0, 0.5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: word,
                                  child: Text(
                                    'kindose',
                                    style: AppText.h1.copyWith(
                                      fontSize: 44.sp,
                                      letterSpacing: -1.2.sp,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6.sp),
                                Opacity(
                                  opacity: tag,
                                  child: Text(
                                    'Your GLP-1 companion',
                                    style: AppText.bodyStrong.copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.heroMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
