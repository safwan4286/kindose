import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/logs.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../services/plus/access_service.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'weigh_ins_controller.dart';

/// Every weigh-in, newest first, grouped by month (Progress → Weigh-ins).
class WeighInsScreen extends GetView<WeighInsController> {
  const WeighInsScreen({super.key});

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
                  _PastButton(onTap: () => controller.logPast(context)),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                controller.watch();
                final groups = controller.groups;
                final count = controller.tracker.weights.length;
                return ListView(
                  padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 24.sp),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Weigh-ins',
                        style: AppText.h1.copyWith(
                          fontSize: 28.sp,
                          color: k.text,
                        ),
                      ),
                    ).enter(motion),
                    SizedBox(height: 4.sp),
                    Text(
                      count == 0
                          ? 'Nothing logged yet.'
                          : '$count ${count == 1 ? 'weigh-in' : 'weigh-ins'} · tap to edit, swipe to delete',
                      style: AppText.small.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: k.muted,
                      ),
                    ).enter(motion),
                    for (final (month, rows) in groups) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.sp, 18.sp, 4.sp, 8.sp),
                        child: Text(
                          month.toUpperCase(),
                          style: AppText.caps.copyWith(
                            fontSize: 11.5.sp,
                            letterSpacing: 1.1,
                            color: k.faint,
                          ),
                        ),
                      ),
                      for (final (w, diff) in rows)
                        _Row(
                          key: ValueKey(w.key),
                          controller: controller,
                          entry: w,
                          diff: diff,
                        ),
                    ],
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

class _PastButton extends StatelessWidget {
  const _PastButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PressScale(
      semanticLabel: 'Log a past weigh-in',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          height: 40.sp,
          padding: EdgeInsets.symmetric(horizontal: 14.sp),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(20.sp),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(PhosphorIconsBold.plus, size: 14.sp, color: k.text),
              SizedBox(width: 6.sp),
              Text(
                'Past weigh-in',
                style: AppText.small.copyWith(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: k.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One weigh-in: day tile, weight, change since the one before.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.controller,
    required this.entry,
    required this.diff,
  });

  final WeighInsController controller;
  final WeightEntry entry;

  /// Change since the weigh-in before; null for the first one.
  final double? diff;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;
    final d = entry.date;
    final dark = k.selectedBorder == AppColors.lime;
    final change = diff == null
        ? 'Starting weight'
        : '${c.signed(diff!)} since last';
    // Down is the usual goal, so it reads as good; up stays neutral.
    final down = diff != null && diff! < -0.05;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.sp),
        child: Dismissible(
          key: ValueKey('weight-${entry.key}'),
          direction: DismissDirection.endToStart,
          // Paywall before the row slides away; a locked swipe springs back.
          confirmDismiss: (_) => AccessService.ensure(),
          onDismissed: (_) => c.delete(entry),
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
          child: Semantics(
            button: true,
            label:
                '${Dates.shortWithDay(d)}, ${c.fmt(entry.kg)}, $change. Opens to edit.',
            excludeSemantics: true,
            child: PressScale(
              pressedScale: 0.98,
              onTap: () => c.edit(entry),
              child: Container(
                padding: EdgeInsets.fromLTRB(12.sp, 12.sp, 10.sp, 12.sp),
                color: k.card,
                child: Row(
                  children: [
                    Container(
                      width: 48.sp,
                      height: 52.sp,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: k.bg,
                        borderRadius: BorderRadius.circular(14.sp),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${d.day}',
                            style: AppText.number(18.sp)
                                .copyWith(color: k.text),
                          ),
                          Text(
                            Dates.weekdayShort(d.weekday).toUpperCase(),
                            style: AppText.caps.copyWith(
                              fontSize: 10.sp,
                              letterSpacing: 0.8,
                              color: k.faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.fmt(entry.kg),
                            style: AppText.title.copyWith(
                              fontSize: 16.sp,
                              color: k.text,
                            ),
                          ),
                          SizedBox(height: 2.sp),
                          Text(
                            change,
                            style: AppText.small.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: !down
                                  ? k.muted
                                  : (dark
                                        ? AppColors.lime
                                        : AppColors.limeText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PhosphorIcon(
                      PhosphorIconsBold.caretRight,
                      size: 16.sp,
                      color: k.faint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
