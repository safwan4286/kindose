import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
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
                    ).enter(motion),
                    SizedBox(height: 6.sp),
                    Text(
                      'Pick what Kindose reminds you about. Everything else stays quiet.',
                      style: AppText.bodyText.copyWith(
                        fontSize: 14.sp,
                        height: 1.4,
                        color: k.muted,
                      ),
                    ).enter(motion, delay: 40),
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
                      ).enter(motion, delay: 80),
                    ],
                    const _Label('Daily habits'),
                    KGroup(
                      padded: true,
                      children: [
                        _ToggleRow(
                          label: 'Water',
                          sub: 'Every ${p.waterEvery.value} hours, ${c.waterWindow}',
                          value: c.unlocked && p.waterOn.value,
                          plus: !c.unlocked,
                          onChanged: c.setWater,
                        ),
                        if (c.unlocked && p.waterOn.value) ...[
                          _ChoiceRow<int>(
                            label: 'How often',
                            options: const [2, 3],
                            selected: p.waterEvery.value,
                            labelOf: (h) => 'Every ${h}h',
                            onChanged: c.setWaterEvery,
                          ),
                          _ValueRow(
                            label: 'First reminder',
                            value: Dates.timeOfDay(p.waterStart.value),
                            onTap: () => c.pickWaterStart(context),
                          ),
                          _ValueRow(
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
                    ).enter(motion, delay: 110),
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
                            label: 'Remind me',
                            options: const [1, 3, 7],
                            selected: p.visitDays.value,
                            labelOf: (d) => d == 7 ? '1 week' : '$d ${d == 1 ? 'day' : 'days'}',
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
                    ).enter(motion, delay: 140),
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
                      ).enter(motion, delay: 170),
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
                            label: 'From',
                            value: Dates.timeOfDay(p.quietStart.value),
                            onTap: () => c.pickQuietStart(context),
                          ),
                          _ValueRow(
                            label: 'Until',
                            value: Dates.timeOfDay(p.quietEnd.value),
                            onTap: () => c.pickQuietEnd(context),
                          ),
                        ],
                      ],
                    ).enter(motion, delay: 200),
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
    required this.label,
    required this.value,
    required this.onTap,
  });

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
          constraints: BoxConstraints(minHeight: 48.sp),
          padding: EdgeInsets.only(left: 12.sp, top: 10.sp, bottom: 10.sp),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.small.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: k.muted,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                decoration: BoxDecoration(
                  color: k.cardAlt,
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                child: Text(
                  value,
                  style: AppText.title.copyWith(fontSize: 14.sp, color: k.text),
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

/// Label on the left, small segmented choice on the right.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 12.sp, top: 8.sp, bottom: 8.sp),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.small.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: context.k.muted,
              ),
            ),
          ),
          SizedBox(
            width: (options.length * 70).sp,
            child: KSegmented<T>(
              options: options,
              selected: selected,
              onChanged: onChanged,
              labelOf: labelOf,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
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
