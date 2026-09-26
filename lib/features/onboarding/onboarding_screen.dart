import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import 'onboarding_controller.dart';
import 'pages/activity_page.dart';
import 'pages/birth_page.dart';
import 'pages/building_page.dart';
import 'pages/body_pages.dart';
import 'pages/diet_page.dart';
import 'pages/dose_page.dart';
import 'pages/focus_page.dart';
import 'pages/frequency_page.dart';
import 'pages/goal_page.dart';
import 'pages/height_page.dart';
import 'pages/intro_pages.dart';
import 'pages/medication_page.dart';
import 'pages/plan_page.dart';
import 'pages/reminders_page.dart';
import 'pages/save_page.dart';
import 'pages/sex_page.dart';
import 'pages/treatment_start_page.dart';
import 'pages/weight_page.dart';
import 'pages/when_page.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  Widget _pageFor(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return const WelcomePage();
      case OnboardingStep.stage:
        return const StagePage();
      case OnboardingStep.medicine:
        return const MedicationPage();
      case OnboardingStep.dose:
        return const DosePage();
      case OnboardingStep.frequency:
        return const FrequencyPage();
      case OnboardingStep.schedule:
        return const WhenPage();
      case OnboardingStep.treatmentStart:
        return const TreatmentStartPage();
      case OnboardingStep.sex:
        return const SexPage();
      case OnboardingStep.birth:
        return const BirthPage();
      case OnboardingStep.height:
        return const HeightPage();
      case OnboardingStep.weight:
        return const WeightPage();
      case OnboardingStep.goal:
        return const GoalPage();
      case OnboardingStep.activity:
        return const ActivityPage();
      case OnboardingStep.diet:
        return const DietPage();
      case OnboardingStep.baseline:
        return const BaselinePage();
      case OnboardingStep.protein:
        return const ProteinPage();
      case OnboardingStep.focus:
        return const FocusPage();
      case OnboardingStep.reminders:
        return const RemindersPage();
      case OnboardingStep.building:
        return const BuildingPage();
      case OnboardingStep.plan:
        return const PlanPage();
      case OnboardingStep.save:
        return const SavePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.current;
      final dark = step == OnboardingStep.welcome;
      return PopScope(
        canPop: controller.page.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.back();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark || context.k.bg == KColors.dark.bg ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
          backgroundColor: dark ? AppColors.hero : context.k.bg,
          body: SafeArea(
            // bottom: Platform.isIOS ? false : true,
            child: Column(
              children: [
                if (!dark) const _StepHeader(),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [for (final s in controller.steps) _pageFor(s)],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      );
    });
  }
}

class _StepHeader extends GetView<OnboardingController> {
  const _StepHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.sp, 8.sp, 22.sp, 6.sp),
      child: Row(
        children: [
          BackCircle(onTap: controller.back, size: 44.sp),
          SizedBox(width: 14.sp),
          Expanded(
            child: Obx(
              () => AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                // Wrap-up screens keep the back button but drop the bar.
                opacity: controller.isWrapUp ? 0 : 1,
                child: _ProgressBar(
                  value: controller.progress,
                  label: 'Step ${controller.stepNumber} of ${controller.stepCount}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One continuous bar that eases to the new value on every step. Works for
/// any number of steps, including steps that are skipped by earlier answers.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final height = 6.sp;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) {
          return Container(
            height: height,
            decoration: BoxDecoration(color: k.border, borderRadius: BorderRadius.circular(height)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  color: k.selectedBorder,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shared layout for a question step: scrollable content and a CTA pinned
/// to the bottom, so long text and large font sizes never overflow.
/// The title and subtitle slide in each time the step is first shown.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    required this.cta,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget cta;

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 15.sp),
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppText.h1.copyWith(fontSize: 30.sp, color: context.k.text)),
              ).enter(motion, dy: 0.12),
              if (subtitle != null) ...[
                SizedBox(height: 10.sp),
                Text(
                  subtitle!,
                  style: AppText.bodyText.copyWith(fontSize: 15.sp, height: 1.45, color: context.k.muted),
                ).enter(motion, delay: 60, dy: 0.12),
              ],
              SizedBox(height: 20.sp),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 12.sp),
          child: cta,
        ),
      ],
    );
  }
}
