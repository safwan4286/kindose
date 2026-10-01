import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../resources/images.dart';
import '../../../resources/routes.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/plus/access_service.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';

void _openPlus() {
  Haptics.instance.lightImpact();
  Get.toNamed<void>(Routes.plus);
}

/// "Free week · 5 days left" strip at the top of Today. Turns lime on the
/// last 2 days. Tap opens the paywall.
class FreeWeekStrip extends StatelessWidget {
  const FreeWeekStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final access = Get.find<AccessService>();
    return Obx(() {
      access.endsAt.value;
      access.started.value;
      final left = access.daysLeft;
      final soon = left <= 2;
      final title = switch (left) {
        1 => 'Free week ends today',
        2 => 'Free week ends tomorrow',
        _ => 'Free week · $left days left',
      };
      final bg = soon ? AppColors.lime : AppColors.hero;
      final fg = soon ? AppColors.ink : AppColors.white;
      final sub = soon ? AppColors.ink.withValues(alpha: 0.7) : AppColors.heroMuted;
      return Semantics(
        button: true,
        label: '$title. Everything is open until ${Dates.shortWithDay(access.endsAt.value)}. See Plus',
        excludeSemantics: true,
        child: PressScale(
          onTap: _openPlus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.fromLTRB(14.sp, 12.sp, 12.sp, 12.sp),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18.sp),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.title.copyWith(fontSize: 14.5.sp, color: fg),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                      decoration: BoxDecoration(
                        color: soon ? AppColors.ink : AppColors.lime,
                        borderRadius: BorderRadius.circular(14.sp),
                      ),
                      child: Text(
                        'See Plus',
                        style: AppText.small.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: soon ? AppColors.lime : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.sp),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.sp),
                  child: SizedBox(
                    height: 6.sp,
                    child: Stack(
                      children: [
                        Positioned.fill(child: ColoredBox(color: fg.withValues(alpha: 0.15))),
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: access.progress),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => FractionallySizedBox(
                            widthFactor: v,
                            heightFactor: 1,
                            child: ColoredBox(color: soon ? AppColors.ink : AppColors.lime),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 6.sp),
                Text(
                  'Everything is open until ${Dates.shortWithDay(access.endsAt.value)}',
                  style: AppText.small.copyWith(fontSize: 12.sp, color: sub),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Shown under the dose card once the free week is over.
class WeekEndedCard extends StatelessWidget {
  const WeekEndedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
        border: Border.all(color: k.text, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ThreeD(Img3d.locked, size: 30.sp),
              SizedBox(width: 10.sp),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Your free week has ended',
                    style: AppText.h2.copyWith(fontSize: 18.sp, color: k.text),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Text(
            'Your next dose date, last spot and dose reminder stay free. '
            'Logging, protein, progress and your report need Plus. '
            'Nothing you logged is deleted.',
            style: AppText.small.copyWith(
              fontSize: 13.5.sp,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: k.muted,
            ),
          ),
          SizedBox(height: 14.sp),
          PressScale(
            semanticLabel: 'Continue with Plus',
            onTap: _openPlus,
            child: Container(
              height: 50.sp,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k.text,
                borderRadius: BorderRadius.circular(25.sp),
              ),
              child: Text(
                'Continue with Plus',
                style: AppText.title.copyWith(fontSize: 15.5.sp, color: k.bg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Today card after the free week: blurred, not tappable inside; a tap
/// anywhere opens the paywall.
class LockedCard extends StatelessWidget {
  const LockedCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'Locked. Get Plus to use this card',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openPlus,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.55,
            child: motion
                ? ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

/// Progress and Report tabs after the free week.
class LockedTab extends StatelessWidget {
  const LockedTab({super.key, required this.title, required this.sub, required this.icon});

  final String title;
  final String sub;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SafeArea(
      bottom: false,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28.sp, 24.sp, 28.sp, 140.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThreeD(icon, size: 72.sp),
              SizedBox(height: 16.sp),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.h2.copyWith(fontSize: 24.sp, color: k.text),
                ),
              ),
              SizedBox(height: 8.sp),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: AppText.bodyText.copyWith(fontSize: 15.sp, height: 1.45, color: k.muted),
              ),
              SizedBox(height: 22.sp),
              PressScale(
                semanticLabel: 'Continue with Plus',
                onTap: _openPlus,
                child: Container(
                  height: 54.sp,
                  padding: EdgeInsets.symmetric(horizontal: 28.sp),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: k.text,
                    borderRadius: BorderRadius.circular(27.sp),
                  ),
                  child: Text(
                    'Continue with Plus',
                    style: AppText.title.copyWith(fontSize: 16.sp, color: k.bg),
                  ),
                ),
              ),
              SizedBox(height: 10.sp),
              Text(
                'Your data is safe. Nothing is deleted.',
                style: AppText.small.copyWith(fontSize: 12.5.sp, color: k.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
