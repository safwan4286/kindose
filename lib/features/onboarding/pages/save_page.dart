import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:kindose/widgets/safe_bottom.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_ruler.dart';
import '../../../widgets/social_button.dart';
import '../onboarding_controller.dart';

/// Wrap-up 4: "Save your plan". Signing in is required (no guest mode):
/// the plan lives in the account and syncs by itself.
class SavePage extends GetView<OnboardingController> {
  const SavePage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    // Apple's button only on iPhone/iPad; Android gets Google alone.
    final ios = defaultTargetPlatform == TargetPlatform.iOS;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24.sp, 10.sp, 24.sp, 16.sp),
            children: [
              Center(
                child: _SavedDataHero(controller: controller, motion: motion),
              ).enter(motion, dy: 0.1),
              SizedBox(height: 30.sp),
              Semantics(
                header: true,
                child: Text(
                  'Save your plan',
                  textAlign: TextAlign.center,
                  style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text),
                ),
              ).enter(motion, delay: 120, dy: 0.12),
              SizedBox(height: 10.sp),
              Text(
                'Your plan, doses and progress live in your Kindose account, safe on any phone.',
                textAlign: TextAlign.center,
                style: AppText.bodyText.copyWith(
                  fontSize: 14.5.sp,
                  height: 1.45,
                  color: k.muted,
                ),
              ).enter(motion, delay: 170, dy: 0.12),
              SizedBox(height: 20.sp),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.sp),
                child: const Column(
                  children: [
                    _Benefit('Syncs by itself, even after offline'),
                    _Benefit('New phone? Just sign in'),
                    _Benefit('No password to remember'),
                  ],
                ),
              ).enter(motion, delay: 240, dy: 0.12),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 8.sp),
          child: Obx(() {
            final busy = controller.signingIn.value;
            final saving = controller.saving.value;
            final email = controller.signedInEmail;
            if (controller.alreadySignedIn) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Signed in as ${email ?? 'your account'}',
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: k.muted,
                    ),
                  ),
                  SizedBox(height: 10.sp),
                  KBottomPadding(
                    child: PillButton(
                      label: 'Continue',
                      busy: saving,
                      onPressed: saving ? null : controller.continueSignedIn,
                    ),
                  ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ios) ...[
                  SocialButton(
                    provider: SocialProvider.apple,
                    busy: busy == SocialProvider.apple,
                    onPressed: busy != null || saving
                        ? null
                        : () => controller.signInWith(SocialProvider.apple),
                  ),
                  SizedBox(height: 10.sp),
                ],
                SocialButton(
                  provider: SocialProvider.google,
                  busy: busy == SocialProvider.google,
                  onPressed: busy != null || saving
                      ? null
                      : () => controller.signInWith(SocialProvider.google),
                ),
                SizedBox(height: 12.sp),
                KBottomPadding(
                  child: Text(
                    'Only your name and email are shared with Kindose.\nWe never sell your data.',
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(
                      fontSize: 12.sp,
                      height: 1.45,
                      color: k.faint,
                    ),
                  ),
                ),
              ],
            );
          }).enter(motion, delay: 320, dy: 0.12),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.sp),
      child: Row(
        children: [
          Container(
            width: 24.sp,
            height: 24.sp,
            decoration: BoxDecoration(
              color: dark ? AppColors.lime : AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsBold.check,
              size: 14.sp,
              color: dark ? AppColors.ink : AppColors.lime,
            ),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Text(
              text,
              style: AppText.bodyStrong.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: k.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A floating card of what gets saved, built from the user's own answers,
/// with a lime shield popping in on its corner.
class _SavedDataHero extends StatelessWidget {
  const _SavedDataHero({required this.controller, required this.motion});

  final OnboardingController controller;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final kg = controller.weightKg.value;
    final weight = controller.useKg.value
        ? '${kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1)} kg'
        : '${(kg * Imperial.lbPerKg).round()} lb';
    final start = controller.treatmentStart.value;
    final week = start == null
        ? 'Week 1'
        : 'Week ${OnboardingController.weekNumber(start)}';

    Widget row(
      IconData icon,
      Color tile,
      Color ink,
      String title,
      String value, {
      bool last = false,
    }) => Container(
      padding: EdgeInsets.symmetric(vertical: 9.sp),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: k.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 30.sp,
            height: 30.sp,
            decoration: BoxDecoration(
              color: tile,
              borderRadius: BorderRadius.circular(10.sp),
            ),
            child: Icon(icon, size: 16.sp, color: ink),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyStrong.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: k.text,
              ),
            ),
          ),
          Text(
            value,
            style: AppText.small.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: k.faint,
            ),
          ),
        ],
      ),
    );

    Widget stack = SizedBox(
      width: 270.sp,
      height: 176.sp,
      child: Stack(
        children: [
          Positioned(
            left: 22.sp,
            right: 22.sp,
            top: 0,
            height: 40.sp,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: k.border,
                borderRadius: BorderRadius.circular(18.sp),
              ),
            ),
          ),
          Positioned(
            left: 10.sp,
            right: 10.sp,
            top: 10.sp,
            height: 40.sp,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: k.cardAlt,
                borderRadius: BorderRadius.circular(18.sp),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 22.sp,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(22.sp),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.10),
                    blurRadius: 30.sp,
                    offset: Offset(0, 14.sp),
                  ),
                ],
              ),
              child: Column(
                children: [
                  row(
                    PhosphorIconsBold.syringe,
                    AppColors.limeSoft,
                    AppColors.ink,
                    'Doses',
                    week,
                  ),
                  row(
                    PhosphorIconsBold.trendDown,
                    AppColors.tangerineSoft,
                    AppColors.tangerineText,
                    'Weight trend',
                    weight,
                  ),
                  row(
                    PhosphorIconsBold.fileText,
                    AppColors.aquaSoft,
                    AppColors.aquaText,
                    'Plan & reports',
                    'Ready',
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (motion) {
      stack = stack
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: -5.sp,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    Widget badge = Container(
      width: 58.sp,
      height: 58.sp,
      decoration: BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
        border: Border.all(color: k.bg, width: 4),
      ),
      child: Icon(
        PhosphorIconsBold.shieldCheck,
        size: 28.sp,
        color: AppColors.ink,
      ),
    );
    if (motion) {
      badge = badge
          .animate(delay: 700.ms)
          .fadeIn(duration: 200.ms)
          .scaleXY(
            begin: 0.3,
            end: 1,
            duration: 500.ms,
            curve: Curves.easeOutBack,
          )
          .rotate(begin: -0.03, end: 0, duration: 500.ms);
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: 270.sp + 32.sp,
        height: 184.sp,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: 16.sp, top: 8.sp, child: stack),
            Positioned(right: 0, top: 0, child: badge),
          ],
        ),
      ),
    );
  }
}
