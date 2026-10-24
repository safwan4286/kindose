import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/drop_mark.dart';
import 'widgets/demo_video.dart';
import 'welcome_controller.dart';
import '../../widgets/safe_bottom.dart';
import '../../services/theme/system_ui.dart';

/// Screen 1 · Welcome (design option B: phone preview).
///
/// Motion: everything enters in a short stagger (≈0.8 s total), the phone
/// floats gently and plays a looping screen recording of the app (see
/// widgets/demo_video.dart). With "reduce motion" on, nothing moves and the
/// phone shows a still.
/// Haptics: medium on "Get started", light on sign in, selection on links.
class WelcomeScreen extends GetView<WelcomeController> {
  const WelcomeScreen({super.key});

  static const List<String> _benefits = [
    'Never miss a dose, with site rotation',
    'Protect your muscle with a daily protein goal',
    'A clean report for your doctor',
  ];

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: KSystemUi.style(darkBackground: dark),
      child: Scaffold(
        backgroundColor: k.bg,
        body: KSafeArea(
          child: DemoVideo(
            builder: (context, video) => LayoutBuilder(
              builder: (context, box) {
                // The phone gets the room: the benefit list (the demo shows
                // the same) only stays on tall screens, and short phones or
                // big accessibility text use the tighter headline.
                final compact = box.maxHeight < 640.sp;
                final benefits = box.maxHeight >= 840.sp;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.sp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.sp),
                      const _Brand().enter(motion, dy: 0),
                      SizedBox(height: 12.sp),
                      Expanded(
                        child: _PhonePreview(motion: motion, video: video),
                      ),
                      SizedBox(height: 8.sp),
                      _Headline(compact: compact).enter(motion, delay: 250),
                      SizedBox(height: 10.sp),
                      Text(
                        'Doses, protein, water and how you feel, in one calm app built around your shot day.',
                        style: AppText.bodyText.copyWith(
                          fontSize: 15.sp,
                          height: 1.5,
                          color: k.muted,
                        ),
                      ).enter(motion, delay: 330),
                      if (benefits) ...[
                        SizedBox(height: 15.sp),
                        for (var i = 0; i < _benefits.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.sp),
                            child: _Benefit(_benefits[i], dark: dark),
                          ).enter(motion, delay: 420 + i * 80, dy: 0.4),
                      ],
                      SizedBox(height: benefits ? 10.sp : 15.sp),
                      PillButton(
                        label: 'Get started',
                        onPressed: controller.getStarted,
                      ).enter(motion, delay: 640),
                      SizedBox(
                        width: Get.width,
                        child: LinkButton(
                          label: 'I already have an account',
                          onTap: controller.signIn,
                          color: k.text,
                        ).enter(motion, delay: 720),
                      ),
                      KBottomPadding(
                        child: _LegalLine(
                          onTerms: controller.openTerms,
                          onPrivacy: controller.openPrivacy,
                        ).enter(motion, delay: 780),
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

/// Entrance helper: fade + slide up, skipped when motion is reduced.
extension _Enter on Widget {
  Widget enter(bool motion, {int delay = 0, double dy = 0.18}) {
    if (!motion) return this;
    return animate(delay: delay.ms)
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(
          begin: dy,
          end: 0,
          duration: 520.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Kindose',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 30.sp,
            height: 30.sp,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(9.sp),
            ),
            alignment: Alignment.center,
            child: DropMark(size: 30.sp, shine: 1, smile: 1),
          ),
          SizedBox(width: 9.sp),
          Text(
            'kindose',
            style: AppText.h2.copyWith(
              fontSize: 21.sp,
              letterSpacing: -0.5.sp,
              color: context.k.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = (compact ? 32 : 34).sp;
    final style = AppText.h1.copyWith(
      fontSize: size,
      height: 1.04,
      letterSpacing: -1.3.sp,
      color: context.k.text,
    );
    return Semantics(
      header: true,
      child: Text('Your GLP-1\njourney, handled.', style: style),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.text, {required this.dark});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.sp,
          height: 20.sp,
          margin: EdgeInsets.only(top: 1.sp),
          decoration: BoxDecoration(
            color: dark ? AppColors.lime : AppColors.ink,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: PhosphorIcon(
            PhosphorIconsBold.check,
            size: 12.sp,
            color: dark ? AppColors.ink : AppColors.lime,
          ),
        ),
        SizedBox(width: 10.sp),
        Expanded(
          child: Text(
            text,
            style: AppText.bodyStrong.copyWith(
              fontSize: 14.sp,
              color: context.k.textSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalLine extends StatelessWidget {
  const _LegalLine({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final base = AppText.tiny.copyWith(
      fontSize: 11.5.sp,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: k.faint,
    );
    // Each link opens its own page.
    Widget link(String t, VoidCallback onTap) => Semantics(
      link: true,
      label: t,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          t,
          style: base.copyWith(
            color: k.text,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: k.text,
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      child: SizedBox(
        width: double.infinity,
        child: Text.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(
                text: "By continuing you confirm you're 18+ and agree to the ",
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: link('Terms', onTerms),
              ),
              const TextSpan(text: ' and '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: link('Privacy Policy', onPrivacy),
              ),
              const TextSpan(text: ". Kindose doesn't give medical advice."),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A phone playing the demo clip: a real phone's shape, whole,
/// as big as the room allows.
class _PhonePreview extends StatelessWidget {
  const _PhonePreview({required this.motion, required this.video});

  final bool motion;
  final VideoPlayerController? video;

  @override
  Widget build(BuildContext context) {
    // Its own layer: the video repaints often, the page doesn't.
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            // Fit the height (with room for the float), keep the screen's
            // own proportions.
            final h = math.max(0.0, box.maxHeight - 18.sp);
            final w = math.min(
              _Phone.widthFor(h),
              math.min(box.maxWidth * 0.8, 260.sp),
            );
            Widget phone = _Phone(
              width: w,
              screen: DemoScreen(video: video),
            );
            if (motion) {
              phone = phone
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -5.sp,
                    duration: 2800.ms,
                    curve: Curves.easeInOut,
                  );
              phone = phone
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 650.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .scaleXY(
                    begin: 0.96,
                    end: 1,
                    duration: 650.ms,
                    curve: Curves.easeOutCubic,
                  );
            }
            return Center(child: phone);
          },
        ),
      ),
    );
  }
}

/// An iPhone-shaped frame: thin ink bezel, rounded screen, the demo on it
/// and the island on top (the recording has none; it's hardware).
/// Proportions follow a 402-point-wide phone.
class _Phone extends StatelessWidget {
  const _Phone({required this.width, required this.screen});

  final double width;
  final Widget screen;

  /// Bezel as a share of the phone's width.
  static const double _bezel = 0.03;

  static double heightFor(double width) {
    final b = width * _bezel;
    return (width - b * 2) / DemoVideo.aspect + b * 2;
  }

  static double widthFor(double height) => height / heightFor(1);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final b = width * _bezel;
    final inner = width - b * 2;
    final u = inner / 402;
    return Container(
      width: width,
      height: heightFor(width),
      padding: EdgeInsets.all(b),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(55 * u + b),
        border: dark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.5,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(55 * u),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: screen),
            Positioned(
              top: 11 * u,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 125 * u,
                  height: 37 * u,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(19 * u),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
