import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/system_ui.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/drop_mark.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../legal/legal_sheet.dart';
import 'plus_controller.dart';

/// Kindose Plus paywall (v2, Calm Paper). Free stays free; close is always
/// visible; the billed price is the biggest number on each plan.
class PlusScreen extends GetView<PlusController> {
  const PlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: !controller.fromOnboarding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.close();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: KSystemUi.style(darkBackground: true),
        child: Scaffold(
          backgroundColor: k.bg,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Hero(onClose: controller.close, motion: motion),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.sp, 20.sp, 20.sp, 16.sp),
                      child: Obx(() {
                        final yearly = controller.isYearly;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionLabel('CHOOSE YOUR PLAN'),
                            SizedBox(height: 10.sp),
                            for (final p in PlusController.plans) ...[
                              _PlanTile(
                                plan: p,
                                selected: controller.selected.value == p.id,
                                onTap: () => controller.pick(p.id),
                              ),
                              SizedBox(height: 12.sp),
                            ],
                            _Perks(
                              controller: controller,
                            ).enter(motion, delay: 220, dy: 0.12),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: yearly
                                  ? Padding(
                                      padding: EdgeInsets.only(top: 20.sp),
                                      child: const _TrialTimeline(),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            SizedBox(height: 20.sp),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LinkButton(
                                  label: 'Restore',
                                  onTap: controller.restore,
                                  color: k.muted,
                                ),
                                LinkButton(
                                  label: 'Terms & privacy',
                                  onTap: showLegalSheet,
                                  color: k.muted,
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: k.bg,
                  boxShadow: [
                    BoxShadow(
                      color: k.bg,
                      blurRadius: 24.sp,
                      offset: Offset(0, -10.sp),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 6.sp),
                    child: Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PillButton(
                            label: controller.cta,
                            onPressed: controller.subscribe,
                          ),
                          SizedBox(height: 8.sp),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              controller.fine,
                              key: ValueKey(controller.fine),
                              textAlign: TextAlign.center,
                              style: AppText.small.copyWith(
                                fontSize: 12.sp,
                                height: 1.4,
                                color: k.muted,
                              ),
                            ),
                          ),
                          LinkButton(
                            label: 'Continue with free',
                            onTap: controller.close,
                            color: k.text,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------- hero

class _Hero extends StatelessWidget {
  const _Hero({required this.onClose, required this.motion});

  final VoidCallback onClose;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    Widget drop = DropMark(size: 96.sp);
    if (motion) {
      drop = drop
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: -6.sp,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    Widget sparkle(double size, Color color, int delay) {
      Widget s = CustomPaint(
        size: Size.square(size),
        painter: _SparklePainter(color),
      );
      if (motion) {
        s = s
            .animate(delay: delay.ms, onPlay: (c) => c.repeat(reverse: true))
            .fade(
              begin: 0.2,
              end: 1,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            )
            .scaleXY(
              begin: 0.7,
              end: 1,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            );
      }
      return s;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(22.sp, top + 8.sp, 18.sp, 28.sp),
      decoration: BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.sp)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 96.sp,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      drop,
                      Positioned(
                        right: 2.sp,
                        top: 6.sp,
                        child: sparkle(18.sp, AppColors.lime, 0),
                      ),
                      Positioned(
                        left: 4.sp,
                        top: 22.sp,
                        child: sparkle(11.sp, AppColors.white, 800),
                      ),
                    ],
                  ),
                ),
              ).enter(motion, dy: 0.1),
              const Spacer(),
              CircleIconButton(
                icon: PhosphorIconsBold.x,
                label: 'Close',
                size: 44.sp,
                background: AppColors.white.withValues(alpha: 0.1),
                foreground: AppColors.white,
                onTap: onClose,
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(9.sp),
            ),
            child: Text(
              'KINDOSE PLUS',
              style: AppText.caps.copyWith(
                fontSize: 12.sp,
                letterSpacing: 1,
                color: AppColors.ink,
              ),
            ),
          ).enter(motion, delay: 60, dy: 0.12),
          SizedBox(height: 12.sp),
          Semantics(
            header: true,
            child: Text(
              'Get more from\nevery dose',
              style: AppText.h1.copyWith(
                fontSize: 30.sp,
                height: 1.08,
                color: AppColors.white,
              ),
            ),
          ).enter(motion, delay: 100, dy: 0.12),
          SizedBox(height: 10.sp),
          Text(
            'Your plan, doses, reminders and daily goals stay free. Plus adds the extras.',
            style: AppText.bodyText.copyWith(
              fontSize: 15.sp,
              height: 1.45,
              color: AppColors.heroMuted,
            ),
          ).enter(motion, delay: 150, dy: 0.12),
        ],
      ),
    );
  }
}

/// Four-point star.
class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = w / 2;
    final path = Path()
      ..moveTo(c, 0)
      ..lineTo(c + w * 0.09, c - w * 0.09)
      ..lineTo(w, c)
      ..lineTo(c + w * 0.09, c + w * 0.09)
      ..lineTo(c, w)
      ..lineTo(c - w * 0.09, c + w * 0.09)
      ..lineTo(0, c)
      ..lineTo(c - w * 0.09, c - w * 0.09)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

// --------------------------------------------------------------------- perks

class _Perks extends StatelessWidget {
  const _Perks({required this.controller});

  final PlusController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    const perks = PlusController.perks;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
        border: Border.all(color: k.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < perks.length; i++)
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
              decoration: BoxDecoration(
                border: i == perks.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: k.border)),
              ),
              child: Row(
                children: [
                  ThreeD(perks[i].icon, size: 36.sp),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perks[i].title,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                        SizedBox(height: 1.sp),
                        Text(
                          perks[i].sub,
                          style: AppText.small.copyWith(
                            fontSize: 12.5.sp,
                            color: k.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.isForYou(perks[i])) ...[
                    SizedBox(width: 8.sp),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.sp,
                        vertical: 3.sp,
                      ),
                      decoration: BoxDecoration(
                        color: k.tint,
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Text(
                        'FOR YOU',
                        style: AppText.caps.copyWith(
                          fontSize: 10.5.sp,
                          letterSpacing: 0.4,
                          color: k.tintText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ trial timeline

class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;

    Widget step(Widget dot, String title, String body) => Padding(
      padding: EdgeInsets.symmetric(vertical: 6.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dot,
          SizedBox(width: 14.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w800,
                    color: k.text,
                  ),
                ),
                SizedBox(height: 1.sp),
                Text(
                  body,
                  style: AppText.small.copyWith(
                    fontSize: 13.sp,
                    color: k.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    Widget dot(IconData icon, Color bg, Color fg, {Color? border}) => Container(
      width: 30.sp,
      height: 30.sp,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border, width: 2),
      ),
      child: Icon(icon, size: 15.sp, color: fg),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('HOW THE FREE TRIAL WORKS'),
        SizedBox(height: 10.sp),
        Stack(
          children: [
            // Rail behind the dots: lime for the free part, grey after.
            Positioned(
              left: 13.5.sp,
              top: 20.sp,
              bottom: 20.sp,
              child: Column(
                children: [
                  Expanded(child: Container(width: 3, color: AppColors.lime)),
                  Expanded(child: Container(width: 3, color: k.border)),
                ],
              ),
            ),
            Column(
              children: [
                step(
                  dot(
                    PhosphorIconsBold.lightning,
                    dark ? AppColors.lime : AppColors.ink,
                    dark ? AppColors.ink : AppColors.lime,
                  ),
                  'Today',
                  'Everything in Plus unlocks',
                ),
                step(
                  dot(PhosphorIconsBold.bell, AppColors.lime, AppColors.ink),
                  'Day 5',
                  'We’ll remind you before the trial ends',
                ),
                step(
                  dot(
                    PhosphorIconsBold.calendarDots,
                    k.card,
                    k.muted,
                    border: k.border,
                  ),
                  'Day 7',
                  'Trial ends, \$39.99 for the year. Cancel before and pay nothing.',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- plan tile

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PlusPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final accent = k.selectedBorder;
    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.name}, ${plan.price} ${plan.per}. ${plan.sub}',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 15.sp),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(22.sp),
                border: Border.all(color: selected ? accent : k.card, width: 2),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24.sp,
                    height: 24.sp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: k.card,
                      border: Border.all(
                        color: selected ? accent : k.border,
                        width: selected ? 7.sp : 2,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                        SizedBox(height: 2.sp),
                        Text(
                          plan.sub,
                          style: AppText.small.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: k.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.price,
                        style: AppText.h3.copyWith(
                          fontSize: 20.sp,
                          color: k.text,
                        ),
                      ),
                      Text(
                        plan.per,
                        style: AppText.small.copyWith(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: k.faint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (plan.badge != null)
              Positioned(
                left: 16.sp,
                top: -11.sp,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9.sp,
                    vertical: 3.sp,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(10.sp),
                  ),
                  child: Text(
                    plan.badge!,
                    style: AppText.caps.copyWith(
                      fontSize: 11.sp,
                      letterSpacing: 0.5,
                      color: AppColors.ink,
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
