import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/system_ui.dart';
import '../../services/theme/theme.dart';
import 'liquid_drop.dart';
import 'splash_controller.dart';

/// Brand moment. Frame one is exactly the native launch image: a lime drop
/// outline centred on ink, 120 pt. A drip forms under the tip and falls,
/// the drop fills with liquid (two waves, a few bubbles), settles with a
/// soft spring, smiles, then lifts as the wordmark wipes in.
/// 2.2 s the first time, 1.5 s once there is a plan; a tap skips it.
///
/// Smoothness: it starts only after the first frame is on screen (that
/// frame matches the native launch image, so the short hold is invisible
/// while start-up work finishes), every stage starts and ends at rest
/// (ease-in-out, no sudden speed), and stages overlap instead of
/// switching hard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Fixed logical pixels (no .sp) on purpose: it must match the 120 pt /
  // 120 dp native launch image exactly, or the drop jumps on hand-off.
  static const double _dropSize = 120;

  /// How far the drop rises at the end to make room for the wordmark.
  static const double _rise = 48;

  final SplashController _controller = Get.find<SplashController>();
  late final AnimationController _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: _controller.returning ? 1500 : 2200),
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
      // Wait for the first frame, then a beat: the app is still busy right
      // after launch, and starting then drops the opening frames.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_anim.isAnimating) _anim.forward();
        });
      });
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Progress of [t] inside [begin]–[end], eased, clamped to 0–1.
  static double _seg(
    double t,
    double begin,
    double end, [
    Curve curve = Curves.linear,
  ]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }

  // ------------------------------------------------------------ timeline
  // 0.00–0.09 drip forms · 0.09–0.21 falls · 0.21–0.64 fills ·
  // 0.62–0.84 swell + face · 0.74–0.95 rise · 0.78–1.00 words.

  static double _drip(double t) {
    if (t >= 0.21) return 0;
    return _seg(t, 0, 0.09, Curves.easeOutCubic);
  }

  static double _dripY(double t) =>
      22 + 56 * _seg(t, 0.09, 0.21, Curves.easeInQuad);

  /// Moves straight away when the drip lands, then slows into full.
  static double _fill(double t) => _seg(t, 0.21, 0.64, Curves.ease);

  /// Waves build after the drip lands, then calm down as it fills.
  static double _wave(double t) {
    if (t < 0.21) return 0;
    final grow = _seg(t, 0.21, 0.31, Curves.easeOut);
    final calm = 1 - _seg(t, 0.42, 0.70, Curves.easeInOut);
    return 4.2 * grow * calm;
  }

  /// One soft swell and a small settle once full. Starts and ends at rest
  /// (no jump in speed), exactly 1 outside.
  static double _pulse(double t) {
    final p = _seg(t, 0.62, 0.84, Curves.easeInOut);
    if (p <= 0 || p >= 1) return 1;
    return 1 + 0.06 * math.sin(p * math.pi * 2) * (1 - p);
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
                // Ease in and out: the drop starts lifting gently instead of
                // jumping to full speed.
                final dropY =
                    -_rise * _seg(t, 0.74, 0.95, Curves.easeInOutCubic);
                final glow = _seg(t, 0.45, 0.85, Curves.easeInOut);
                final word = _seg(t, 0.78, 0.96, Curves.easeOutCubic);
                final tag = _seg(t, 0.86, 1.0, Curves.easeOut);
                final pulse = _pulse(t);

                return SizedBox.expand(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft lime glow that blooms as the drop fills. Fades
                      // through its own colour (no Opacity layer per frame).
                      if (glow > 0)
                        Transform.translate(
                          offset: Offset(0, dropY),
                          child: Container(
                            width: 420.sp,
                            height: 420.sp,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.lime.withValues(alpha: 0.18 * glow),
                                  AppColors.lime.withValues(alpha: 0),
                                ],
                                stops: const [0, 0.62],
                              ),
                            ),
                          ),
                        ),
                      // The drop, centred like the native launch image.
                      Transform.translate(
                        offset: Offset(0, dropY),
                        child: Transform.scale(
                          scale: pulse,
                          child: ExcludeSemantics(
                            child: CustomPaint(
                              size: const Size.square(_dropSize),
                              painter: LiquidDropPainter(
                                drip: _drip(t),
                                dripY: _dripY(t),
                                fill: _fill(t),
                                wave: _wave(t),
                                // About three and a half wave cycles in all.
                                phase: t * math.pi * 7,
                                splash: _seg(t, 0.21, 0.45, Curves.easeOut),
                                bubbles: _seg(t, 0.25, 0.68),
                                shine: _seg(t, 0.64, 0.78, Curves.easeInOut),
                                smile: _seg(t, 0.66, 0.84, Curves.easeInOutCubic),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Wordmark and tagline, just under the drop's final spot.
                      Transform.translate(
                        offset: Offset(0, _dropSize / 2 - _rise),
                        child: Align(
                          alignment: Alignment.center,
                          child: FractionalTranslation(
                            translation: const Offset(0, 0.5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Wipe(
                                  progress: word,
                                  child: Transform.translate(
                                    offset: Offset(0, 10 * (1 - word)),
                                    child: Text(
                                      'kindose',
                                      style: AppText.h1.copyWith(
                                        fontSize: 44.sp,
                                        letterSpacing: -1.2.sp,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6.sp),
                                Opacity(
                                  opacity: tag,
                                  child: Transform.translate(
                                    offset: Offset(0, 6 * (1 - tag)),
                                    child: Text(
                                      'Your GLP-1 companion',
                                      style: AppText.bodyStrong.copyWith(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.heroMuted,
                                      ),
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

/// Reveals [child] left to right with a soft edge.
class _Wipe extends StatelessWidget {
  const _Wipe({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return Opacity(opacity: 0, child: child);
    if (progress >= 1) return child;
    // Edge is 25% wide; slide it from fully left to fully right.
    final edge = progress * 1.25;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: const [Colors.white, Colors.transparent],
        stops: [(edge - 0.25).clamp(0.0, 1.0), edge.clamp(0.0, 1.0)],
      ).createShader(rect),
      child: child,
    );
  }
}
