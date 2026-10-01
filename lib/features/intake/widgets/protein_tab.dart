import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../models/logs.dart';
import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/images.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';
import '../../today/next_bite.dart';
import '../intake_controller.dart';
import 'intake_parts.dart';

/// Protein screen: one top card (progress + today's log with Undo),
/// search + Custom, then Suggested / My foods / All foods.
class ProteinTab extends GetView<IntakeController> {
  const ProteinTab({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Obx(() {
      controller.watch();
      final searching = controller.query.value.trim().isNotEmpty;
      final section = controller.currentSection;
      return ListView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 40.sp),
        children: [
          const _Hero().enter(motion),
          SizedBox(height: 12.sp),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _SearchField()),
                SizedBox(width: 8),
                _CustomButton(),
              ],
            ),
          ).enter(motion, delay: 40),
          if (searching)
            const _Results()
          else ...[
            if (controller.sections.length > 1) ...[
              SizedBox(height: 12.sp),
              KSegmented<String>(
                options: controller.sections,
                selected: section,
                onChanged: controller.pickSection,
                labelOf: IntakeController.sectionName,
                dense: true,
              ).enter(motion, delay: 80),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: switch (section) {
                'sug' => const _Suggested(key: ValueKey('sug')),
                'mine' => const _MyFoods(key: ValueKey('mine')),
                _ => const _AllFoods(key: ValueKey('all')),
              },
            ),
          ],
        ],
      );
    });
  }
}

// ---------------------------------------------------------------- top card

class _Hero extends GetView<IntakeController> {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.watch();
      final total = controller.proteinToday;
      final entries = controller.proteinEntries;
      final last = controller.lastProtein;
      final open = controller.logOpen.value && entries.length > 1;
      return Container(
        padding: EdgeInsets.all(18.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(24.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label:
                  'Protein ${controller.dayTitle.toLowerCase()}: $total of ${controller.proteinGoal} grams. ${controller.proteinLine}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROTEIN · ${controller.dayTitle.toUpperCase()}',
                              style: intakeCaps(
                                context,
                              ).copyWith(color: k.faint),
                            ),
                            SizedBox(height: 6.sp),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(end: total.toDouble()),
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, _) => Text(
                                    '${v.round()}',
                                    style: AppText.number(
                                      44.sp,
                                    ).copyWith(color: k.text),
                                  ),
                                ),
                                SizedBox(width: 6.sp),
                                Text(
                                  'of ${controller.proteinGoal} g',
                                  style: AppText.title.copyWith(
                                    fontSize: 16.sp,
                                    color: k.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ThreeD(Img3d.biceps, size: 48.sp),
                    ],
                  ),
                  SizedBox(height: 12.sp),
                  _Bar(value: controller.proteinProgress),
                  SizedBox(height: 10.sp),
                  Text(
                    controller.proteinLine,
                    style: AppText.small.copyWith(
                      fontSize: 13.5.sp,
                      color: k.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) => SizeTransition(
                sizeFactor: a,
                axisAlignment: -1,
                child: FadeTransition(opacity: a, child: child),
              ),
              child: last == null
                  ? const SizedBox(
                      width: double.infinity,
                      key: ValueKey('none'),
                    )
                  : Padding(
                      key: ValueKey(last.id),
                      padding: EdgeInsets.only(top: 14.sp),
                      child: _LastAdded(entry: last),
                    ),
            ),
            if (entries.length > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  expanded: open,
                  label: open
                      ? 'Hide today\'s list'
                      : 'See all ${entries.length} entries',
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: controller.toggleLog,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 12.sp,
                        bottom: 2.sp,
                        right: 12.sp,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            open
                                ? 'Hide'
                                : 'See all ${entries.length} ${controller.isToday ? 'today' : 'that day'}',
                            style: AppText.title.copyWith(
                              fontSize: 13.5.sp,
                              color: k.text,
                            ),
                          ),
                          SizedBox(width: 4.sp),
                          AnimatedRotation(
                            turns: open ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              PhosphorIconsBold.caretDown,
                              size: 14.sp,
                              color: k.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      children: [
                        SizedBox(height: 6.sp),
                        for (final e in entries) _LogRow(entry: e),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.sp),
      child: SizedBox(
        height: 12.sp,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: context.k.proteinTrack)),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.tangerine,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
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

/// Newest entry with a one-tap Undo, so a wrong tap is fixed right here.
class _LastAdded extends GetView<IntakeController> {
  const _LastAdded({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final title = controller.entryTitle(entry);
    return Container(
      padding: EdgeInsets.fromLTRB(14.sp, 10.sp, 8.sp, 10.sp),
      decoration: BoxDecoration(
        color: k.bg,
        borderRadius: BorderRadius.circular(16.sp),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST ADDED · ${controller.timeOf(entry.at)}',
                  style: intakeCaps(
                    context,
                  ).copyWith(fontSize: 10.5.sp, color: k.faint),
                ),
                SizedBox(height: 2.sp),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 14.sp,
                    color: k.text,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.sp),
          Text(
            '+${entry.amount} g',
            style: AppText.title.copyWith(fontSize: 14.sp, color: k.text),
          ),
          SizedBox(width: 10.sp),
          Semantics(
            button: true,
            label: 'Undo $title',
            excludeSemantics: true,
            child: PressScale(
              pressedScale: 0.92,
              onTap: () => controller.removeWithUndo(entry),
              child: Container(
                height: 36.sp,
                padding: EdgeInsets.symmetric(horizontal: 14.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: k.card,
                  borderRadius: BorderRadius.circular(18.sp),
                  border: Border.all(color: k.text, width: 1.5),
                ),
                child: Text(
                  'Undo',
                  style: AppText.title.copyWith(
                    fontSize: 13.5.sp,
                    color: k.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One entry in the open list: × to remove (swipe works too).
class _LogRow extends GetView<IntakeController> {
  const _LogRow({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final title = controller.entryTitle(entry);
    return Dismissible(
      key: ValueKey('log-${entry.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.removeWithUndo(entry),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 12.sp),
        color: AppColors.dangerSoft,
        child: Icon(
          PhosphorIconsBold.trash,
          size: 18.sp,
          color: AppColors.danger,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: k.card,
          border: Border(top: BorderSide(color: k.border)),
        ),
        padding: EdgeInsets.symmetric(vertical: 6.sp),
        child: Row(
          children: [
            SizedBox(
              width: 64.sp,
              child: Text(
                controller.timeOf(entry.at),
                style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 13.5.sp,
                  color: k.text,
                ),
              ),
            ),
            SizedBox(width: 8.sp),
            Text(
              '+${entry.amount} g',
              style: AppText.title.copyWith(fontSize: 13.5.sp, color: k.text),
            ),
            SizedBox(width: 6.sp),
            CircleIconButton(
              icon: PhosphorIconsBold.x,
              label: 'Remove $title',
              size: 34.sp,
              background: k.bg,
              foreground: k.muted,
              onTap: () => controller.removeWithUndo(entry),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------- search + custom

class _SearchField extends GetView<IntakeController> {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.watch();
      return TextField(
        controller: controller.searchCtrl,
        onChanged: (v) => controller.query.value = v,
        textInputAction: TextInputAction.search,
        style: AppText.bodyStrong.copyWith(fontSize: 14.5.sp, color: k.text),
        decoration: InputDecoration(
          hintText: 'Search foods',
          prefixIcon: Icon(Icons.search_rounded, size: 20.sp, color: k.muted),
          suffixIcon: controller.query.value.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(PhosphorIconsBold.x, size: 16.sp, color: k.muted),
                  onPressed: () {
                    controller.searchCtrl.clear();
                    controller.query.value = '';
                  },
                ),
        ),
      );
    });
  }
}

class _CustomButton extends GetView<IntakeController> {
  const _CustomButton();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final fg = dark ? AppColors.ink : AppColors.lime;
    return Semantics(
      button: true,
      label: 'Add your own food',
      excludeSemantics: true,
      child: PressScale(
        pressedScale: 0.94,
        onTap: () => controller.openCustom(),
        child: Container(
          constraints: BoxConstraints(minHeight: 48.sp),
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark ? AppColors.lime : AppColors.ink,
            borderRadius: BorderRadius.circular(16.sp),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsBold.plus, size: 16.sp, color: fg),
              SizedBox(width: 6.sp),
              Text(
                'Custom',
                style: AppText.title.copyWith(fontSize: 14.5.sp, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends GetView<IntakeController> {
  const _Results();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.watch();
      final q = controller.query.value.trim();
      final list = controller.searchResults;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const IntakeLabel('Results'),
          if (list.isEmpty)
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(22.sp),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No match for "$q".',
                    style: AppText.small.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: k.muted,
                    ),
                  ),
                  SizedBox(height: 12.sp),
                  SoftButton(
                    label: 'Add "$q" as your own',
                    height: 48,
                    background: k.text,
                    foreground: k.bg,
                    onPressed: () => controller.openCustom(name: q),
                  ),
                ],
              ),
            )
          else
            IntakeCard(
              children: [
                for (final f in list)
                  FoodRow(
                    food: f,
                    onLongPress: f.cat == 'mine'
                        ? () => controller.editMyFood(f)
                        : null,
                  ),
              ],
            ),
        ],
      );
    });
  }
}

// ----------------------------------------------------------------- sections

class _Suggested extends GetView<IntakeController> {
  const _Suggested({super.key});

  static Food _asFood(BiteIdea i) => Food(
    i.id,
    i.name,
    i.grams,
    i.icon,
    portion: i.portion,
    cat: switch (i.src) {
      FoodSrc.dairy => 'dairy',
      FoodSrc.egg => 'egg',
      FoodSrc.meat => 'meat',
      FoodSrc.fish => 'fish',
      FoodSrc.plant => 'beans',
    },
    src: i.src,
  );

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Obx(() {
      controller.watch();
      final bite = controller.bite;
      final ideas = controller.biteIdeas;
      final tip = bite?.tip;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bite != null && ideas.isNotEmpty) ...[
            SizedBox(height: 16.sp),
            Row(
              children: [
                const KTag('NEXT BITE', bg: AppColors.lime, fg: AppColors.ink),
                SizedBox(width: 8.sp),
                Expanded(
                  child: Text(
                    bite.context,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: k.muted,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Why these ideas?',
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: controller.showBiteWhy,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.sp,
                        vertical: 8.sp,
                      ),
                      child: Text(
                        'Why?',
                        style: AppText.title.copyWith(
                          fontSize: 13.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.sp),
            IntakeCard(
              children: [
                for (final (i, idea) in ideas.indexed)
                  AnimatedSwitcher(
                    key: ValueKey('slot$i'),
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    ),
                    child: FoodRow(
                      key: ValueKey(idea.id),
                      food: _asFood(idea),
                      onAdd: () => controller.addIdea(idea),
                    ),
                  ),
              ],
            ),
            if (!controller.biteUnlocked) ...[
              SizedBox(height: 8.sp),
              _PlusRow(onTap: controller.openPlus),
            ],
          ],
          const IntakeLabel('Your usual', trailing: 'Tap a food for more'),
          IntakeCard(
            children: [for (final f in controller.usualFoods) FoodRow(food: f)],
          ),
          if (tip != null && tip.isNotEmpty) ...[
            SizedBox(height: 12.sp),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 11.sp),
              decoration: BoxDecoration(
                color: dark ? k.cardAlt : AppColors.limeSoft,
                borderRadius: BorderRadius.circular(14.sp),
              ),
              child: Text(
                tip,
                style: AppText.small.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: dark ? k.text : AppColors.limeText,
                ),
              ),
            ),
          ],
          SizedBox(height: 10.sp),
          Text(
            'Ideas only, not medical advice.',
            style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint),
          ),
        ],
      );
    });
  }
}

class _PlusRow extends StatelessWidget {
  const _PlusRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'More ideas with Plus',
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
                  '2 more ideas + a plan for low-appetite days',
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

class _MyFoods extends GetView<IntakeController> {
  const _MyFoods({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.watch();
      final mine = controller.tracker.myFoods;
      if (mine.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(top: 16.sp),
          child: Container(
            padding: EdgeInsets.fromLTRB(20.sp, 22.sp, 20.sp, 20.sp),
            decoration: BoxDecoration(
              color: k.card,
              borderRadius: BorderRadius.circular(22.sp),
            ),
            child: Column(
              children: [
                ThreeD(Img3d.bowl, size: 44.sp),
                SizedBox(height: 8.sp),
                Text(
                  'Your own foods live here',
                  textAlign: TextAlign.center,
                  style: AppText.h2.copyWith(fontSize: 19.sp, color: k.text),
                ),
                SizedBox(height: 6.sp),
                Text(
                  'Your protein bar, your yogurt, a meal you make often. Save it once, then add it with one tap.',
                  textAlign: TextAlign.center,
                  style: AppText.small.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: k.muted,
                  ),
                ),
                SizedBox(height: 16.sp),
                SoftButton(
                  label: 'Create a food',
                  icon: PhosphorIconsBold.plus,
                  height: 48,
                  background: k.text,
                  foreground: k.bg,
                  onPressed: () => controller.openCustom(),
                ),
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const IntakeLabel('Saved by you', trailing: 'Hold to edit'),
          IntakeCard(
            children: [
              for (final f in mine)
                FoodRow(food: f, onLongPress: () => controller.editMyFood(f)),
              _CreateRow(onTap: () => controller.openCustom()),
            ],
          ),
        ],
      );
    });
  }
}

class _CreateRow extends StatelessWidget {
  const _CreateRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      label: 'Create a food',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
          child: Row(
            children: [
              Container(
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.sp),
                  border: Border.all(color: k.border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(PhosphorIconsBold.plus, size: 16.sp, color: k.text),
              ),
              SizedBox(width: 12.sp),
              Text(
                'Create a food',
                style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllFoods extends GetView<IntakeController> {
  const _AllFoods({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.watch();
      final diet = controller.dietName;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 14.sp),
          if (diet != null) ...[
            Text(
              'Showing $diet foods',
              style: AppText.small.copyWith(fontSize: 12.5.sp, color: k.faint),
            ),
            SizedBox(height: 8.sp),
          ],
          SizedBox(
            height: 38.sp,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                for (final (id, label) in controller.categories) ...[
                  _CatChip(
                    label: label,
                    selected: controller.category.value == id,
                    onTap: () => controller.pickCategory(id),
                  ),
                  SizedBox(width: 8.sp),
                ],
              ],
            ),
          ),
          for (final (label, foods) in controller.foodGroups) ...[
            IntakeLabel(label, top: 18),
            IntakeCard(children: [for (final f in foods) FoodRow(food: f)]),
          ],
          SizedBox(height: 12.sp),
          Text(
            'Protein values are typical for the portion shown. Labels and recipes vary.',
            style: AppText.small.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: k.faint,
            ),
          ),
        ],
      );
    });
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38.sp,
          padding: EdgeInsets.symmetric(horizontal: 14.sp),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? k.text : k.card,
            borderRadius: BorderRadius.circular(19.sp),
          ),
          child: Text(
            label,
            style: AppText.small.copyWith(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: selected ? k.bg : k.textSoft,
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- food row

/// One food everywhere on the Protein screen. Tap the row for ½ to 3
/// portions, tap + for one portion. Once added, "− 2×" shows so it can be
/// taken off right here.
class FoodRow extends GetView<IntakeController> {
  const FoodRow({super.key, required this.food, this.onAdd, this.onLongPress});

  final Food food;

  /// Overrides the plain add (Next bite ideas track what was added).
  final VoidCallback? onAdd;
  final VoidCallback? onLongPress;

  Color _tint(BuildContext context) {
    final k = context.k;
    if (k.selectedBorder == AppColors.lime) return k.cardAlt;
    return switch (food.cat) {
      'dairy' || 'shake' || 'fish' => AppColors.aquaSoft,
      'beans' || 'meal' || 'meat' => AppColors.tangerineSoft,
      'snack' || 'soy' => AppColors.limeSoft,
      _ => AppColors.amberSoft,
    };
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final count = controller.countOf(food);
    final portion = food.portion.isEmpty ? '' : '${food.portion} · ';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: count > 0
          ? (dark ? k.cardAlt : AppColors.limeSoft.withValues(alpha: 0.5))
          : k.card,
      padding: EdgeInsets.fromLTRB(14.sp, 10.sp, 10.sp, 10.sp),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label:
                  '${food.name}, ${food.portion}, ${food.grams} grams protein. Choose portion${onLongPress != null ? '. Hold to edit' : ''}',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(14.sp),
                onTap: () => controller.openPortion(food),
                onLongPress: onLongPress,
                child: Row(
                  children: [
                    Container(
                      width: 42.sp,
                      height: 42.sp,
                      decoration: BoxDecoration(
                        color: _tint(context),
                        borderRadius: BorderRadius.circular(14.sp),
                      ),
                      alignment: Alignment.center,
                      child: ThreeD(food.icon, size: 28.sp),
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(
                              fontSize: 14.5.sp,
                              color: k.text,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: portion),
                                TextSpan(
                                  text: '${food.grams} g',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: k.text,
                                  ),
                                ),
                              ],
                            ),
                            style: AppText.small.copyWith(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: k.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 6.sp),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: count == 0
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleIconButton(
                        icon: PhosphorIconsBold.minus,
                        label: 'Remove one ${food.name}',
                        size: 34.sp,
                        background: k.card,
                        onTap: () => controller.removeOneOf(food),
                      ),
                      SizedBox(
                        width: 30.sp,
                        child: Text(
                          '$count×',
                          textAlign: TextAlign.center,
                          style: AppText.title.copyWith(
                            fontSize: 14.sp,
                            color: k.text,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          PressScale(
            pressedScale: 0.88,
            semanticLabel: 'Add ${food.name}, ${food.grams} grams',
            onTap: onAdd ?? () => controller.addFood(food),
            child: Container(
              width: 40.sp,
              height: 40.sp,
              decoration: BoxDecoration(
                color: dark ? AppColors.lime : AppColors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                PhosphorIconsBold.plus,
                size: 17.sp,
                color: dark ? AppColors.ink : AppColors.lime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
