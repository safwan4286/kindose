import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../models/logs.dart';
import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/toast.dart';
import '../doses_controller.dart';

/// Tap a dose in the history: its details, then Edit or Delete.
Future<void> showDoseDetailSheet(DosesController c, DoseLog d) {
  Haptics.instance.selectionClick();
  return Get.bottomSheet<void>(
    _DoseDetailSheet(controller: c, dose: d),
    isScrollControlled: true,
  );
}

class _DoseDetailSheet extends StatelessWidget {
  const _DoseDetailSheet({required this.controller, required this.dose});

  final DosesController controller;
  final DoseLog dose;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final red = dark ? const Color(0xFFFF8A80) : AppColors.danger;
    final d = dose;
    final tablet = controller.isTablet;
    final status = controller.statusOf(d);
    final facts = <(String, String)>[
      ('Dose', controller.medicineOf(d)),
      if (!tablet && d.site.isNotEmpty) ('Spot', Catalog.siteName(d.site)),
      if (!tablet) ('How it felt', controller.painOf(d)),
      if (status != null) ('Timing', status.$1),
      ('Note', controller.noteOf(d) ?? '—'),
    ];

    Widget action(
      IconData icon,
      String title,
      String sub,
      VoidCallback onTap, {
      bool danger = false,
    }) => Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: Semantics(
        button: true,
        label: '$title. $sub',
        excludeSemantics: true,
        child: PressScale(
          onTap: () {
            popRoute();
            onTap();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
            decoration: BoxDecoration(
              color: k.card,
              borderRadius: BorderRadius.circular(18.sp),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.sp,
                  height: 40.sp,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: danger
                        ? red.withValues(alpha: 0.12)
                        : (dark
                              ? AppColors.lime.withValues(alpha: 0.14)
                              : AppColors.limeSoft),
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                  child: Icon(
                    icon,
                    size: 20.sp,
                    color: danger ? red : (dark ? AppColors.lime : AppColors.ink),
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.title.copyWith(
                          fontSize: 15.sp,
                          color: danger ? red : k.text,
                        ),
                      ),
                      Text(
                        sub,
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
      ),
    );

    return KSheetFrame(
      title: tablet ? 'Tablet' : 'Dose ${controller.numberOf(d)}',
      sub: '${Dates.weekdayName(d.takenAt.weekday)}, ${Dates.short(d.takenAt)} ${d.takenAt.year} · ${Dates.time(d.takenAt)}',
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.sp),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(18.sp),
          ),
          child: Column(
            children: [
              for (var i = 0; i < facts.length; i++)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 11.sp),
                  decoration: BoxDecoration(
                    border: i == facts.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: k.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facts[i].$1,
                        style: AppText.small.copyWith(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: k.muted,
                        ),
                      ),
                      SizedBox(width: 16.sp),
                      Expanded(
                        child: Text(
                          facts[i].$2,
                          textAlign: TextAlign.right,
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.sp),
        action(
          PhosphorIconsBold.pencilSimple,
          tablet ? 'Edit tablet' : 'Edit dose',
          tablet ? 'Date, time, dose, note' : 'Date, time, spot, dose, note',
          () => controller.edit(d),
        ),
        action(
          PhosphorIconsBold.trash,
          tablet ? 'Delete tablet' : 'Delete dose',
          'Asks first',
          () => controller.delete(d),
          danger: true,
        ),
      ],
    );
  }
}
