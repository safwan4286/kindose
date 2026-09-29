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
                        style: AppText.h1.copyWith(fontSize: 28.sp, height: 1.1, color: k.text),
                      ),
                    ).enter(motion),
                    SizedBox(height: 16.sp),
                    _DoseSection(controller: controller).enter(motion, delay: 40),
                    SizedBox(height: 12.sp),
                    _IntakeSection(controller: controller, kind: 'protein').enter(motion, delay: 80),
                    SizedBox(height: 12.sp),
                    _IntakeSection(controller: controller, kind: 'water').enter(motion, delay: 120),
                    SizedBox(height: 12.sp),
                    _WeightSection(controller: controller).enter(motion, delay: 160),
                    SizedBox(height: 12.sp),
                    _FeelSection(controller: controller).enter(motion, delay: 200),
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
  const _Section({required this.icon, required this.tint, required this.title, required this.child, this.trailing});

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
      decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(22.sp)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.sp,
                height: 34.sp,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11.sp)),
                child: Icon(icon, size: 17.sp, color: AppColors.ink),
              ),
              SizedBox(width: 10.sp),
              Expanded(
                child: Text(title, style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
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

Widget _link(BuildContext context, String label, VoidCallback onTap) => Semantics(
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
            style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: context.k.text),
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
                Text(controller.doseTitle, style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: k.text)),
                SizedBox(height: 2.sp),
                _muted(context, controller.doseLine),
              ],
            )
          : _muted(context, 'No dose logged this day.'),
    );
  }
}

// ---------------------------------------------------------- protein, water

class _IntakeSection extends StatelessWidget {
  const _IntakeSection({required this.controller, required this.kind});

  final DayController controller;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final protein = kind == 'protein';
    final list = controller.entries(kind);
    final total = protein ? controller.log.proteinG : controller.log.waterMl;
    final goal = protein ? controller.proteinGoal : controller.waterGoal;
    final totalText = protein
        ? '$total g of $goal g'
        : '${controller.litres(total)} of ${controller.litres(goal)} L';
    return _Section(
      icon: protein ? PhosphorIconsBold.egg : PhosphorIconsBold.drop,
      tint: protein ? AppColors.tangerineSoft : AppColors.aquaSoft,
      title: protein ? 'Protein' : 'Water',
      trailing: _link(context, list.isEmpty ? 'Add' : 'Edit', () => controller.openIntake(kind)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  totalText,
                  style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: k.text),
                ),
              ),
              if (total >= goal && goal > 0)
                KTag('Goal hit', bg: protein ? AppColors.tangerineSoft : AppColors.aquaSoft, fg: protein ? AppColors.tangerineText : AppColors.aquaText),
            ],
          ),
          if (list.isEmpty) ...[
            SizedBox(height: 2.sp),
            _muted(context, 'Nothing logged.'),
          ] else ...[
            SizedBox(height: 6.sp),
            for (final e in list) _EntryRow(controller: controller, entry: e),
          ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.controller, required this.entry});

  final DayController controller;
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final amount = entry.isProtein ? '+${entry.amount} g' : '+${entry.amount} ml';
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.removeEntry(entry),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 12.sp),
        color: AppColors.dangerSoft,
        child: Icon(PhosphorIconsBold.trash, size: 18.sp, color: AppColors.danger),
      ),
      child: Semantics(
        label: '${controller.entryTitle(entry)}, $amount. Swipe left to remove.',
        excludeSemantics: true,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 7.sp),
          child: Row(
            children: [
              SizedBox(
                width: 64.sp,
                child: Text(
                  TimeOfDay.fromDateTime(entry.at).format(context),
                  style: AppText.small.copyWith(fontSize: 12.5.sp, color: k.faint),
                ),
              ),
              Expanded(
                child: Text(
                  controller.entryTitle(entry),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: k.text),
                ),
              ),
              Text(amount, style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: k.text)),
            ],
          ),
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
      icon: PhosphorIconsBold.scales,
      tint: AppColors.violetSoft,
      title: 'Weight',
      child: w == null
          ? _muted(context, 'No weigh-in this day.')
          : Text(
              controller.weightLabel(w.kg),
              style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: k.text),
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
      trailing: c.isToday && !c.hasCheckIn ? _link(context, 'Check in', c.openCheckIn) : null,
      child: !c.hasCheckIn
          ? _muted(context, c.isToday ? 'No check-in yet today.' : 'No check-in this day.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.moodLabel != null)
                  Row(
                    children: [
                      if (c.moodIcon != null) ...[ThreeD(c.moodIcon!, size: 26.sp), SizedBox(width: 8.sp)],
                      Text(
                        c.moodLabel!,
                        style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: k.text),
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
                          padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 5.sp),
                          decoration: BoxDecoration(color: k.cardAlt, borderRadius: BorderRadius.circular(12.sp)),
                          child: Text(t, style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: k.text)),
                        ),
                    ],
                  ),
                ],
                if (c.log.note?.isNotEmpty ?? false) ...[
                  SizedBox(height: 8.sp),
                  Text(
                    '“${c.log.note}”',
                    style: AppText.bodyText.copyWith(fontSize: 13.5.sp, fontStyle: FontStyle.italic, color: k.muted),
                  ),
                ],
              ],
            ),
    );
  }
}
