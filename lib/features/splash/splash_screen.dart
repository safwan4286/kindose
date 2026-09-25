import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/drop_mark.dart';
import 'splash_controller.dart';

/// 1.3 s brand moment. Starts exactly where the native splash leaves off
/// (lime drop centred on ink, no smile), so the hand-off has no jump:
/// the drop hops, lands with a squash and ripple, smiles, then rises as the
/// wordmark fades in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Kept as fixed logical pixels (no .sp) on purpose: it must match the
  // 120 pt / 120 dp native splash image exactly, or the drop jumps on hand-off.
  static const double _dropSize = 120;

  /// How far the drop rises at the end to make room for the wordmark.
  static const double _rise = 48;

  final SplashController _controller = Get.find<SplashController>();
  late final AnimationController _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))
      ..addStatusListener((s) {
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
      Future<void>.delayed(const Duration(milliseconds: 700), _controller.goNext);
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
  double _seg(double t, double begin, double end, [Curve curve = Curves.linear]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }

  // double _hop(double t) {
  //   if (t < 0.12) return -18 * _seg(t, 0, 0.12, Curves.easeOut);
  //   return -18 * (1 - _seg(t, 0.12, 0.30, Curves.easeIn));
  // }

  /// How far above the resting spot the drop starts (frame 1 in your ref).
  /// Tune this to match wherever your native splash places the drop.
  static const double _dropStartY = -150;

  double _fall(double t) {
    if (t < 0.30) {
      final p = _seg(t, 0, 0.30, Curves.easeIn); // accelerating, gravity-like
      return _dropStartY * (1 - p);
    }
    return 0;
  }

  Offset _squash(double t) {
    // (scaleX, scaleY) through land → squash → overshoot → rest.
    if (t < 0.30) return const Offset(1, 1);
    if (t < 0.40) {
      final p = _seg(t, 0.30, 0.40, Curves.easeOut);
      return Offset(1 + 0.12 * p, 1 - 0.14 * p);
    }
    if (t < 0.50) {
      final p = _seg(t, 0.40, 0.50, Curves.easeInOut);
      return Offset(1.12 - 0.15 * p, 0.86 + 0.18 * p);
    }
    final p = _seg(t, 0.50, 0.58, Curves.easeOut);
    return Offset(0.97 + 0.03 * p, 1.04 - 0.04 * p);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.hero,
        body: Semantics(
          label: 'Kindose, your GLP-1 companion',
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final t = _anim.value;
              final squash = _squash(t);
              // final dropY = _hop(t) - _rise * _seg(t, 0.58, 0.85, Curves.easeOutCubic);
              final dropY = _fall(t) - _rise * _seg(t, 0.58, 0.85, Curves.easeOutCubic);
              final word = _seg(t, 0.62, 0.86, Curves.easeOut);
              final tag = _seg(t, 0.70, 0.92, Curves.easeOut);
              final glow = _seg(t, 0.30, 0.70, Curves.easeOut);

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
                      transform: Matrix4.diagonal3Values(squash.dx, squash.dy, 1),
                      child: DropMark(
                        size: _dropSize,
                        smile: _seg(t, 0.36, 0.58, Curves.easeOut),
                        shine: _seg(t, 0.54, 0.70),
                        ripple: _seg(t, 0.30, 0.62),
                      ),
                    ),
                  ),
                  // Wordmark and tagline, placed just under the drop's final spot.
                  Transform.translate(
                    offset: Offset(0, _dropSize / 2 - _rise + 12 * (1 - word)),
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
    );
  }
}
