import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../services/plus/plus_access.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/mood_row.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'check_in_controller.dart';
import 'widgets/symptoms_sheet.dart';

/// How I feel: mood, nausea / food noise / appetite, side effects with a
/// strength, a safety card for anything severe, and a note. ~20 seconds.
class CheckInScreen extends GetView<CheckInController> {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: k.bg,
      body: KSafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 0),
              child: Row(
                children: [
                  BackCircle(onTap: popRoute),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Text(
                      controller.eyebrow,
                      style: AppText.caps.copyWith(
                        fontSize: 12.sp,
                        letterSpacing: 1.1,
                        color: k.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 24.sp),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      controller.title,
                      style: AppText.h1.copyWith(
                        fontSize: 30.sp,
                        color: k.text,
                      ),
                    ),
                  ).enter(motion),
                  SizedBox(height: 6.sp),
                  Text(
                    controller.sub,
                    style: AppText.bodyStrong.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: k.muted,
                    ),
                  ).enter(motion, delay: 40),
                  SizedBox(height: 18.sp),
                  Obx(
                    () => MoodRow(
                      selected: controller.mood.value,
                      onPick: controller.pickMood,
                      height: 92.sp,
                      onCard: false,
                    ),
                  ).enter(motion, delay: 80),
                  SizedBox(height: 18.sp),
                  const _Scales().enter(motion, delay: 120),
                  _label(context, 'Anything else?').enter(motion, delay: 160),
                  const _Effects().enter(motion, delay: 180),
                  const _SevereCard(),
                  SizedBox(height: 16.sp),
                  // The Plus advert only for people without Plus; they
                  // see their real pattern on Progress.
                  Obx(
                    () => PlusAccess.unlocked
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsets.only(bottom: 12.sp),
                            child: const _PatternTeaser().enter(
                              motion,
                              delay: 220,
                            ),
                          ),
                  ),
                  const _Note(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 12.sp),
              child: Obx(
                () => PillButton(
                  label: 'Save check-in',
                  icon: PhosphorIconsBold.check,
                  busy: controller.saving.value,
                  onPressed: controller.save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final k = context.k;
    return Padding(
      padding: EdgeInsets.only(top: 14.sp, bottom: 6.sp),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text.toUpperCase(),
                style: AppText.caps.copyWith(
                  fontSize: 12.sp,
                  letterSpacing: 1.1,
                  color: k.muted,
                ),
              ),
            ),
          ),
          PressScale(
            semanticLabel: 'Customise symptoms',
            onTap: () => showSymptomsSheet(),
            child: Container(
              color: Colors.transparent,
              constraints: BoxConstraints(minHeight: 44.sp),
              padding: EdgeInsets.only(left: 12.sp),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsBold.slidersHorizontal,
                    size: 15.sp,
                    color: k.text,
                  ),
                  SizedBox(width: 6.sp),
                  Text(
                    'Customise',
                    style: AppText.small.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: k.text,
                    ),
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

/// Nausea, food noise and appetite: one tap on a level each.
class _Scales extends GetView<CheckInController> {
  const _Scales();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(22.sp),
        ),
        child: Column(
          children: [
            _ScaleRow(
              title: 'Nausea',
              hint: 'Feeling sick',
              options: const ['None', 'Mild', 'Moderate', 'Severe'],
              selected: controller.nauseaOnScreen,
              danger: 3,
              onPick: controller.pickNausea,
            ),
            Divider(height: 1, color: k.border),
            _ScaleRow(
              title: 'Food noise',
              hint: 'Thinking about food',
              options: const ['Quiet', 'Some', 'Loud'],
              selected: controller.foodNoise.value,
              onPick: (v) => controller.pickLevel(controller.foodNoise, v),
            ),
            Divider(height: 1, color: k.border),
            _ScaleRow(
              title: 'Appetite',
              hint: 'How hungry',
              options: const ['Low', 'Normal', 'High'],
              selected: controller.appetite.value,
              onPick: (v) => controller.pickLevel(controller.appetite, v),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.title,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onPick,
    this.danger,
  });

  final String title;
  final String hint;
  final List<String> options;
  final int? selected;
  final ValueChanged<int> onPick;

  /// Option drawn in red when picked (Severe).
  final int? danger;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
                ),
              ),
              Text(
                hint,
                style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) SizedBox(width: 6.sp),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected == i,
                    inMutuallyExclusiveGroup: true,
                    label: '$title: ${options[i]}',
                    excludeSemantics: true,
                    child: PressScale(
                      pressedScale: 0.95,
                      onTap: () => onPick(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 40.sp,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected != i
                              ? k.bg
                              : i == danger
                              ? AppColors.danger
                              : k.text,
                          borderRadius: BorderRadius.circular(14.sp),
                        ),
                        child: Text(
                          options[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: selected != i
                                ? k.textSoft
                                : i == danger
                                ? AppColors.white
                                : k.bg,
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
      ),
    );
  }
}

/// Side-effect chips to pick, then a Mild / Moderate / Severe row for
/// each picked one, in the order they were picked.
class _Effects extends GetView<CheckInController> {
  const _Effects();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.levels.length;
      controller.levels.values.toList();
      final effects = controller.effects;
      final picked = controller.levels.keys.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (effects.isEmpty)
            Text(
              'No symptoms on your list. Tap Customise to add some.',
              style: AppText.small.copyWith(fontSize: 13.sp, color: k.muted),
            )
          else
            Wrap(
              spacing: 8.sp,
              runSpacing: 8.sp,
              children: [
                for (final id in effects)
                  _EffectChip(
                    name: Catalog.symptomLabel(id),
                    level: controller.levelOf(id),
                    onTap: () => controller.toggleEffect(id),
                  ),
              ],
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: picked.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.only(top: 12.sp),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.sp,
                        vertical: 4.sp,
                      ),
                      decoration: BoxDecoration(
                        color: k.card,
                        borderRadius: BorderRadius.circular(22.sp),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < picked.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: k.border),
                            _ScaleRow(
                              title: Catalog.symptomLabel(picked[i]),
                              hint: 'How strong',
                              options: const ['Mild', 'Moderate', 'Severe'],
                              selected: controller.levelOf(picked[i]) - 1,
                              danger: 2,
                              onPick: (v) =>
                                  controller.setLevel(picked[i], v + 1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

/// A side effect to pick: outlined, or filled once picked (red when
/// severe). Same size either way, so the chips never move under a finger.
class _EffectChip extends StatelessWidget {
  const _EffectChip({
    required this.name,
    required this.level,
    required this.onTap,
  });

  final String name;
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final on = level > 0;
    final severe = level == 3;
    final bg = severe ? AppColors.dangerSoft : (on ? k.text : k.card);
    final fg = severe ? AppColors.dangerText : (on ? k.bg : k.text);
    return Semantics(
      button: true,
      selected: on,
      label: on
          ? '$name, ${Catalog.levelWords[level]}. Tap to remove'
          : '$name. Tap to add',
      excludeSemantics: true,
      child: PressScale(
        pressedScale: 0.94,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42.sp,
          padding: EdgeInsets.symmetric(horizontal: 14.sp),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(21.sp),
            border: Border.all(
              color: severe ? AppColors.danger : (on ? k.text : k.border),
              width: 1.5,
            ),
          ),
          // A Row sizes to the name and centres it vertically.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppText.small.copyWith(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SevereCard extends GetView<CheckInController> {
  const _SevereCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.levels.length;
      final show = controller.anySevere;
      return AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: !show
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: EdgeInsets.only(top: 14.sp),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 16.sp, 14.sp),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(18.sp),
                    ),
                    child: Text.rich(
                      const TextSpan(
                        children: [
                          TextSpan(
                            text: 'That sounds hard. ',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text:
                                'If you have severe stomach pain, can’t keep fluids down, feel very dizzy, '
                                'have vision changes or chest pain, contact your doctor or local emergency services now.',
                          ),
                        ],
                      ),
                      style: AppText.small.copyWith(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: AppColors.dangerText,
                      ),
                    ),
                  ),
                ),
              ),
      );
    });
  }
}

/// Plus teaser for "side-effect patterns" with example bars. Hidden once
/// Plus is open; the real pattern is on Progress.
class _PatternTeaser extends GetView<CheckInController> {
  const _PatternTeaser();

  static const List<(String, double)> _example = [
    ('Dose', 0.35),
    ('D1', 0.95),
    ('D2', 0.85),
    ('D3', 0.55),
    ('D4', 0.35),
    ('D5', 0.25),
    ('D6', 0.2),
  ];

  @override
  Widget build(BuildContext context) {
    final bordered = context.k.selectedBorder == AppColors.lime;
    return PressScale(
      semanticLabel: 'Your pattern, a Kindose Plus feature. See which day after your dose feels hardest. Opens Plus',
      onTap: controller.openPlus,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: AppColors.hero,
            borderRadius: BorderRadius.circular(22.sp),
            border: bordered ? Border.all(color: context.k.border) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'YOUR PATTERN',
                    style: AppText.caps.copyWith(
                      fontSize: 12.sp,
                      letterSpacing: 1,
                      color: AppColors.lime,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  const PlusTag(onDark: true),
                  const Spacer(),
                  Text(
                    'Example',
                    style: AppText.small.copyWith(
                      fontSize: 11.5.sp,
                      color: AppColors.heroMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.sp),
              SizedBox(
                height: 62.sp,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, (label, h)) in _example.indexed) ...[
                      if (i > 0) SizedBox(width: 6.sp),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 44.sp * h,
                              decoration: BoxDecoration(
                                color: i == 1
                                    ? AppColors.lime
                                    : AppColors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6.sp),
                              ),
                            ),
                            SizedBox(height: 4.sp),
                            Text(
                              label,
                              style: AppText.tiny.copyWith(
                                fontSize: 10.5.sp,
                                color: AppColors.heroMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 10.sp),
              Text(
                'After 3 dose weeks you’ll see which day after your dose feels hardest, and it goes into your doctor report.',
                style: AppText.small.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: AppColors.heroMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends GetView<CheckInController> {
  const _Note();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      if (controller.showNote.value) {
        return TextField(
          controller: controller.noteCtrl,
          focusNode: controller.noteFocus,
          autofocus: controller.noteCtrl.text.isEmpty && !controller.focusNote,
          minLines: 1,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          style: AppText.bodyStrong.copyWith(fontSize: 14.5.sp, color: k.text),
          decoration: const InputDecoration(
            hintText: 'What you ate, sleep, anything to remember',
          ),
        );
      }
      return Material(
        color: k.card,
        borderRadius: BorderRadius.circular(18.sp),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.sp),
          onTap: () => controller.showNote.value = true,
          child: Container(
            constraints: BoxConstraints(minHeight: 52.sp),
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsBold.pencilSimple,
                  size: 18.sp,
                  color: k.muted,
                ),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    'Add a note (what you ate, sleep…)',
                    style: AppText.bodyStrong.copyWith(
                      fontSize: 14.5.sp,
                      color: k.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
