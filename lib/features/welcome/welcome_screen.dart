import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/drop_mark.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/painters.dart';
import 'welcome_controller.dart';

/// Screen 1 · Welcome (design option B: phone preview).
///
/// Motion: everything enters in a short stagger (≈0.8 s total), the phone
/// floats gently, water glasses fill one by one and the protein ring sweeps
/// in. All of it is skipped when the system "reduce motion" setting is on.
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
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: k.bg,
        body: SafeArea(
          bottom: Platform.isIOS ? false : true,
          child: LayoutBuilder(
            builder: (context, box) {
              // On short phones (or big accessibility text) drop the benefit
              // list so the buttons never get pushed off screen.
              final compact = box.maxHeight < 640.sp;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.sp),
                    const _Brand().enter(motion, dy: 0),
                    Expanded(child: _PhonePreview(motion: motion)),
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
                    if (!compact) ...[
                      SizedBox(height: 15.sp),
                      for (var i = 0; i < _benefits.length; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.sp),
                          child: _Benefit(_benefits[i], dark: dark),
                        ).enter(motion, delay: 420 + i * 80, dy: 0.4),
                    ],
                    SizedBox(height: compact ? 15.sp : 10.sp),
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
                    _LegalLine(onTap: controller.openLegal)
                        .enter(motion, delay: 780),
                    SizedBox(height: 10.sp),
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
      label: 'Your GLP-1\njourney, handled.',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'Your GLP-1\njourney, '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _Highlighter(text: 'handled.', style: style),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lime marker stroke behind a word, like a highlighter pen.
class _Highlighter extends StatelessWidget {
  const _Highlighter({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final fs = style.fontSize ?? 38;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -2.sp,
          right: -2.sp,
          bottom: fs * 0.1,
          height: fs * 0.36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(3.sp),
            ),
          ),
        ),
        Text(text, style: style.copyWith(color: AppColors.ink)),
      ],
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
  const _LegalLine({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final base = AppText.tiny.copyWith(
      fontSize: 11.5.sp,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: k.faint,
    );
    Widget link(String t) => GestureDetector(
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
    );
    return Semantics(
      button: true,
      label: 'Terms and Privacy Policy',
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
                child: link('Terms'),
              ),
              const TextSpan(text: ' and '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: link('Privacy Policy'),
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

/// A tilted phone showing the Today screen, fading into the page.
class _PhonePreview extends StatelessWidget {
  const _PhonePreview({required this.motion});

  final bool motion;

  @override
  Widget build(BuildContext context) {
    final bg = context.k.bg;
    final phoneW = 250.sp;
    final phoneH = 330.sp;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final fitsWhole = box.maxHeight >= phoneH + 40.sp;
          Widget phone = Transform.rotate(
            angle: -3 * math.pi / 180,
            child: _Phone(width: phoneW, height: phoneH, motion: motion),
          );
          if (motion) {
            phone = phone
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: -6.sp,
                  duration: 2800.ms,
                  curve: Curves.easeInOut,
                );
            phone = phone
                .animate(delay: 100.ms)
                .fadeIn(duration: 500.ms)
                .slideY(
                  begin: 0.12,
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
          return ClipRect(
            child: Stack(
              children: [
                Align(
                  alignment: fitsWhole ? Alignment.center : Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: fitsWhole ? 0 : 20.sp),
                    child: OverflowBox(
                      maxHeight: phoneH + 40.sp,
                      alignment: Alignment.topCenter,
                      child: phone,
                    ),
                  ),
                ),
                // Fade the bottom of the phone into the page.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 64.sp,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [bg.withValues(alpha: 0), bg],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({
    required this.width,
    required this.height,
    required this.motion,
  });

  final double width;
  final double height;
  final bool motion;

  // The preview always shows the light app, whatever the system theme.
  static const Color _paper = Color(0xFFF6F5F1);
  static const Color _muted = Color(0xFF6B6A76);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(40.sp),
        border: dark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              )
            : null,
        // boxShadow: [
        //   BoxShadow(color: AppColors.ink.withValues(alpha: 0.22), blurRadius: 50.sp, offset: Offset(0, 24.sp)),
        // ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.sp),
        child: ColoredBox(
          color: _paper,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.sp, 14.sp, 14.sp, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 70.sp,
                    height: 18.sp,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(10.sp),
                    ),
                  ),
                ),
                SizedBox(height: 10.sp),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${Dates.weekdayName(now.weekday)}, ${now.day} ${Dates.monthShort(now.month)}',
                            style: AppText.tiny.copyWith(
                              fontSize: 8.sp,
                              color: _muted,
                            ),
                          ),
                          Text(
                            Dates.greeting(now),
                            style: AppText.h3.copyWith(
                              fontSize: 16.sp,
                              letterSpacing: -0.4.sp,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20.sp,
                      height: 20.sp,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(6.sp),
                      ),
                      alignment: Alignment.center,
                      child: DropMark(size: 20.sp),
                    ),
                  ],
                ),
                SizedBox(height: 9.sp),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.sp,
                    vertical: 11.sp,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.hero,
                    borderRadius: BorderRadius.circular(16.sp),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT DOSE · MOUNJARO 2.5 MG',
                        style: AppText.caps.copyWith(
                          fontSize: 7.sp,
                          letterSpacing: 0.8.sp,
                          color: AppColors.heroMuted,
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        '2d 14h',
                        style: AppText.number(
                          28.sp,
                        ).copyWith(color: AppColors.lime, letterSpacing: -1.sp),
                      ),
                      SizedBox(height: 5.sp),
                      Text(
                        'Sunday · 9:00 AM · left belly',
                        style: AppText.tiny.copyWith(
                          fontSize: 8.sp,
                          color: const Color(0xFFE8E7F5),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 7.sp),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _MiniProtein()),
                    SizedBox(width: 7.sp),
                    Expanded(child: _MiniWater(motion: motion)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniProtein extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(9.sp),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.sp),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Protein',
              style: AppText.tiny.copyWith(
                fontSize: 8.sp,
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 4.sp),
          ProgressRing(
            value: 86 / 110,
            color: AppColors.tangerine,
            track: AppColors.tangerineSoft,
            size: 50.sp,
            stroke: 6.sp,
            child: ThreeD(Img3d.egg, size: 20.sp),
          ),
          SizedBox(height: 4.sp),
          Text(
            '86 / 110 g',
            style: AppText.tiny.copyWith(
              fontSize: 8.sp,
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniWater extends StatelessWidget {
  const _MiniWater({required this.motion});

  final bool motion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(9.sp),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Water',
            style: AppText.tiny.copyWith(
              fontSize: 8.sp,
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.sp),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '1.8 ',
                  style: AppText.number(15.sp).copyWith(color: AppColors.ink),
                ),
                TextSpan(
                  text: '/ 2.5 L',
                  style: AppText.tiny.copyWith(
                    fontSize: 8.sp,
                    color: const Color(0xFF6B6A76),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.sp),
          for (var row = 0; row < 2; row++) ...[
            if (row == 1) SizedBox(height: 3.sp),
            Row(
              children: [
                for (var i = row * 5; i < row * 5 + 5; i++) ...[
                  if (i > row * 5) SizedBox(width: 3.sp),
                  Expanded(
                    child: _Glass(filled: i < 7, index: i, motion: motion),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.filled,
    required this.index,
    required this.motion,
  });

  final bool filled;
  final int index;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final glass = Container(
      height: 18.sp,
      decoration: BoxDecoration(
        color: filled ? AppColors.aqua : AppColors.white,
        border: Border.all(
          color: filled ? AppColors.aqua : const Color(0xFFCFE6F3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(4.sp),
          bottom: Radius.circular(6.sp),
        ),
      ),
    );
    if (!motion || !filled) return glass;
    // Glasses fill one after another once the phone has landed.
    return glass
        .animate(delay: (700 + index * 70).ms)
        .fadeIn(duration: 220.ms)
        .scaleY(
          begin: 0.3,
          end: 1,
          alignment: Alignment.bottomCenter,
          duration: 260.ms,
          curve: Curves.easeOutBack,
        );
  }
}
