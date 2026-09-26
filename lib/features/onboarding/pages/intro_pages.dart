import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../resources/images.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_widgets.dart';
import '../../legal/legal_sheet.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_footer.dart';

/// First screen: dark hero with a floating preview of the Today card.
class WelcomePage extends GetView<OnboardingController> {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Logo(),
                const SizedBox(height: 12),
                const _HeroPreview(),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text.rich(
                    const TextSpan(
                      text: 'Your GLP-1 journey, ',
                      children: [
                        TextSpan(text: 'handled.', style: TextStyle(color: AppColors.lime)),
                      ],
                    ),
                    style: AppText.h1.copyWith(fontSize: 40, color: AppColors.white, letterSpacing: -1.3),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Doses, protein, water and how you feel. One calm app, built around your shot day.',
                  style: AppText.bodyText.copyWith(fontSize: 16, height: 1.5, color: AppColors.heroMuted),
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Perk(PhosphorIconsDuotone.userCircleMinus, 'No account'),
                    _Perk(PhosphorIconsDuotone.deviceMobile, 'Data stays on your phone'),
                    _Perk(PhosphorIconsDuotone.checkCircle, 'Free tracking'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Column(
            children: [
              PillButton(label: "Let's go", lime: true, onPressed: controller.next),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  text: "By continuing you confirm you're 18 or older and accept the ",
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800),
                      recognizer: TapGestureRecognizer()..onTap = showLegalSheet,
                    ),
                    const TextSpan(text: ". Kindose doesn't give medical advice."),
                  ],
                ),
                textAlign: TextAlign.center,
                style: AppText.tiny.copyWith(fontSize: 12, color: const Color(0xFF8F8DB0), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(12)),
          child: const Center(
            child: PhosphorIcon(PhosphorIconsBold.drop, size: 20, color: AppColors.hero),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'kindose',
          style: AppText.h2.copyWith(fontSize: 22, color: AppColors.white, letterSpacing: -0.4),
        ),
      ],
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.icon, this.label);

  final PhosphorDuotoneIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 16, color: AppColors.lime),
          const SizedBox(width: 6),
          Text(label, style: AppText.small.copyWith(color: const Color(0xFFE8E7F5))),
        ],
      ),
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 270,
        child: Builder(
          builder: (context) {
            final w = MediaQuery.sizeOf(context).width - 48;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: w * 0.2,
                  top: 34,
                  child: Transform.rotate(
                    angle: -0.07,
                    child: Container(
                      width: 206,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 60, offset: const Offset(0, 30)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEXT DOSE', style: AppText.caps.copyWith(color: AppColors.violet, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Text('2d 14h', style: AppText.number(44).copyWith(color: AppColors.ink, letterSpacing: -1.5)),
                          const SizedBox(height: 6),
                          Text('Sunday · 9:00 AM', style: AppText.small.copyWith(color: const Color(0xFF5E5C7A))),
                          const SizedBox(height: 10),
                          const _MiniBar('Protein', '86 / 110 g', 0.78, AppColors.tangerine, AppColors.tangerineSoft),
                          const SizedBox(height: 6),
                          const _MiniBar('Water', '1.8 / 2.5 L', 0.72, AppColors.aqua, AppColors.aquaSoft),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(right: 0, top: 0, child: Floaty(child: ThreeD(Img3d.syringe, size: 104))),
                Positioned(
                  left: -6,
                  top: 10,
                  child: Floaty(
                    delayMs: 600,
                    child: Transform.rotate(angle: -0.17, child: const ThreeD(Img3d.calendar, size: 74)),
                  ),
                ),
                const Positioned(left: 6, top: 168, child: Floaty(delayMs: 900, child: ThreeD(Img3d.egg, size: 60))),
                const Positioned(right: 14, top: 196, child: Floaty(delayMs: 300, child: ThreeD(Img3d.droplet, size: 60))),
                Positioned(left: w * 0.66, top: 128, child: const Floaty(delayMs: 1200, child: ThreeD(Img3d.biceps, size: 62))),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar(this.label, this.value, this.pct, this.color, this.track);

  final String label;
  final String value;
  final double pct;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: AppText.tiny.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const Spacer(),
            Text(value, style: AppText.tiny.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF5E5C7A))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, minHeight: 8, color: color, backgroundColor: track),
        ),
      ],
    );
  }
}

/// Question 1: where the user is on their treatment. Tapping an option
/// selects it and moves on (no Continue button for single choices).
class StagePage extends GetView<OnboardingController> {
  const StagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.card == KColors.dark.card;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final options = [
      _StageOption(
        id: 'taking',
        title: "I'm already taking it",
        sub: 'Track doses from today',
        icon: Img3d.syringe,
        tint: k.cardAlt,
      ),
      _StageOption(
        id: 'starting',
        title: "I'm starting soon",
        sub: 'Get ready for your first dose',
        icon: Img3d.calendar,
        tint: dark ? AppColors.lime.withValues(alpha: 0.12) : const Color(0xFFF1F7D6),
      ),
      _StageOption(
        id: 'restart',
        title: 'Restarting after a break',
        sub: 'Pick up where you left off',
        icon: Img3d.seedling,
        tint: dark ? AppColors.aqua.withValues(alpha: 0.16) : AppColors.aquaSoft,
      ),
    ];

    return StepScaffold(
      title: 'Where are you on your GLP-1 journey?',
      subtitle: 'This shapes your plan. You can change it anytime.',
      cta: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PrivacyNote('Everything you enter stays on this phone unless you choose to back it up.')
              .enter(motion, delay: 420, dy: 0.1),
          SizedBox(height: 10.sp),
          const TapHint('Tap an option to continue').enter(motion, delay: 480, dy: 0),
        ],
      ),
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(height: 12.sp),
          Obx(
            () => ChoiceTile(
              title: options[i].title,
              sub: options[i].sub,
              leading: ChoiceIcon(options[i].icon, tint: options[i].tint),
              selected: controller.stage.value == options[i].id,
              onTap: () => controller.pickStage(options[i].id),
            ),
          ).enter(motion, delay: 140 + i * 70),
        ],
      ],
    );
  }
}

class _StageOption {
  const _StageOption({
    required this.id,
    required this.title,
    required this.sub,
    required this.icon,
    required this.tint,
  });

  final String id;
  final String title;
  final String sub;
  final String icon;
  final Color tint;
}
