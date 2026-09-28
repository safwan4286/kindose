import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'intake_controller.dart';
import 'widgets/water_drop.dart';

/// Protein and water. One tap adds, every add can be undone.
class IntakeScreen extends GetView<IntakeController> {
  const IntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
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
                  // One screen per card: Protein or Water (no tabs).
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        controller.isProtein ? 'Protein' : 'Water',
                        style: AppText.h2.copyWith(fontSize: 22.sp, color: k.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  child: controller.isProtein
                      ? const _ProteinTab(key: ValueKey('protein'))
                      : const _WaterTab(key: ValueKey('water')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ shared

TextStyle _caps(BuildContext c) => AppText.caps.copyWith(
  fontSize: 12.sp,
  letterSpacing: 1.1,
  color: c.k.muted,
);

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 22.sp, bottom: 10.sp),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text.toUpperCase(), style: _caps(context)),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppText.small.copyWith(
                fontSize: 12.5.sp,
                color: context.k.faint,
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: k.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _EntryList extends GetView<IntakeController> {
  const _EntryList({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.watch();
      return _build(context);
    });
  }

  Widget _build(BuildContext context) {
    final k = context.k;
    final entries = controller.entriesFor(kind);
    if (entries.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(22.sp),
        ),
        child: Text(
          kind == 'protein'
              ? 'Nothing yet today. Tap + on a food to add it.'
              : 'Nothing yet today. Tap a glass to add it.',
          style: AppText.small.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: k.muted,
          ),
        ),
      );
    }
    final valueColor = kind == 'protein'
        ? AppColors.tangerineText
        : AppColors.aquaText;
    final dark = k.selectedBorder == AppColors.lime;
    return _Card(
      children: [
        for (final e in entries)
          Dismissible(
            key: ValueKey(e.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => controller.removeEntry(e),
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 18.sp),
              color: AppColors.dangerSoft,
              child: Icon(
                PhosphorIconsBold.trash,
                size: 20.sp,
                color: AppColors.danger,
              ),
            ),
            child: _EntryRow(entry: e, valueColor: dark ? k.text : valueColor),
          ),
      ],
    );
  }
}

class _EntryRow extends GetView<IntakeController> {
  const _EntryRow({required this.entry, required this.valueColor});

  final LogEntry entry;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final unit = entry.isProtein ? 'g' : 'ml';
    final title = controller.entryTitle(entry);
    return Semantics(
      label:
          '${controller.timeOf(entry.at)}, $title, ${entry.amount} $unit. Swipe left to remove.',
      excludeSemantics: true,
      child: Container(
        color: k.card,
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        child: Row(
          children: [
            SizedBox(
              width: 66.sp,
              child: Text(
                controller.timeOf(entry.at),
                style: AppText.small.copyWith(
                  fontSize: 12.5.sp,
                  color: k.faint,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 14.5.sp,
                  color: k.text,
                ),
              ),
            ),
            SizedBox(width: 8.sp),
            Text(
              '+${entry.amount} $unit',
              style: AppText.title.copyWith(
                fontSize: 14.5.sp,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- protein

class _ProteinTab extends GetView<IntakeController> {
  const _ProteinTab({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final k = context.k;
    return Obx(() {
      controller.watch();
      final searching = controller.query.value.trim().isNotEmpty;
      final browse = controller.browseFoods;
      final diet = controller.dietName;
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20.sp, 18.sp, 20.sp, 32.sp),
        children: [
          const _ProteinHero().enter(motion),
          SizedBox(height: 14.sp),
          const _SearchField().enter(motion, delay: 60),
          if (!searching) ...[
            _Label(
              'Your usual',
              trailing: 'Tap + to add',
            ).enter(motion, delay: 100),
            _Card(
              children: [
                for (final f in controller.usualFoods)
                  _FoodRow(food: f, strong: true),
              ],
            ).enter(motion, delay: 120),
            _Label(diet == null ? 'Browse' : 'Browse · $diet'),
            SizedBox(
              height: 40.sp,
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
            SizedBox(height: 10.sp),
          ] else
            _Label('Results'),
          if (browse.isEmpty)
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(22.sp),
              ),
              child: Text(
                'No match. Add it by grams below.',
                style: AppText.small.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: k.muted,
                ),
              ),
            )
          else
            _Card(children: [for (final f in browse) _FoodRow(food: f)]),
          SizedBox(height: 12.sp),
          const _CustomProtein(),
          _Label('Today', trailing: 'Swipe left to remove'),
          const _EntryList(kind: 'protein'),
          SizedBox(height: 12.sp),
          Text(
            'Protein values are typical amounts for the portion shown. Labels and recipes vary.',
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

class _ProteinHero extends GetView<IntakeController> {
  const _ProteinHero();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.watch();
      final total = controller.proteinToday;
      return Semantics(
        label:
            'Protein today: $total of ${controller.proteinGoal} grams. ${controller.proteinLine}',
        excludeSemantics: true,
        child: Container(
          padding: EdgeInsets.all(18.sp),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(24.sp),
          ),
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
                          'PROTEIN TODAY',
                          style: _caps(context).copyWith(color: k.faint),
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
                  ThreeD(Img3d.biceps, size: 52.sp),
                ],
              ),
              SizedBox(height: 14.sp),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.sp),
                child: SizedBox(
                  height: 12.sp,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: k.proteinTrack)),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: controller.proteinProgress),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => FractionallySizedBox(
                          widthFactor: v,
                          heightFactor: 1,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.tangerine,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      );
    });
  }
}

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
          hintText: 'Search foods: paneer, dal…',
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

/// One food: tap + to add a serving, tap the row for ½ / 1 / 1½ / 2.
class _FoodRow extends GetView<IntakeController> {
  const _FoodRow({required this.food, this.strong = false});

  final Food food;
  final bool strong;

  Color _tint(BuildContext context) {
    final k = context.k;
    if (k.selectedBorder == AppColors.lime) return k.cardAlt;
    return switch (food.cat) {
      'dairy' || 'shake' => AppColors.aquaSoft,
      'dal' || 'meal' || 'meat' => AppColors.tangerineSoft,
      'snack' || 'soy' => AppColors.limeSoft,
      _ => AppColors.amberSoft,
    };
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final open = controller.openFood.value == food.id;
    final times = controller.portion.value;
    final dark = k.selectedBorder == AppColors.lime;
    return Container(
      color: k.card,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.sp, 10.sp, 10.sp, 10.sp),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    expanded: open,
                    label:
                        '${food.name}, ${food.portion}, ${food.grams} grams protein. Choose portion',
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14.sp),
                      onTap: () => controller.toggleFood(food),
                      child: Row(
                        children: [
                          Container(
                            width: (strong ? 44 : 40).sp,
                            height: (strong ? 44 : 40).sp,
                            decoration: BoxDecoration(
                              color: _tint(context),
                              borderRadius: BorderRadius.circular(14.sp),
                            ),
                            alignment: Alignment.center,
                            child: ThreeD(
                              food.icon,
                              size: (strong ? 30 : 26).sp,
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: AppText.title.copyWith(
                                    fontSize: (strong ? 15 : 14.5).sp,
                                    color: k.text,
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: '${food.portion} · '),
                                      TextSpan(
                                        text: strong
                                            ? '${food.grams} g protein'
                                            : '${food.grams} g',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: strong && !dark
                                              ? AppColors.tangerineText
                                              : null,
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
                _AddButton(
                  strong: strong,
                  label: 'Add ${food.name}, ${food.grams} grams',
                  onTap: () => controller.addFood(food),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.fromLTRB(14.sp, 0, 10.sp, 12.sp),
                    child: Row(
                      children: [
                        for (final p in IntakeController.portions) ...[
                          Semantics(
                            button: true,
                            selected: p.times == times,
                            label: '${p.label} serving',
                            excludeSemantics: true,
                            child: PressScale(
                              onTap: () => controller.pickPortion(p.times),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                constraints: BoxConstraints(minWidth: 44.sp),
                                height: 36.sp,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: k.bg,
                                  borderRadius: BorderRadius.circular(18.sp),
                                  border: Border.all(
                                    color: p.times == times
                                        ? k.selectedBorder
                                        : k.bg,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  p.label,
                                  style: AppText.small.copyWith(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: k.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.sp),
                        ],
                        const Spacer(),
                        PressScale(
                          semanticLabel:
                              'Add ${controller.gramsFor(food, times)} grams',
                          onTap: () => controller.addFood(food, times),
                          child: Container(
                            height: 36.sp,
                            padding: EdgeInsets.symmetric(horizontal: 14.sp),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(18.sp),
                            ),
                            child: Text(
                              'Add ${controller.gramsFor(food, times)} g',
                              style: AppText.small.copyWith(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
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

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.strong,
    required this.label,
    required this.onTap,
  });

  final bool strong;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final size = (strong ? 44 : 40).sp;
    final bg = strong ? (dark ? AppColors.lime : AppColors.ink) : k.card;
    final fg = strong ? (dark ? AppColors.ink : AppColors.lime) : k.text;
    return PressScale(
      pressedScale: 0.88,
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: strong ? null : Border.all(color: k.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          PhosphorIconsBold.plus,
          size: (strong ? 18 : 16).sp,
          color: fg,
        ),
      ),
    );
  }
}

class _CustomProtein extends GetView<IntakeController> {
  const _CustomProtein();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      controller.watch();
      return Container(
        padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 12.sp, 12.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(20.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Know the grams?',
              style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text),
            ),
            Text(
              'From a food label or your dietitian',
              style: AppText.small.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: k.muted,
              ),
            ),
            SizedBox(height: 10.sp),
            Row(
              children: [
                CircleIconButton(
                  icon: PhosphorIconsBold.minus,
                  label: '5 grams less',
                  background: k.bg,
                  onTap: controller.customGrams.value <= 1
                      ? null
                      : () => controller.stepCustom(-5),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '${controller.customGrams.value} grams. Tap to type',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => controller.typeCustom(context),
                      child: Text(
                        '${controller.customGrams.value} g',
                        textAlign: TextAlign.center,
                        style: AppText.number(24.sp).copyWith(color: k.text),
                      ),
                    ),
                  ),
                ),
                CircleIconButton(
                  icon: PhosphorIconsBold.plus,
                  label: '5 grams more',
                  background: k.bg,
                  onTap: controller.customGrams.value >= 200
                      ? null
                      : () => controller.stepCustom(5),
                ),
                SizedBox(width: 10.sp),
                SoftButton(
                  label: 'Add',
                  height: 44,
                  background: k.text,
                  foreground: k.bg,
                  onPressed: controller.addCustomProtein,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ------------------------------------------------------------------- water

class _WaterTab extends GetView<IntakeController> {
  const _WaterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final k = context.k;
    return Obx(() {
      controller.watch();
      final dark = k.selectedBorder == AppColors.lime;
      final tileBg = dark ? k.card : AppColors.aquaSoft;
      return ListView(
        padding: EdgeInsets.fromLTRB(20.sp, 18.sp, 20.sp, 32.sp),
        children: [
          Semantics(
            label:
                'Water today: ${controller.litres(controller.waterToday)} of ${controller.litres(controller.waterGoal)} litres. ${controller.waterLine}',
            excludeSemantics: true,
            child: Container(
              padding: EdgeInsets.fromLTRB(18.sp, 20.sp, 18.sp, 20.sp),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(24.sp),
              ),
              child: Row(
                children: [
                  WaterDrop(
                    size: 128.sp,
                    fill: controller.waterProgress,
                    animate: motion,
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WATER TODAY',
                          style: _caps(context).copyWith(color: k.faint),
                        ),
                        SizedBox(height: 6.sp),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 5.sp,
                          children: [
                            Text(
                              controller.litres(controller.waterToday),
                              style: AppText.number(
                                40.sp,
                              ).copyWith(color: k.text),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 3.sp),
                              child: Text(
                                'of ${controller.litres(controller.waterGoal)} L',
                                style: AppText.title.copyWith(
                                  fontSize: 15.sp,
                                  color: k.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.sp),
                        Text(
                          controller.waterLine,
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            color: dark ? AppColors.aqua : AppColors.aquaText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).enter(motion),
          const _Label('Add water', trailing: 'One tap adds it'),
          Row(
            children: [
              for (final (i, d) in Catalog.waterSizes.indexed) ...[
                if (i > 0) SizedBox(width: 8.sp),
                Expanded(
                  child: _WaterTile(
                    label: d.label,
                    level: i,
                    bg: tileBg,
                    semantic:
                        'Add ${d.label.toLowerCase()}, ${d.ml} millilitres',
                    onTap: () => controller.addDrink(d),
                  ),
                ),
              ],
              SizedBox(width: 8.sp),
              Expanded(
                child: _WaterTile(
                  label: 'Custom',
                  level: -1,
                  bg: tileBg,
                  semantic: 'Add a custom amount',
                  onTap: () => controller.addCustomWater(context),
                ),
              ),
            ],
          ).enter(motion, delay: 80),
          const _Label('Other drinks count too'),
          Wrap(
            spacing: 8.sp,
            runSpacing: 8.sp,
            children: [
              for (final d in controller.otherDrinks)
                PressScale(
                  semanticLabel:
                      'Add ${d.label.toLowerCase()}, ${d.ml} millilitres',
                  onTap: () => controller.addDrink(d),
                  child: Container(
                    height: 40.sp,
                    padding: EdgeInsets.symmetric(horizontal: 14.sp),
                    decoration: BoxDecoration(
                      color: k.card,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(color: k.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          d.label,
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                        Text(
                          ' · ${d.ml} ml',
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: k.faint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ).enter(motion, delay: 120),
          SizedBox(height: 16.sp),
          Container(
            padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 16.sp, 14.sp),
            decoration: BoxDecoration(
              color: k.cardAlt,
              borderRadius: BorderRadius.circular(18.sp),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThreeD(Img3d.droplet, size: 30.sp),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Small sips, often. ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'Many people feel less thirsty on these medicines, so a glass at each meal and between meals helps.',
                        ),
                      ],
                    ),
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: k.textSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _Label('Today', trailing: 'Swipe left to remove'),
          const _EntryList(kind: 'water'),
          if (controller.entriesFor('water').isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: LinkButton(
                label: 'Undo last',
                color: k.text,
                onTap: () => controller.undoLast('water'),
              ),
            ),
        ],
      );
    });
  }
}

class _WaterTile extends StatelessWidget {
  const _WaterTile({
    required this.label,
    required this.level,
    required this.bg,
    required this.semantic,
    required this.onTap,
  });

  final String label;

  /// 0 glass, 1 bottle, 2 litre, -1 custom.
  final int level;
  final Color bg;
  final String semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final h = switch (level) {
      1 => 28.0,
      2 => 32.0,
      _ => 24.0,
    };
    return PressScale(
      pressedScale: 0.94,
      semanticLabel: semantic,
      onTap: onTap,
      child: Container(
        height: 96.sp,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.sp),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32.sp,
              child: Center(
                child: level < 0
                    ? Icon(
                        PhosphorIconsBold.pencilSimple,
                        size: 22.sp,
                        color: AppColors.aqua,
                      )
                    : CustomPaint(
                        size: Size((h * 0.75).sp, h.sp),
                        painter: const _GlassPainter(),
                      ),
              ),
            ),
            SizedBox(height: 6.sp),
            Text(
              label,
              style: AppText.small.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: k.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glass = Path()
      ..moveTo(w * 0.08, h * 0.06)
      ..lineTo(w * 0.92, h * 0.06)
      ..lineTo(w * 0.8, h * 0.96)
      ..lineTo(w * 0.2, h * 0.96)
      ..close();
    canvas.drawPath(glass, Paint()..color = AppColors.white);
    canvas.save();
    canvas.clipPath(glass);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.42, w, h),
      Paint()..color = AppColors.aqua,
    );
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.aqua,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => false;
}
