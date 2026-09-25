import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../resources/images.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_widgets.dart';
import '../onboarding_controller.dart';

/// Last onboarding screen: the plan reveal on a dark background.
class PlanPage extends GetView<OnboardingController> {
  const PlanPage({super.key});

  /// First planned dose day on or after today.
  DateTime _firstDoseDay(DateTime now, int everyDays, int weekday) {
    final today = Dates.dateOnly(now);
    if (everyDays == 1 || (everyDays != 7 && everyDays != 14)) return today;
    return today.add(Duration(days: (weekday - today.weekday + 7) % 7));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.draft;
      final med = Catalog.medicine(p.medicineId);
      final now = DateTime.now();
      final first = _firstDoseDay(now, p.everyDays, p.shotWeekday);
      final inDays = Dates.daysBetween(now, first);
      final when = inDays == 0 ? 'today' : inDays == 1 ? 'tomorrow' : 'in $inDays days';
      final site = Catalog.siteName(Catalog.nextSite(null));
      final isTablet = p.form == 'tablet';

      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "YOU'RE ALL SET",
                            style: AppText.caps.copyWith(fontSize: 13, letterSpacing: 1.2, color: AppColors.lime),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            header: true,
                            child: Text(
                              "Here's your plan",
                              style: AppText.h1.copyWith(fontSize: 36, color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _PopIn(child: ThreeD(Img3d.partyPopper, size: 84)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('NEXT DOSE', style: AppText.caps.copyWith(fontSize: 13, color: AppColors.hero)),
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.hero.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${med.name} · ${Catalog.mg(p.strengthMg)} mg',
                                style: AppText.tiny.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.hero),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 10,
                        children: [
                          Text(
                            inDays == 0 ? 'Today' : Dates.weekdayName(first.weekday),
                            style: AppText.number(46).copyWith(color: AppColors.hero),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$when · ${Dates.timeOfDay(p.shotMinutes)}',
                              style: AppText.title.copyWith(fontSize: 16, color: AppColors.hero),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _WeekStrip(start: Dates.dateOnly(now), doseDay: first, everyDays: p.everyDays),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _PlanStat(icon: Img3d.egg, value: '${p.proteinGoalG} g', label: 'protein a day')),
                    const SizedBox(width: 10),
                    const Expanded(child: _PlanStat(icon: Img3d.droplet, value: '2.5 L', label: 'water a day')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PlanStat(
                        icon: Img3d.smile,
                        value: isTablet ? 'Daily' : Dates.weekdayShort(first.add(const Duration(days: 1)).weekday),
                        label: 'how-you-feel check',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _NotificationPreview(
                  time: Dates.timeOfDay(p.shotMinutes),
                  day: Dates.weekdayShort(first.weekday),
                  text: isTablet ? "Time for today's tablet." : "It's shot day. $site is next.",
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              children: [
                PillButton(
                  label: 'Turn on reminders',
                  lime: true,
                  busy: controller.saving.value,
                  icon: PhosphorIconsBold.bellRinging,
                  onPressed: () => controller.finish(remindersOn: true),
                ),
                TextButton(
                  onPressed: controller.saving.value ? null : () => controller.finish(),
                  child: Text(
                    'Maybe later',
                    style: AppText.title.copyWith(color: AppColors.heroMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.start, required this.doseDay, required this.everyDays});

  final DateTime start;
  final DateTime doseDay;
  final int everyDays;

  bool _isDose(DateTime d) {
    if (d.isBefore(doseDay)) return false;
    final diff = Dates.daysBetween(doseDay, d);
    return diff % everyDays == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(builder: (context) {
              final d = start.add(Duration(days: i));
              final dose = _isDose(d);
              return Semantics(
                label: '${Dates.weekdayName(d.weekday)} ${d.day}${dose ? ', dose day' : ''}',
                excludeSemantics: true,
                child: Column(
                  children: [
                    Text(
                      Dates.weekdayShort(d.weekday).substring(0, 2),
                      style: AppText.tiny.copyWith(fontWeight: FontWeight.w800, color: AppColors.hero),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: dose ? AppColors.hero : Colors.transparent,
                        shape: BoxShape.circle,
                        border: i == 0 && !dose ? Border.all(color: AppColors.hero, width: 2) : null,
                      ),
                      alignment: Alignment.center,
                      child: dose
                          ? const PhosphorIcon(PhosphorIconsFill.syringe, size: 16, color: AppColors.lime)
                          : Text(
                              '${d.day}',
                              style: AppText.small.copyWith(fontWeight: FontWeight.w800, color: AppColors.hero),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({required this.icon, required this.value, required this.label});

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF22213F), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThreeD(icon, size: 34),
          const SizedBox(height: 6),
          Text(value, style: AppText.h2.copyWith(fontSize: 21, color: AppColors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: AppText.tiny.copyWith(fontSize: 12, color: AppColors.heroMuted), maxLines: 2),
        ],
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.time, required this.day, required this.text});

  final String time;
  final String day;
  final String text;

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF5E5C7A);
    return Semantics(
      label: 'Reminder preview: $text',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 20))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(7)),
                  child: const Center(child: PhosphorIcon(PhosphorIconsBold.drop, size: 13, color: AppColors.hero)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Kindose', style: AppText.small.copyWith(color: muted, fontWeight: FontWeight.w800))),
                Text('$day ${time.replaceAll(' AM', '').replaceAll(' PM', '')}', style: AppText.tiny.copyWith(fontSize: 12, color: muted)),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: AppText.title.copyWith(color: AppColors.ink)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _FakeAction('Mark as done', filled: true)),
                const SizedBox(width: 8),
                Expanded(child: _FakeAction('Snooze 1 hour')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeAction extends StatelessWidget {
  const _FakeAction(this.label, {this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.ink : const Color(0xFFF3F2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: AppText.small.copyWith(fontWeight: FontWeight.w800, color: filled ? AppColors.white : AppColors.ink),
      ),
    );
  }
}

/// Scales the child in once, with a little overshoot.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: child,
    );
  }
}
