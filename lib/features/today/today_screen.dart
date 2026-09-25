import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/mood_row.dart';
import '../../widgets/painters.dart';
import '../home/home_screen.dart';
import 'today_controller.dart';

class TodayScreen extends GetView<TodayController> {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        // Touch the reactive sources this screen depends on.
        controller.now.value;
        controller.tracker.doses.length;
        controller.tracker.days.length;
        controller.tracker.weights.length;
        final profile = controller.profile;
        if (profile == null) return const SizedBox.shrink();

        final Widget doseCard;
        if (controller.doseToday != null) {
          doseCard = const _DoseLoggedCard();
        } else if (controller.isDoseDay) {
          doseCard = const _DoseDayCard();
        } else {
          doseCard = const _CountdownCard();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, kNavClearance),
          children: [
            const _Header(),
            const SizedBox(height: 14),
            AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: doseCard),
            if (controller.showChecklist) ...[
              const SizedBox(height: 12),
              const _Checklist(),
            ],
            const SizedBox(height: 12),
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ProteinCard()),
                  SizedBox(width: 12),
                  Expanded(child: _WaterCard()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _MoodCard(),
            const SizedBox(height: 12),
            const _TipCard(),
          ],
        );
      }),
    );
  }
}

class _Header extends GetView<TodayController> {
  const _Header();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final k = context.k;
    final streak = controller.streakLabel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Dates.long(controller.now.value), style: AppText.bodyStrong.copyWith(color: k.muted)),
              const SizedBox(height: 2),
              Semantics(header: true, child: Text(Dates.greeting(controller.now.value), style: AppText.h1)),
            ],
          ),
        ),
        if (streak.isNotEmpty)
          Container(
            height: 38,
            padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
            decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(19)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThreeD(Img3d.fire, size: 26),
                const SizedBox(width: 4),
                Text(streak, style: AppText.small.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CountdownCard extends GetView<TodayController> {
  const _CountdownCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    return Container(
      key: const ValueKey('countdown'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: context.k.bg == KColors.dark.bg
            ? const LinearGradient(colors: [Color(0xFF2B2470), Color(0xFF1B1A33)])
            : null,
        color: AppColors.hero,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -22,
            child: Transform.rotate(angle: 0.14, child: const Floaty(child: ThreeD(Img3d.syringe, size: 100))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 80),
                child: Text(
                  'NEXT ${controller.isTablet ? 'TABLET' : 'DOSE'} · ${controller.medicineLabel.toUpperCase()}',
                  style: AppText.caps.copyWith(color: AppColors.heroMuted, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                label: 'Next dose in ${controller.countdown}',
                excludeSemantics: true,
                child: Text(controller.countdown, style: AppText.number(54).copyWith(color: AppColors.lime)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.nextDoseLine,
                      style: AppText.bodyStrong.copyWith(fontSize: 15, color: const Color(0xFFE8E7F5)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => Get.toNamed<void>(Routes.logDose),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        child: Text('Log dose', style: AppText.small.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.hero)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lime card shown when a dose is due today (or overdue).
class _DoseDayCard extends GetView<TodayController> {
  const _DoseDayCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final p = controller.profile;
    final overdue = controller.isOverdue;
    final next = controller.nextDoseAt;
    final dueLine = overdue && next != null
        ? 'Planned for ${Dates.shortWithDay(next)}'
        : 'Due today · ${Dates.timeOfDay(p?.shotMinutes ?? 540)}';
    return Container(
      key: const ValueKey('doseday'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(overdue ? 'DOSE PENDING' : "IT'S DOSE DAY", style: AppText.caps.copyWith(color: AppColors.hero)),
                    const SizedBox(height: 6),
                    Text(controller.medicineLabel, style: AppText.h2.copyWith(fontSize: 28, color: AppColors.hero)),
                    const SizedBox(height: 4),
                    Text(dueLine, style: AppText.bodyStrong.copyWith(color: AppColors.hero)),
                    if (!controller.isTablet)
                      Text(
                        'Next site: ${controller.nextSiteName.toLowerCase()}',
                        style: AppText.bodyStrong.copyWith(color: AppColors.hero.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
              const Floaty(child: ThreeD(Img3d.syringe, size: 76)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Obx(() => SoftButton(
                      label: 'Mark as done',
                      icon: PhosphorIconsBold.check,
                      background: AppColors.hero,
                      foreground: AppColors.white,
                      height: 50,
                      onPressed: controller.busy.value ? null : controller.markDoseDone,
                    )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SoftButton(
                  label: 'Add details',
                  background: AppColors.hero.withValues(alpha: 0.1),
                  foreground: AppColors.hero,
                  height: 50,
                  onPressed: () => Get.toNamed<void>(Routes.logDose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoseLoggedCard extends GetView<TodayController> {
  const _DoseLoggedCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final d = controller.doseToday;
    if (d == null) return const SizedBox.shrink();
    final where = d.site.isEmpty ? 'Taken' : controller.siteNameOf(d.site);
    return Container(
      key: const ValueKey('logged'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.hero, borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          const _Pop(child: ThreeD(Img3d.partyPopper, size: 64)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dose logged', style: AppText.h2.copyWith(color: AppColors.lime)),
                const SizedBox(height: 4),
                Text(
                  '$where · ${Dates.time(d.takenAt)}. Next: ${controller.nextAfterToday}.',
                  style: AppText.bodyStrong.copyWith(color: const Color(0xFFE8E7F5)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.undoDoseToday,
            child: Text('Undo', style: AppText.title.copyWith(color: AppColors.heroMuted)),
          ),
        ],
      ),
    );
  }
}

class _Pop extends StatelessWidget {
  const _Pop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: child,
    );
  }
}

class _Checklist extends GetView<TodayController> {
  const _Checklist();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final k = context.k;
    final items = controller.checklist;
    final done = items.where((i) => i.done).length;
    return KCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Start here', style: AppText.h3)),
              Text('$done of ${items.length}', style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / items.length,
              minHeight: 8,
              color: AppColors.violet,
              backgroundColor: k.border,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in items)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: item.done ? null : item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ThreeD(item.icon, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppText.title.copyWith(
                          color: item.done ? k.faint : k.text,
                          decoration: item.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: item.done ? AppColors.violet : Colors.transparent,
                        shape: BoxShape.circle,
                        border: item.done ? null : Border.all(color: k.border, width: 2),
                      ),
                      child: item.done
                          ? const Center(child: PhosphorIcon(PhosphorIconsBold.check, size: 14, color: AppColors.white))
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProteinCard extends GetView<TodayController> {
  const _ProteinCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final k = context.k;
    final g = controller.day.proteinG;
    final goal = controller.proteinGoal;
    return KCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Protein', style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800))),
              CircleIconButton(
                icon: PhosphorIconsBold.plus,
                label: 'Add protein',
                size: 32,
                background: k.proteinTrack,
                foreground: AppColors.tangerine,
                onTap: () => Get.toNamed<void>(Routes.addIntake, arguments: 'protein'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressRing(
            value: goal == 0 ? 0 : g / goal,
            color: AppColors.tangerine,
            track: k.proteinTrack,
            size: 96,
            child: const ThreeD(Img3d.egg, size: 40),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '$g of $goal grams protein',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$g', style: AppText.number(20).copyWith(color: k.text)),
                  TextSpan(text: ' / $goal g', style: AppText.bodyStrong.copyWith(color: k.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends GetView<TodayController> {
  const _WaterCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final k = context.k;
    final count = controller.glassCount;
    final full = controller.glassesFull;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Water', style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800))),
              const ThreeD(Img3d.droplet, size: 30),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: controller.litres, style: AppText.number(28).copyWith(color: k.text)),
                TextSpan(text: ' / ${controller.waterGoalLabel}', style: AppText.bodyStrong.copyWith(color: k.muted)),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 8),
          for (var row = 0; row * 5 < count; row++) ...[
            if (row > 0) const SizedBox(height: 5),
            Row(
              children: [
                for (var i = row * 5; i < row * 5 + 5; i++) ...[
                  if (i > row * 5) const SizedBox(width: 5),
                  Expanded(
                    child: i >= count
                        ? const SizedBox.shrink()
                        : AspectRatio(
                            aspectRatio: 0.72,
                            child: Semantics(
                              button: true,
                              label: 'Glass ${i + 1}, ${i < full ? 'filled' : 'empty'}',
                              excludeSemantics: true,
                              child: GestureDetector(
                                onTap: () => controller.tapGlass(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: i < full ? AppColors.aqua : k.waterEmpty,
                                    border: Border.all(color: i < full ? AppColors.aqua : k.waterEdge, width: 2),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                      bottom: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text('Tap a glass · 250 ml each', style: AppText.tiny.copyWith(color: k.faint)),
        ],
      ),
    );
  }
}

class _MoodCard extends GetView<TodayController> {
  const _MoodCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    return KCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('How are you feeling?', style: AppText.title)),
              TextButton(
                onPressed: () => Get.toNamed<void>(Routes.checkIn),
                child: Text('Add details', style: AppText.small.copyWith(fontWeight: FontWeight.w800, color: context.k.tintText)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          MoodRow(selected: controller.day.mood, onPick: controller.setMood, height: 66),
        ],
      ),
    );
  }
}

class _TipCard extends GetView<TodayController> {
  const _TipCard();

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final k = context.k;
    final tip = controller.tip;
    return KCard(
      color: k.tint,
      radius: 22,
      child: Row(
        children: [
          ThreeD(tip.icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title.toUpperCase(), style: AppText.caps.copyWith(color: k.tintText)),
                const SizedBox(height: 2),
                Text(tip.text, style: AppText.bodyStrong),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
