import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/logs.dart';
import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/day_switcher.dart';
import '../../widgets/entrance.dart';
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
                return ListView(
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
                    ).enter(motion),
                    SizedBox(height: 16.sp),
                    _DoseSection(
                      controller: controller,
                    ).enter(motion, delay: 40),
                    SizedBox(height: 12.sp),
                    _ProteinSection(
                      controller: controller,
                    ).enter(motion, delay: 80),
                    SizedBox(height: 12.sp),
                    _WaterSection(
                      controller: controller,
                    ).enter(motion, delay: 120),
                    SizedBox(height: 12.sp),
                    _WeightSection(
                      controller: controller,
                    ).enter(motion, delay: 160),
                    SizedBox(height: 12.sp),
                    _FeelSection(
                      controller: controller,
                    ).enter(motion, delay: 200),
                  ],
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

  final IconData icon;
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
                child: Icon(icon, size: 17.sp, color: AppColors.ink),
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
      icon: PhosphorIconsBold.syringe,
      tint: AppColors.lime,
      title: 'Dose',
      trailing: has ? _link(context, 'Edit', controller.editDose) : null,
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
          : _muted(context, 'No dose logged this day.'),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.track, required this.fill});

  final double value;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.sp),
      child: SizedBox(
        height: 10.sp,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: ColoredBox(color: fill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _listLabel(BuildContext context, String text, {bool swipeHint = false}) =>
    Padding(
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
              style: AppText.small.copyWith(fontSize: 11.5.sp, color: context.k.faint),
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
      icon: PhosphorIconsBold.egg,
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
                        padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 9.sp),
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
                            Text(
                              g == 0 ? '—' : '$g g',
                              style: AppText.number(17.sp).copyWith(
                                color: g == 0 ? k.faint : k.text,
                              ),
                            ),
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
    return _Swipe(
      id: entry.id,
      onRemove: () => controller.removeEntry(entry),
      child: Semantics(
        label: '$name${portion.isEmpty ? '' : ', $portion'}, $time, ${entry.amount} grams. Swipe left to remove.',
        excludeSemantics: true,
        child: _EntryTile(
          first: first,
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
    final groups = controller.waterGroups;
    final total = controller.log.waterMl;
    final goal = controller.waterGoal;
    final done = controller.glassesDone;
    return _Section(
      icon: PhosphorIconsBold.drop,
      tint: AppColors.aquaSoft,
      title: 'Water',
      trailing: _link(
        context,
        groups.isEmpty ? 'Add' : 'Edit',
        () => controller.openIntake('water'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label:
                '${controller.litres(total)} of ${controller.litres(goal)} litres water. ${controller.waterLine}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Total(
                  value: controller.litres(total),
                  of: 'of ${controller.litres(goal)} L',
                  hit: goal > 0 && total >= goal,
                  tagBg: AppColors.aquaSoft,
                  tagFg: AppColors.aquaText,
                ),
                SizedBox(height: 12.sp),
                Row(
                  children: [
                    for (var i = 0; i < controller.glassesGoal; i++) ...[
                      if (i > 0) SizedBox(width: 5.sp),
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 250 + i * 30),
                          height: 30.sp,
                          decoration: BoxDecoration(
                            color: i < done
                                ? AppColors.aqua
                                : (dark ? k.cardAlt : AppColors.aquaSoft),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6.sp),
                              bottom: Radius.circular(9.sp),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6.sp),
                Text(
                  groups.isEmpty ? 'Nothing logged.' : controller.waterLine,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: k.muted,
                  ),
                ),
              ],
            ),
          ),
          if (groups.isNotEmpty) ...[
            _listLabel(context, 'WHAT YOU DRANK', swipeHint: true),
            for (final (i, g) in groups.indexed)
              _DrinkRow(controller: controller, group: g, first: i == 0),
          ],
        ],
      ),
    );
  }
}

class _DrinkRow extends StatelessWidget {
  const _DrinkRow({
    required this.controller,
    required this.group,
    required this.first,
  });

  final DayController controller;
  final DrinkGroup group;
  final bool first;

  String _amount(int ml) => ml >= 1000 ? '${controller.litres(ml)} L' : '$ml ml';

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final n = group.entries.length;
    final newest = group.entries.first;
    final oldest = group.entries.last;
    final time = n == 1
        ? controller.entryTime(newest)
        : '${controller.entryTime(oldest)} – ${controller.entryTime(newest)}';
    final sub = n == 1 ? '${group.each} ml · $time' : '${group.each} ml each · $time';
    return _Swipe(
      id: 'g-${newest.id}',
      onRemove: () => controller.removeEntry(newest),
      child: Semantics(
        label:
            '${group.name}${n > 1 ? ' times $n' : ''}, $sub, ${_amount(group.total)}. Swipe left to remove the latest.',
        excludeSemantics: true,
        child: _EntryTile(
          first: first,
          icon: group.icon,
          tint: dark ? k.cardAlt : DayController.tintFor(group.icon),
          title: group.name,
          count: n > 1 ? n : null,
          sub: sub,
          amount: '+${_amount(group.total)}',
          amountColor: dark ? k.text : AppColors.aquaText,
        ),
      ),
    );
  }
}

/// Swipe left to remove, with the red trash background.
class _Swipe extends StatelessWidget {
  const _Swipe({required this.id, required this.onRemove, required this.child});

  final String id;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 12.sp),
        color: AppColors.dangerSoft,
        child: Icon(PhosphorIconsBold.trash, size: 18.sp, color: AppColors.danger),
      ),
      child: child,
    );
  }
}

/// Icon, name (+ "× 4"), sub line and amount. Name and sub never share a
/// line, so long food names don't push the amount off.
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.first,
    required this.icon,
    required this.tint,
    required this.title,
    required this.sub,
    required this.amount,
    required this.amountColor,
    this.count,
  });

  final bool first;
  final String icon;
  final Color tint;
  final String title;
  final String sub;
  final String amount;
  final Color amountColor;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      decoration: BoxDecoration(
        color: k.card,
        border: first ? null : Border(top: BorderSide(color: k.border)),
      ),
      padding: EdgeInsets.symmetric(vertical: 10.sp),
      child: Row(
        children: [
          Container(
            width: 40.sp,
            height: 40.sp,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(13.sp),
            ),
            alignment: Alignment.center,
            child: ThreeD(icon, size: 26.sp),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: title),
                      if (count != null)
                        TextSpan(
                          text: '  × $count',
                          style: TextStyle(color: k.muted),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text),
                ),
                SizedBox(height: 1.sp),
                Text(
                  sub,
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
          SizedBox(width: 10.sp),
          Text(
            amount,
            style: AppText.number(16.sp).copyWith(color: amountColor),
          ),
        ],
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
      icon: PhosphorIconsBold.scales,
      tint: AppColors.violetSoft,
      title: 'Weight',
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
      icon: PhosphorIconsBold.smiley,
      tint: AppColors.limeSoft,
      title: 'How I felt',
      trailing: c.isToday && !c.hasCheckIn
          ? _link(context, 'Check in', c.openCheckIn)
          : null,
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
