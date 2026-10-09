import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../resources/images.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';
import '../next_bite.dart';
import '../today_controller.dart';

/// "Next bite": what to eat now to close today's protein gap, sized to how
/// much the user can eat today (dose cycle, appetite, nausea).
class NextBiteCard extends GetView<TodayController> {
  const NextBiteCard({super.key, this.compact = false});

  /// On the Protein screen: no progress block or "Log other food" (the screen
  /// already shows both).
  final bool compact;

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build(context, controller.nextBite);
  });

  Widget _build(BuildContext context, NextBite b) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final ink = dark ? AppColors.lime : AppColors.ink;
    final unlocked = controller.biteUnlocked;
    final shown = b.ideas.take(unlocked ? 3 : 1).toList();

    return Container(
      padding: EdgeInsets.all(18.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(24.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.sp, vertical: 4.sp),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(9.sp),
                ),
                child: Text(
                  'NEXT BITE',
                  style: AppText.caps.copyWith(
                    fontSize: 11.sp,
                    letterSpacing: 1,
                    color: AppColors.ink,
                  ),
                ),
              ),
              SizedBox(width: 2.sp),
              Semantics(
                button: true,
                label: 'Why these ideas?',
                excludeSemantics: true,
                child: PressScale(
                  onTap: () => controller.showBiteWhy(b),
                  // 44 px tap area around a small ⓘ button.
                  child: SizedBox.square(
                    dimension: 44.sp,
                    child: Center(
                      child: Container(
                        width: 28.sp,
                        height: 28.sp,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: k.border, width: 1.5),
                        ),
                        child: PhosphorIcon(
                          PhosphorIconsBold.info,
                          size: 15.sp,
                          color: k.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Same arrow as the Water card: opens the Protein screen.
              if (!compact)
                Semantics(
                  button: true,
                  label: 'Open protein',
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: controller.openProtein,
                    child: SizedBox(
                      height: 44.sp,
                      child: const Center(child: OpenArrow()),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.sp),
          Text(
            b.context,
            style: AppText.small.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: k.muted,
            ),
          ),
          if (!compact) ...[
            SizedBox(height: 10.sp),
            Semantics(
              label: '${b.have} of ${b.goal} grams protein today',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  NumberUnit('${b.have}', 'g', size: 30.sp, color: k.text),
                  SizedBox(width: 6.sp),
                  Expanded(
                    child: Text(
                      'of ${b.goal} g protein',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: k.muted,
                      ),
                    ),
                  ),
                  if (!b.goalHit)
                    Text(
                      '${b.goal - b.have} g to go',
                      style: AppText.small.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: k.muted,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8.sp),
            ClipRRect(
              borderRadius: BorderRadius.circular(3.sp),
              child: SizedBox(
                height: 6.sp,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    end: b.goal == 0 ? 0 : (b.have / b.goal).clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6.sp,
                    backgroundColor: k.cardAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(ink),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: compact ? 10.sp : 14.sp),
          if (b.goalHit)
            _GoalHit(goal: b.goal)
          else ...[
            Text(
              b.lead.endsWith(':')
                  ? b.lead.substring(0, b.lead.length - 1)
                  : b.lead,
              style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text),
            ),
            SizedBox(height: 10.sp),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  for (final (n, i) in shown.indexed) ...[
                    if (n > 0) SizedBox(height: 8.sp),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(a),
                          child: child,
                        ),
                      ),
                      child: _IdeaRow(
                        key: ValueKey<String>(i.id),
                        idea: i,
                        onAdd: () => controller.addBite(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!unlocked) ...[
              SizedBox(height: 8.sp),
              _PlusRow(onTap: controller.openPlusFromBite),
            ],
            if (b.tip != null) ...[
              SizedBox(height: 8.sp),
              // A quiet line, not another coloured box.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.sp),
                child: Text(
                  b.tip!,
                  style: AppText.small.copyWith(
                    fontSize: 13.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: k.muted,
                  ),
                ),
              ),
            ],
          ],
          SizedBox(height: 10.sp),
          if (!compact)
            Row(
              children: [
                _QuickChip(
                  label: '+10 g',
                  onTap: () => controller.addProtein(10),
                ),
                SizedBox(width: 8.sp),
                _QuickChip(
                  label: '+20 g',
                  onTap: () => controller.addProtein(20),
                ),
                SizedBox(width: 8.sp),
                // Opens the Protein screen: search, My foods, all foods.
                Expanded(
                  child: _OtherFoodChip(onTap: controller.openProtein),
                ),
              ],
            ),
          SizedBox(height: 10.sp),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Ideas only, not medical advice',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: k.faint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "+10 g" style quick add, same look as the old Protein card chips.
class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      label: 'Add ${label.replaceAll('+', '')} protein',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          height: 36.sp,
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.sp),
            border: Border.all(color: k.border, width: 1.5),
          ),
          child: Text(
            label,
            style: AppText.bodyStrong.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: k.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Log other food ›", same outline style as the +10 g / +20 g chips.
class _OtherFoodChip extends StatelessWidget {
  const _OtherFoodChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      label: 'Log other food. Opens the protein screen',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          height: 36.sp,
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.sp),
            border: Border.all(color: k.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Log other food',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: k.text,
                  ),
                ),
              ),
              SizedBox(width: 2.sp),
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 13.sp,
                color: k.text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaRow extends StatelessWidget {
  const _IdeaRow({super.key, required this.idea, required this.onAdd});

  final BiteIdea idea;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Semantics(
      button: true,
      label: 'Add ${idea.name}, ${idea.portion}, ${idea.grams} grams protein',
      excludeSemantics: true,
      child: PressScale(
        onTap: onAdd,
        child: Container(
          padding: EdgeInsets.fromLTRB(10.sp, 10.sp, 10.sp, 10.sp),
          decoration: BoxDecoration(
            color: k.bg,
            borderRadius: BorderRadius.circular(18.sp),
          ),
          child: Row(
            children: [
              Container(
                width: 40.sp,
                height: 40.sp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: k.card,
                  borderRadius: BorderRadius.circular(13.sp),
                ),
                child: ThreeD(idea.icon, size: 26.sp),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(
                        fontSize: 14.5.sp,
                        color: k.text,
                      ),
                    ),
                    Text(
                      idea.portion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: k.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.sp),
              // Amount and action in one button: "+ 30 g".
              Container(
                height: 36.sp,
                padding: EdgeInsets.symmetric(horizontal: 12.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark ? AppColors.lime : AppColors.ink,
                  borderRadius: BorderRadius.circular(18.sp),
                ),
                child: Text(
                  '+ ${idea.grams} g',
                  style: AppText.small.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: dark ? AppColors.ink : AppColors.lime,
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

class _PlusRow extends StatelessWidget {
  const _PlusRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '2 more ideas with Plus',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
          decoration: BoxDecoration(
            color: AppColors.hero,
            borderRadius: BorderRadius.circular(16.sp),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '2 more ideas for today',
                  style: AppText.small.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: 8.sp),
              const PlusTag(onDark: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalHit extends StatelessWidget {
  const _GoalHit({required this.goal});

  final int goal;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.sp),
      decoration: BoxDecoration(
        color: k.bg,
        borderRadius: BorderRadius.circular(18.sp),
      ),
      child: Row(
        children: [
          ThreeD(Img3d.biceps, size: 32.sp),
          SizedBox(width: 12.sp),
          Expanded(
            child: Text(
              'Protein goal reached today. Nicely done.',
              style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Why these?" sheet.
Future<void> showBiteWhySheet(NextBite b) {
  return Get.bottomSheet<void>(_WhySheet(bite: b), isScrollControlled: true);
}

class _WhySheet extends StatelessWidget {
  const _WhySheet({required this.bite});

  final NextBite bite;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSheetFrame(
      title: 'Why these ideas',
      sub: 'Next bite picks small, protein-first foods that fit today.',
      children: [
        for (final r in bite.reasons)
          Padding(
            padding: EdgeInsets.only(bottom: 10.sp),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 6.sp),
                  child: Container(
                    width: 7.sp,
                    height: 7.sp,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    r,
                    style: AppText.bodyText.copyWith(
                      fontSize: 14.5.sp,
                      color: k.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 6.sp),
        Text(
          'These are general food ideas with typical protein amounts, not medical or nutrition advice. '
          'Your doctor or dietitian can adjust your goal. You can change it anytime in Me.',
          style: AppText.small.copyWith(
            fontSize: 12.5.sp,
            height: 1.45,
            color: k.muted,
          ),
        ),
        SizedBox(height: 8.sp),
      ],
    );
  }
}
