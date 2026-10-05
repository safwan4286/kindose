import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../resources/images.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/drop_mark.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/k_widgets.dart';
import '../onboarding_controller.dart';

/// Wrap-up 1: explain reminders with real previews from the user's own
/// answers, then ask for permission. "Not now" is always fine.
class RemindersPage extends GetView<OnboardingController> {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final time = Dates.timeOfDay(controller.shotMinutes.value);
    final tablet = controller.form.value == 'tablet';
    final daily = controller.everyDays == 1;
    final site = Catalog.siteName(Catalog.nextSite(const []));

    // The same words the real reminders use (ReminderService). They never
    // name the medicine, so nothing private shows on a lock screen.
    final previews = [
      if (daily)
        _Preview('Time for today’s dose', 'Tap to mark it as taken.', time)
      else
        _Preview(
          "It's dose day",
          tablet
              ? 'Tap to log it when you’re done.'
              : 'Tap to log it when you’re done. $site is next.',
          time,
        ),
      if (!daily)
        const _Preview(
          'Still to log: your dose',
          'Took it already? Tap to log it.',
          '8:00 PM',
        ),
      const _Preview(
        'Doctor visit on Monday',
        'Your one-page report is ready. Tap to check it.',
        '9:00 AM',
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 16.sp),
            children: [
              const Center(child: _RingingBell()).enter(motion, dy: 0.1),
              SizedBox(height: 15.sp),
              Semantics(
                header: true,
                child: Text(
                  'Never miss a dose',
                  textAlign: TextAlign.center,
                  style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text),
                ),
              ).enter(motion, delay: 80, dy: 0.12),
              SizedBox(height: 10.sp),
              Text(
                'A nudge on dose day, a follow-up if it isn’t logged, and a heads-up before doctor visits. Your medicine’s name never shows.',
                textAlign: TextAlign.center,
                style: AppText.bodyText.copyWith(
                  fontSize: 14.5.sp,
                  height: 1.45,
                  color: k.muted,
                ),
              ).enter(motion, delay: 140, dy: 0.12),
              SizedBox(height: 20.sp),
              ExcludeSemantics(
                child: Column(
                  children: [
                    for (var i = 0; i < previews.length; i++) ...[
                      if (i > 0) SizedBox(height: 10.sp),
                      _NotificationCard(
                        previews[i],
                      ).enter(motion, delay: 260 + i * 150, dy: 0.25),
                    ],
                  ],
                ),
              ),
              // SizedBox(height: 22.sp),
              // _ExtraNudges(controller: controller).enter(
              //   motion,
              //   delay: 260 + previews.length * 150,
              //   dy: 0.2,
              // ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 8.sp),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillButton(
                  label: 'Turn on reminders',
                  busy: controller.askingReminders.value,
                  onPressed: controller.enableReminders,
                ),
                SizedBox(height: 4.sp),
                LinkButton(
                  label: 'Not now',
                  onTap: controller.askingReminders.value
                      ? null
                      : controller.skipReminders,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Optional water and protein nudges, off by default. They need the same
/// permission, so they are saved only with "Turn on reminders".
class _ExtraNudges extends StatelessWidget {
  const _ExtraNudges({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.sp, bottom: 8.sp),
            child: SectionLabel('Also remind me', color: k.faint),
          ),
          KGroup(
            padded: true,
            children: [
              SwitchRow(
                label: 'Drink water',
                sub: 'Every 2 hours, 9 AM – 8 PM',
                leading: ThreeD(Img3d.droplet, size: 30.sp),
                value: controller.wantWater.value,
                onChanged: (_) => controller.toggleWater(),
                padding: EdgeInsets.symmetric(vertical: 12.sp),
              ),
              SwitchRow(
                label: 'Eat protein',
                sub: 'At lunch and mid-afternoon',
                leading: ThreeD(Img3d.biceps, size: 30.sp),
                value: controller.wantProtein.value,
                onChanged: (_) => controller.toggleProtein(),
                padding: EdgeInsets.symmetric(vertical: 12.sp),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(4.sp, 8.sp, 4.sp, 0),
            child: Text(
              'Open in your free week, then part of Kindose Plus. Change any reminder later in Me › Notifications.',
              style: AppText.small.copyWith(
                fontSize: 12.sp,
                height: 1.4,
                color: k.faint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview {
  const _Preview(this.title, this.body, this.time);

  final String title;
  final String body;
  final String time;
}

/// Lock-screen style card with the Kindose drop as the app icon.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard(this.p);

  final _Preview p;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: EdgeInsets.fromLTRB(12.sp, 12.sp, 14.sp, 12.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(20.sp),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 20.sp,
            offset: Offset(0, 6.sp),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.sp,
            height: 22.sp,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(6.sp),
            ),
            alignment: Alignment.center,
            child: DropMark(size: 22.sp),
          ),
          SizedBox(width: 10.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'KINDOSE',
                        style: AppText.small.copyWith(
                          fontSize: 12.sp,
                          color: k.faint,
                        ),
                      ),
                    ),
                    Text(
                      p.time,
                      style: AppText.small.copyWith(
                        fontSize: 12.sp,
                        color: k.faint,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.sp),
                Text(
                  p.title,
                  style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
                ),
                SizedBox(height: 2.sp),
                Text(
                  p.body,
                  style: AppText.bodyText.copyWith(
                    fontSize: 13.5.sp,
                    height: 1.35,
                    color: k.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D bell that gives a short ring every few seconds. Still when the user
/// has reduce motion on.
class _RingingBell extends StatefulWidget {
  const _RingingBell();

  @override
  State<_RingingBell> createState() => _RingingBellState();
}

class _RingingBellState extends State<_RingingBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _c.repeat();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Ring during the first 30% of each cycle, fading out; rest otherwise.
  double _angle(double t) {
    if (t > 0.3) return 0;
    final p = t / 0.3;
    return 0.22 * math.sin(p * 4 * math.pi) * (1 - p);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Container(
      width: 100.sp,
      height: 100.sp,
      decoration: BoxDecoration(
        color: dark
            ? AppColors.lime.withValues(alpha: 0.14)
            : const Color(0xFFF1F7D6),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.rotate(
          angle: _angle(_c.value),
          alignment: const Alignment(0, -0.8),
          child: child,
        ),
        child: ThreeD(Img3d.bell, size: 60.sp),
      ),
    );
  }
}
