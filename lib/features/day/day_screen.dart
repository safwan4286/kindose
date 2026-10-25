import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../resources/water_units.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/day_switcher.dart';
import '../../widgets/entry_tile.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'day_controller.dart';

/// One day at a glance. Past days: the last 4 weeks free, older with Plus.
class DayScreen extends GetView<DayController> {
  const DayScreen({super.key});

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
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 10.sp),
              child: Row(
                children: [
                  BackCircle(onTap: popRoute),
                  const Spacer(),
                  DaySwitcher(nav: controller),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                controller.watch();
                // The page already slides in, so the cards are there at
                // once (no staggered entrance on top). Switching days
                // cross-fades instead of jumping.
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: motion ? 180 : 0),
                  child: ListView(
                    key: ValueKey(controller.day.value),
                    padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 24.sp),
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          controller.longDate,
                          style: AppText.h1.copyWith(
                            fontSize: 28.sp,
                            height: 1.1,
                            color: k.text,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.sp),
                      _DoseSection(controller: controller),
                      SizedBox(height: 12.sp),
                      _ProteinSection(controller: controller),
                      SizedBox(height: 12.sp),
                      _WaterSection(controller: controller),
                      SizedBox(height: 12.sp),
                      _WeightSection(controller: controller),
                      SizedBox(height: 12.sp),
                      _FeelSection(controller: controller),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ pieces

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.tint,
    required this.title,
    required this.child,
    this.trailing,
  });

  /// A 3D icon (Img3d), the same ones the Log sheet and Today use.
  final String icon;
  final Color tint;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.sp,
                height: 34.sp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(11.sp),
                ),
                child: ThreeD(icon, size: 22.sp),
              ),
              SizedBox(width: 10.sp),
              Expanded(
                child: Text(
                  title,
                  style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: 10.sp),
          child,
        ],
      ),
    );
  }
}

Widget _muted(BuildContext context, String text) => Text(
  text,
  style: AppText.small.copyWith(fontSize: 13.5.sp, color: context.k.muted),
);

Widget _link(BuildContext context, String label, VoidCallback onTap) =>
    Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 32.sp),
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.k.cardAlt,
            borderRadius: BorderRadius.circular(16.sp),
          ),
          child: Text(
            label,
            style: AppText.small.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: context.k.text,
            ),
          ),
        ),
      ),
    );

// ------------------------------------------------------------------- dose

class _DoseSection extends StatelessWidget {
  const _DoseSection({required this.controller});

  final DayController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final has = controller.dose != null;
    return _Section(
      icon: Img3d.syringe,
      tint: AppColors.limeSoft,
      title: 'Dose',
      trailing: has
          ? _link(context, 'Edit', controller.editDose)
          : _link(context, 'Log', controller.logDoseForDay),
      child: has
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.doseTitle,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: k.text,
                  ),
                ),
                SizedBox(height: 2.sp),
                _muted(context, controller.doseLine),
              ],
            )
          : _muted(
              context,
              controller.isToday
                  ? 'No dose logged yet today.'
                  : 'No dose logged this day. Took one? Tap Log to add it.',
            ),
    );
  }
}

// ---------------------------------------------------------- protein, water

/// Big number, "of goal" and a Goal hit tag, used by protein and water.
class _Total extends StatelessWidget {
  const _Total({
    required this.value,
    required this.of,
    required this.hit,
    required this.tagBg,
    required this.tagFg,
  });

  final String value;
  final String of;
  final bool hit;
  final Color tagBg;
  final Color tagFg;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: AppText.number(32.sp).copyWith(color: k.text)),
        SizedBox(width: 6.sp),
        Expanded(
          child: Text(
            of,
            style: AppText.title.copyWith(fontSize: 15.sp, color: k.muted),
          ),
        ),
        if (hit) KTag('Goal hit', bg: tagBg, fg: tagFg),
      ],
    );
  }
}

/// Fully rounded track and fill; a little progress shows as a dot.
class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.track, required this.fill});

  final double value;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final h = 10.sp;
    final round = BorderRadius.circular(h / 2);
    return LayoutBuilder(
      builder: (_, box) => Container(
        height: h,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: track, borderRadius: round),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => v <= 0
              ? const SizedBox.shrink()
              : Container(
                  width: (box.maxWidth * v).clamp(h, box.maxWidth),
                  decoration: BoxDecoration(color: fill, borderRadius: round),
                ),
        ),
      ),
    );
  }
}

Widget _listLabel(
  BuildContext context,
  String text, {
  bool swipeHint = false,
}) => Padding(
  padding: EdgeInsets.only(top: 16.sp, bottom: 2.sp),
  child: Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: AppText.caps.copyWith(
            fontSize: 11.sp,
            letterSpacing: 1,
            color: context.k.faint,
          ),
        ),
      ),
      if (swipeHint)
        Text(
          'Swipe left to remove',
          style: AppText.small.copyWith(
            fontSize: 11.5.sp,
            color: context.k.faint,
          ),
        ),
    ],
  ),
);

class _ProteinSection extends StatelessWidget {
  const _ProteinSection({required this.controller});

  final DayController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final list = controller.proteinList;
    final total = controller.log.proteinG;
    final goal = controller.proteinGoal;
    final parts = controller.proteinByPart;
    final best = parts.fold<int>(0, (m, p) => p.$2 > m ? p.$2 : m);
    return _Section(
      icon: Img3d.biceps,
      tint: AppColors.tangerineSoft,
      title: 'Protein',
      trailing: _link(
        context,
        list.isEmpty ? 'Add' : 'Edit',
        () => controller.openIntake('protein'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: '$total of $goal grams protein. ${controller.proteinLine}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Total(
                  value: '$total',
                  of: 'of $goal g',
                  hit: goal > 0 && total >= goal,
                  tagBg: AppColors.tangerineSoft,
                  tagFg: AppColors.tangerineText,
                ),
                SizedBox(height: 10.sp),
                _Bar(
                  value: goal == 0 ? 0 : total / goal,
                  track: k.proteinTrack,
                  fill: AppColors.tangerine,
                ),
                SizedBox(height: 6.sp),
                Text(
                  list.isEmpty ? 'Nothing logged.' : controller.proteinLine,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: k.muted,
                  ),
                ),
              ],
            ),
          ),
          if (list.isNotEmpty) ...[
            SizedBox(height: 12.sp),
            Row(
              children: [
                for (final (i, (name, g)) in parts.indexed) ...[
                  if (i > 0) SizedBox(width: 8.sp),
                  Expanded(
                    child: Semantics(
                      label: '$name: ${g == 0 ? 'nothing' : '$g grams'}',
                      excludeSemantics: true,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.sp,
                          vertical: 9.sp,
                        ),
                        decoration: BoxDecoration(
                          color: g > 0 && g == best
                              ? (dark ? k.cardAlt : AppColors.tangerineSoft)
                              : k.bg,
                          borderRadius: BorderRadius.circular(14.sp),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                name.toUpperCase(),
                                style: AppText.caps.copyWith(
                                  fontSize: 10.5.sp,
                                  letterSpacing: 0.8,
                                  color: g > 0 && g == best && !dark
                                      ? AppColors.tangerineText
                                      : k.faint,
                                ),
                              ),
                            ),
                            SizedBox(height: 2.sp),
                            g == 0
                                ? Text(
                                    '—',
                                    style: AppText.number(20.sp)
                                        .copyWith(color: k.faint),
                                  )
                                : NumberUnit('$g', 'g', size: 20.sp),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            _listLabel(context, 'WHAT YOU HAD', swipeHint: true),
            for (final (i, e) in list.indexed)
              _FoodEntryRow(controller: controller, entry: e, first: i == 0),
          ],
        ],
      ),
    );
  }
}

class _FoodEntryRow extends StatelessWidget {
  const _FoodEntryRow({
    required this.controller,
    required this.entry,
    required this.first,
  });

  final DayController controller;
  final LogEntry entry;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final name = controller.entryName(entry);
    final portion = controller.entryPortion(entry);
    final time = controller.entryTime(entry);
    final icon = controller.foodIcon(entry);
    return SwipeToRemove(
      id: entry.id,
      onRemove: () => controller.removeEntry(entry),
      child: Semantics(
        label:
            '$name${portion.isEmpty ? '' : ', $portion'}, $time, ${entry.amount} grams. Swipe left to remove.',
        excludeSemantics: true,
        child: EntryTile(
          divider: !first,
          icon: icon,
          tint: dark ? k.cardAlt : DayController.tintFor(icon),
          title: name,
          sub: portion.isEmpty ? time : '$portion · $time',
          amount: '+${entry.amount} g',
          amountColor: dark ? k.text : AppColors.tangerineText,
        ),
      ),
    );
  }
}

class _WaterSection extends StatelessWidget {
  const _WaterSection({required this.controller});

  final DayController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final drinks = controller.waterList;
    final total = controller.log.waterMl;
    final goal = controller.waterGoal;
    return _Section(
      icon: Img3d.droplet,
      tint: AppColors.aquaSoft,
      title: 'Water',
      trailing: _link(
        context,
        drinks.isEmpty ? 'Add' : 'Edit',
        () => controller.openIntake('water'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label:
                '${controller.litres(total)} of ${controller.litres(goal)} ${Water.unitWords} water. ${controller.waterLine}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Total(
                  value: controller.litres(total),
                  of: 'of ${controller.litres(goal)} ${Water.unit}',
                  hit: goal > 0 && total >= goal,
                  tagBg: AppColors.aquaSoft,
                  tagFg: AppColors.aquaText,
                ),
                SizedBox(height: 10.sp),
                _Bar(
                  value: goal == 0 ? 0 : total / goal,
                  track: dark ? k.cardAlt : AppColors.aquaSoft,
                  fill: AppColors.aqua,
                ),
                SizedBox(height: 6.sp),
                Text(
                  drinks.isEmpty ? 'Nothing logged.' : controller.waterLine,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: k.muted,
                  ),
                ),
              ],
            ),
          ),
          if (drinks.isNotEmpty) ...[
            _listLabel(context, 'WHAT YOU DRANK', swipeHint: true),
            for (final (i, e) in drinks.indexed)
              _DrinkRow(controller: controller, entry: e, first: i == 0),
          ],
        ],
      ),
    );
  }
}

class _DrinkRow extends StatelessWidget {
  const _DrinkRow({
    required this.controller,
    required this.entry,
    required this.first,
  });

  final DayController controller;
  final LogEntry entry;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final name = controller.entryName(entry);
    final amount = Water.amount(entry.amount);
    final time = controller.entryTime(entry);
    final icon = controller.drinkIcon(entry);
    return SwipeToRemove(
      id: entry.id,
      onRemove: () => controller.removeEntry(entry),
      child: Semantics(
        label: '$name, $amount, $time. Swipe left to remove.',
        excludeSemantics: true,
        child: EntryTile(
          divider: !first,
          icon: icon,
          tint: dark ? k.cardAlt : DayController.tintFor(icon),
          title: name,
          sub: time,
          amount: '+$amount',
          amountColor: dark ? k.text : AppColors.aquaText,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- weight

class _WeightSection extends StatelessWidget {
  const _WeightSection({required this.controller});

  final DayController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final w = controller.weighIn;
    return _Section(
      icon: Img3d.chartDown,
      tint: AppColors.violetSoft,
      title: 'Weight',
      trailing: _link(
        context,
        w == null ? 'Log' : 'Edit',
        controller.logWeightForDay,
      ),
      child: w == null
          ? _muted(context, 'No weigh-in this day.')
          : Text(
              controller.weightLabel(w.kg),
              style: AppText.bodyStrong.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: k.text,
              ),
            ),
    );
  }
}

// ------------------------------------------------------------ how it felt

class _FeelSection extends StatelessWidget {
  const _FeelSection({required this.controller});

  final DayController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;
    final chips = [...c.effects, ...c.scales];
    return _Section(
      icon: Img3d.nauseated,
      tint: AppColors.limeSoft,
      title: 'How I felt',
      trailing: _link(
        context,
        c.hasCheckIn ? 'Edit' : 'Check in',
        c.openCheckIn,
      ),
      child: !c.hasCheckIn
          ? _muted(
              context,
              c.isToday ? 'No check-in yet today.' : 'No check-in this day.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.moodLabel != null)
                  Row(
                    children: [
                      if (c.moodIcon != null) ...[
                        ThreeD(c.moodIcon!, size: 26.sp),
                        SizedBox(width: 8.sp),
                      ],
                      Text(
                        c.moodLabel!,
                        style: AppText.bodyStrong.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: k.text,
                        ),
                      ),
                    ],
                  ),
                if (chips.isNotEmpty) ...[
                  SizedBox(height: 8.sp),
                  Wrap(
                    spacing: 6.sp,
                    runSpacing: 6.sp,
                    children: [
                      for (final t in chips)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.sp,
                            vertical: 5.sp,
                          ),
                          decoration: BoxDecoration(
                            color: k.cardAlt,
                            borderRadius: BorderRadius.circular(12.sp),
                          ),
                          child: Text(
                            t,
                            style: AppText.small.copyWith(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: k.text,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (c.log.note?.isNotEmpty ?? false) ...[
                  SizedBox(height: 8.sp),
                  Text(
                    '“${c.log.note}”',
                    style: AppText.bodyText.copyWith(
                      fontSize: 13.5.sp,
                      fontStyle: FontStyle.italic,
                      color: k.muted,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
