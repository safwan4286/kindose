import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/choice_sheet.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'notifications_controller.dart';

/// Me → Notifications. Every reminder Kindose sends, each with its own
/// switch, plus quiet hours.
class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

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
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 4.sp),
              child: Row(children: [BackCircle(onTap: popRoute)]),
            ),
            Expanded(
              child: Obx(() {
                controller.watch();
                final c = controller;
                final p = c.prefs;
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20.sp, 6.sp, 20.sp, 32.sp),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Notifications',
                        style: AppText.h1.copyWith(fontSize: 28.sp, color: k.text),
                      ),
                    ),
                    SizedBox(height: 6.sp),
                    Text(
                      'Pick what Kindose reminds you about. Everything else stays quiet.',
                      style: AppText.bodyText.copyWith(
                        fontSize: 14.sp,
                        height: 1.4,
                        color: k.muted,
                      ),
                    ),
                    _Reveal(
                      show: c.blocked,
                      child: Padding(
                        padding: EdgeInsets.only(top: 16.sp),
                        child: _BlockedCard(onOpen: c.openSystemSettings),
                      ),
                    ),
                    if (c.hasPlan) ...[
                      const _Label('Treatment'),
                      KGroup(
                        padded: true,
                        children: [
                          _ToggleRow(
                            label: 'Dose reminders',
                            sub: c.doseSub,
                            value: c.doseOn,
                            onChanged: c.setDose,
                          ),
                          if (c.doseOn)
                            _ValueRow(
                              icon: PhosphorIconsRegular.clock,
                              label: 'Reminder time',
                              value: c.doseTime,
                              onTap: () => c.pickDoseTime(context),
                            ),
                          if (c.doseOn && !c.isDaily) ...[
                            _ToggleRow(
                              label: 'Follow-up',
                              sub: 'One more nudge that evening if not logged',
                              value: p.followUpOn.value,
                              onChanged: c.setFollowUp,
                            ),
                            _ToggleRow(
                              label: 'Missed dose',
                              sub: 'A gentle check the next morning',
                              value: p.missedOn.value,
                              onChanged: c.setMissed,
                            ),
                          ],
                        ],
                      ).enter(motion, delay: 140, dy: 0.04),
                    ],
                    const _Label('Daily habits'),
                    KGroup(
                      padded: true,
                      children: [
                        _ToggleRow(
                          label: 'Water',
                          sub:
                              '${p.waterEvery.value == 1 ? 'Every hour' : 'Every ${p.waterEvery.value} hours'}, ${c.waterWindow}',
                          value: c.unlocked && p.waterOn.value,
                          plus: !c.unlocked,
                          onChanged: c.setWater,
                        ),
                        if (c.unlocked && p.waterOn.value) ...[
                          _ChoiceRow<int>(
                            icon: PhosphorIconsRegular.repeat,
                            label: 'How often',
                            title: 'Water reminders',
                            options: const [1, 2, 3, 4],
                            selected: p.waterEvery.value,
                            labelOf: (h) =>
                                h == 1 ? 'Every hour' : 'Every $h hours',
                            onChanged: c.setWaterEvery,
                          ),
                          _ValueRow(
                            icon: PhosphorIconsRegular.sun,
                            label: 'First reminder',
                            value: Dates.timeOfDay(p.waterStart.value),
                            onTap: () => c.pickWaterStart(context),
                          ),
                          _ValueRow(
                            icon: PhosphorIconsRegular.moon,
                            label: 'Last reminder',
                            value: Dates.timeOfDay(p.waterEnd.value),
                            onTap: () => c.pickWaterEnd(context),
                          ),
                        ],
                        _ToggleRow(
                          label: 'Protein',
                          sub: 'At lunch and mid-afternoon, until your goal is met',
                          value: c.unlocked && p.proteinOn.value,
                          plus: !c.unlocked,
                          onChanged: c.setProtein,
                        ),
                      ],
                    ).enter(motion, delay: 200, dy: 0.04),
                    const _Label('Visits & supplies'),
                    KGroup(
                      padded: true,
                      children: [
                        _ToggleRow(
                          label: 'Doctor visit',
                          sub: c.visitSub,
                          value: c.visitOn,
                          onChanged: c.setVisit,
                        ),
                        if (c.visitOn)
                          _ChoiceRow<int>(
                            icon: PhosphorIconsRegular.calendarBlank,
                            label: 'Remind me',
                            title: 'Doctor visit reminder',
                            options: const [1, 2, 3, 7],
                            selected: p.visitDays.value,
                            labelOf: (d) => d == 7
                                ? '1 week before'
                                : '$d ${d == 1 ? 'day' : 'days'} before',
                            onChanged: c.setVisitDays,
                          ),
                        _ToggleRow(
                          label: 'Refill',
                          sub: 'When your supply at home runs low',
                          value: c.refillOn,
                          plus: !c.unlocked,
                          onChanged: c.setRefill,
                        ),
                      ],
                    ).enter(motion, delay: 260, dy: 0.04),
                    if (!c.isPlus) ...[
                      const _Label('Kindose'),
                      KGroup(
                        padded: true,
                        children: [
                          _ToggleRow(
                            label: 'Free week & offers',
                            sub: 'A heads-up the day before your free week ends',
                            value: p.offersOn.value,
                            onChanged: c.setOffers,
                          ),
                        ],
                      ).enter(motion, delay: 320, dy: 0.04),
                    ],
                    const _Label('Quiet hours'),
                    KGroup(
                      padded: true,
                      children: [
                        _ToggleRow(
                          label: 'Quiet hours',
                          sub: p.quietOn.value
                              ? c.quietWindow
                              : 'Reminders can come at any time',
                          value: p.quietOn.value,
                          onChanged: c.setQuiet,
                        ),
                        if (p.quietOn.value) ...[
                          _ValueRow(
                            icon: PhosphorIconsRegular.moonStars,
                            label: 'From',
                            value: Dates.timeOfDay(p.quietStart.value),
                            onTap: () => c.pickQuietStart(context),
                          ),
                          _ValueRow(
                            icon: PhosphorIconsRegular.sunHorizon,
                            label: 'Until',
                            value: Dates.timeOfDay(p.quietEnd.value),
                            onTap: () => c.pickQuietEnd(context),
                          ),
                        ],
                      ],
                    ).enter(motion, delay: 380, dy: 0.04),
                    Padding(
                      padding: EdgeInsets.fromLTRB(4.sp, 10.sp, 4.sp, 0),
                      child: KBottomPadding(
                        child: Text(
                          'Dose reminders always come at the time you chose. '
                          'Other reminders wait until quiet hours end.',
                          style: AppText.small.copyWith(
                            fontSize: 12.5.sp,
                            height: 1.45,
                            color: k.faint,
                          ),
                        ),
                      ),
                    ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 22.sp, bottom: 10.sp, left: 4.sp),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: AppText.caps.copyWith(
            fontSize: 12.sp,
            letterSpacing: 1.1,
            color: context.k.faint,
          ),
        ),
      ),
    );
  }
}

/// Grows in and out smoothly.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: show ? child : const SizedBox(width: double.infinity),
    );
  }
}

/// Switch row with an optional Plus tag. Free users tapping a Plus row go
/// to the paywall (the controller decides).
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.plus = false,
  });

  final String label;
  final String sub;
  final bool value;
  final bool plus;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      toggled: value,
      button: true,
      label: plus ? '$label, Plus feature. $sub' : '$label. $sub',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.sp),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.sp),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8.sp,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          label,
                          style: AppText.title.copyWith(
                            fontSize: 15.sp,
                            color: k.text,
                          ),
                        ),
                        if (plus) const PlusTag(),
                      ],
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      sub,
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        height: 1.35,
                        color: k.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.sp),
              KSwitch(value: value),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Reminder time   9:00 AM ›" — opens a picker.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  /// Marks it as a setting of the row above, lined up with that row.
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PressScale(
      semanticLabel: '$label, $value',
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        constraints: BoxConstraints(minHeight: 52.sp),
        padding: EdgeInsets.symmetric(vertical: 12.sp),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 20.sp, color: k.muted),
            SizedBox(width: 12.sp),
            Expanded(
              child: Text(
                label,
                style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
              ),
            ),
            SizedBox(width: 8.sp),
            Text(
              value,
              style: AppText.bodyStrong.copyWith(
                fontSize: 14.5.sp,
                color: k.muted,
              ),
            ),
            SizedBox(width: 6.sp),
            PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: 14.sp,
              color: k.faint,
            ),
          ],
        ),
      ),
    );
  }
}

/// "How often   Every 2 hours ›": opens a sheet with every option, so
/// the list can grow without crowding the row.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final IconData icon;
  final String label;

  /// Heading of the sheet.
  final String title;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  Future<void> _open() async {
    final picked = await showChoiceSheet<T>(
      title: title,
      options: options,
      selected: selected,
      labelOf: labelOf,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) =>
      _ValueRow(
        icon: icon,
        label: label,
        value: labelOf(selected),
        onTap: _open,
      );
}

/// Shown when the phone blocks Kindose notifications: no switch here can
/// work until they are allowed again.
class _BlockedCard extends StatelessWidget {
  const _BlockedCard({required this.onOpen});

  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final bg = dark ? k.cardAlt : AppColors.amberSoft;
    final fg = dark ? k.text : AppColors.amberText;
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIconsBold.bellSlash, size: 20.sp, color: fg),
              SizedBox(width: 8.sp),
              Expanded(
                child: Text(
                  'Notifications are off',
                  style: AppText.title.copyWith(fontSize: 15.sp, color: fg),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.sp),
          Text(
            'Your phone is blocking Kindose, so no reminders can reach you. '
            'Turn them on in Settings.',
            style: AppText.small.copyWith(
              fontSize: 13.sp,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          SizedBox(height: 12.sp),
          PillButton(label: 'Open Settings', ink: true, onPressed: onOpen),
        ],
      ),
    );
  }
}
