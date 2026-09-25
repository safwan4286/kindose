import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../resources/colors.dart';
import '../../services/theme/theme.dart';
import '../../widgets/k_widgets.dart';
import 'onboarding_controller.dart';
import 'pages/body_pages.dart';
import 'pages/intro_pages.dart';
import 'pages/medicine_pages.dart';
import 'pages/plan_page.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  Widget _pageFor(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return const WelcomePage();
      case OnboardingStep.stage:
        return const StagePage();
      case OnboardingStep.medicine:
        return const MedicinePage();
      case OnboardingStep.dose:
        return const DosePage();
      case OnboardingStep.baseline:
        return const BaselinePage();
      case OnboardingStep.protein:
        return const ProteinPage();
      case OnboardingStep.focus:
        return const FocusPage();
      case OnboardingStep.plan:
        return const PlanPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.current;
      final dark = step == OnboardingStep.welcome || step == OnboardingStep.plan;
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
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: Obx(() {
        final n = controller.stepNumber;
        final total = controller.stepCount;
        return Row(
          children: [
            BackCircle(onTap: controller.back),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                label: 'Step $n of $total',
                child: Row(
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < n ? AppColors.violet : k.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ExcludeSemantics(
              child: Text('$n/$total', style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }
}

/// Shared layout for a question step: scrollable content and a CTA pinned
/// to the bottom, so long text and large font sizes never overflow.
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppText.h1.copyWith(fontSize: 32)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: AppText.bodyText.copyWith(fontSize: 16, color: context.k.muted)),
              ],
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: cta,
        ),
      ],
    );
  }
}
