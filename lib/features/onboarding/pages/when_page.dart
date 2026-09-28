import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Question 5: the day of the last dose (already taking) or first dose
/// (starting / restarting), plus the usual time. A live "Next dose" card
/// shows what the answers mean.
class WhenPage extends GetView<OnboardingController> {
  const WhenPage({super.key});

  static const int _stripDays = 14;

  (String, String) get _copy {
    if (!controller.needsDoseDate) {
      return (
        'What time do you usually take it?',
        "We'll remind you at the same time each day.",
      );
    }
    return switch (controller.stage.value) {
      'starting' => (
        'When is your first dose?',
        "We'll have everything ready for it.",
      ),
      'restart' => (
        'When will you restart?',
        'Pick the day of your first dose back.',
      ),
      _ => ('When was your last dose?', "We'll work out your next one."),
    };
  }

  Future<void> _pickEarlierOrLater(BuildContext context) async {
    final today = Dates.dateOnly(DateTime.now());
    final past = controller.asksLastDose;
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.doseDate.value ?? today,
      firstDate: past ? today.subtract(const Duration(days: 180)) : today,
      lastDate: past ? today : today.add(const Duration(days: 365)),
      helpText: past ? 'Last dose' : 'First dose',
    );
    if (picked != null) controller.pickDoseDate(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final m = controller.shotMinutes.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      helpText: 'Usual time',
    );
    if (picked != null)
      controller.pickDoseTime(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final (title, subtitle) = _copy;
    final needsDate = controller.needsDoseDate;

    return StepScaffold(
      title: title,
      subtitle: subtitle,
      cta: Obx(
        () => PillButton(
          label: controller.editMode ? 'Save changes' : 'Continue',
          onPressed: controller.scheduleReady
              ? controller.confirmSchedule
              : null,
        ),
      ),
      children: [
        if (needsDate) ...[
          const SectionLabel('Day').enter(motion, delay: 100, dy: 0.1),
          SizedBox(height: 10.sp),
          SizedBox(
            height: 82.sp,
            child: Obx(() {
              final today = Dates.dateOnly(DateTime.now());
              final past = controller.asksLastDose;
              final selected = controller.doseDate.value;
              final days = [
                for (var i = 0; i < _stripDays; i++)
                  past
                      ? today.subtract(Duration(days: i))
                      : today.add(Duration(days: i)),
              ];
              final outside = selected != null && !days.contains(selected);
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: days.length + 1,
                separatorBuilder: (context, index) => SizedBox(width: 8.sp),
                itemBuilder: (context, i) {
                  if (i == days.length) {
                    return _MoreDaysCard(
                      label: past ? 'Earlier…' : 'Later…',
                      picked: outside ? selected : null,
                      onTap: () => _pickEarlierOrLater(context),
                    );
                  }
                  final d = days[i];
                  return _DayCard(
                    day: d,
                    top: i == 0
                        ? 'Today'
                        : i == 1
                        ? (past ? 'Yest.' : 'Tmrw')
                        : Dates.weekdayShort(d.weekday),
                    selected: selected == d,
                    onTap: () => controller.pickDoseDate(d),
                  ).enter(motion, delay: 140 + i.clamp(0, 5) * 40, dy: 0.1);
                },
              );
            }),
          ),
          SizedBox(height: 22.sp),
        ],
        const SectionLabel('Usual time').enter(motion, delay: 200, dy: 0.1),
        SizedBox(height: 10.sp),
        Obx(() {
          final m = controller.shotMinutes.value;
          final custom = !OnboardingController.timePresets.contains(m);
          Widget tile(IconData icon, Color tint, String label, int minutes) =>
              _TimeTile(
                icon: icon,
                tint: tint,
                label: label,
                time: Dates.timeOfDay(minutes),
                selected: m == minutes,
                onTap: () => controller.pickDoseTime(minutes),
              );
          return _TwoByTwo(
            children: [
              tile(
                PhosphorIconsBold.sun,
                _tint(context, AppColors.tangerineSoft, AppColors.tangerine),
                'Morning',
                OnboardingController.morningMinutes,
              ),
              tile(
                PhosphorIconsBold.cloudSun,
                _tint(context, AppColors.aquaSoft, AppColors.aqua),
                'Afternoon',
                OnboardingController.afternoonMinutes,
              ),
              tile(
                PhosphorIconsBold.moon,
                context.k.cardAlt,
                'Evening',
                OnboardingController.eveningMinutes,
              ),
              _TimeTile(
                icon: PhosphorIconsBold.clock,
                tint: _tint(context, const Color(0xFFF1F7D6), AppColors.lime),
                label: 'Pick a time',
                time: custom ? Dates.timeOfDay(m) : 'Any time',
                selected: custom,
                onTap: () => _pickTime(context),
              ),
            ],
          );
        }).enter(motion, delay: 240),
        SizedBox(height: 18.sp),
        const _NextDoseCard(),
      ],
    );
  }

  static Color _tint(BuildContext context, Color light, Color accent) =>
      context.k.selectedBorder == AppColors.lime
      ? accent.withValues(alpha: 0.16)
      : light;
}

/// Two equal columns, rows as tall as their content.
class _TwoByTwo extends StatelessWidget {
  const _TwoByTwo({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: 8.sp));
      rows.add(
        Row(
          children: [
            Expanded(child: children[i]),
            SizedBox(width: 8.sp),
            Expanded(
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.top,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final String top;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final onLime = k.selectedBorder == AppColors.lime;
    final fg = selected ? (onLime ? AppColors.ink : AppColors.white) : k.text;
    final sub = selected
        ? (onLime ? AppColors.ink.withValues(alpha: 0.7) : AppColors.lime)
        : k.muted;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$top, ${Dates.long(day)}',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 64.sp,
          decoration: BoxDecoration(
            color: selected ? k.selectedBorder : k.card,
            borderRadius: BorderRadius.circular(20.sp),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 2.sp,
                offset: Offset(0, 1.sp),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                top,
                style: AppText.small.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: sub,
                ),
              ),
              SizedBox(height: 2.sp),
              Text(
                '${day.day}',
                style: AppText.h1.copyWith(
                  fontSize: 24.sp,
                  height: 1,
                  color: fg,
                ),
              ),
              SizedBox(height: 2.sp),
              Text(
                Dates.monthShort(day.month),
                style: AppText.small.copyWith(fontSize: 11.sp, color: sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed "Earlier…" / "Later…" card that opens the calendar. Shows the
/// picked date when it's outside the strip.
class _MoreDaysCard extends StatelessWidget {
  const _MoreDaysCard({
    required this.label,
    required this.picked,
    required this.onTap,
  });

  final String label;
  final DateTime? picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final has = picked != null;
    return Semantics(
      button: true,
      selected: has,
      label: has
          ? 'Picked ${Dates.long(picked!)}. Change date'
          : 'Pick another date',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: has ? 84.sp : 64.sp,
          decoration: BoxDecoration(
            color: has ? k.selectedBorder : Colors.transparent,
            borderRadius: BorderRadius.circular(20.sp),
            border: has ? null : Border.all(color: k.border, width: 2),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 6.sp),
          child: has
              ? Text(
                  Dates.short(picked!),
                  textAlign: TextAlign.center,
                  style: AppText.title.copyWith(
                    fontSize: 14.sp,
                    color: k.selectedBorder == AppColors.lime
                        ? AppColors.ink
                        : AppColors.white,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsBold.calendarDots,
                      size: 18.sp,
                      color: k.muted,
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      label,
                      style: AppText.small.copyWith(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: k.muted,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.tint,
    required this.label,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$label, $time',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: BoxConstraints(minHeight: 58.sp),
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(18.sp),
            border: Border.all(
              color: selected ? k.selectedBorder : k.card,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34.sp,
                height: 34.sp,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(11.sp),
                ),
                alignment: Alignment.center,
                child: PhosphorIcon(icon, size: 18.sp, color: k.text),
              ),
              SizedBox(width: 10.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: k.text,
                      ),
                    ),
                    Text(
                      time,
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
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
    );
  }
}

/// Dark card that updates live: "NEXT DOSE · Thu, 1 Oct · 8:00 AM".
class _NextDoseCard extends GetView<OnboardingController> {
  const _NextDoseCard();

  String _rhythm(int every, DateTime next) {
    final day = Dates.weekdayName(next.weekday);
    return switch (every) {
      1 => 'Daily, so every day at ${Dates.time(next)}.',
      7 => 'Weekly, so every $day from now on.',
      14 => 'Every 2 weeks, so every other $day.',
      _ => 'Every $every days from then on.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Obx(() {
      // nextDosePreview reads the date, time and frequency, so Obx rebuilds on each.
      final next = controller.nextDosePreview;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SizeTransition(
            sizeFactor: anim,
            alignment: Alignment.topLeft,
            child: child,
          ),
        ),
        child: next == null
            ? const SizedBox(width: double.infinity, key: ValueKey('empty'))
            : Column(
                key: const ValueKey('card'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    label:
                        'Next dose ${Dates.shortWithDay(next)} at ${Dates.time(next)}',
                    excludeSemantics: true,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16.sp, 16.sp, 18.sp, 16.sp),
                      decoration: BoxDecoration(
                        color: dark ? k.cardAlt : AppColors.ink,
                        borderRadius: BorderRadius.circular(22.sp),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44.sp,
                            height: 44.sp,
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(14.sp),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  Dates.monthShort(next.month).toUpperCase(),
                                  style: AppText.small.copyWith(
                                    fontSize: 9.sp,
                                    height: 1,
                                    letterSpacing: 0.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  '${next.day}',
                                  style: AppText.h1.copyWith(
                                    fontSize: 19.sp,
                                    height: 1.05,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 14.sp),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEXT DOSE',
                                  style: AppText.caps.copyWith(
                                    fontSize: 12.sp,
                                    letterSpacing: 1,
                                    color: AppColors.heroMuted,
                                  ),
                                ),
                                SizedBox(height: 2.sp),
                                Text(
                                  '${Dates.relativeDay(next, DateTime.now())} · ${Dates.time(next)}',
                                  style: AppText.title.copyWith(
                                    fontSize: 17.sp,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(4.sp, 12.sp, 4.sp, 0),
                    child: Text(
                      '${_rhythm(controller.everyDays, next)} You can move it any time.',
                      style: AppText.small.copyWith(
                        fontSize: 12.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: k.faint,
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }
}
