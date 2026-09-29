import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../features/common/day_nav.dart';
import '../resources/colors.dart';
import '../services/plus/plus_access.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'buttons.dart';
import 'k_widgets.dart';
import 'press_scale.dart';

/// ‹ Today › with a tappable date that opens a calendar.
class DaySwitcher extends StatelessWidget {
  const DaySwitcher({super.key, required this.nav});

  final DayNav nav;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      nav.day.value;
      PlusAccess.active.value;
      Widget arrow(IconData icon, String label, VoidCallback? onTap) => CircleIconButton(
            icon: icon,
            label: label,
            size: 36.sp,
            background: k.card,
            onTap: onTap,
          );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(PhosphorIconsBold.caretLeft, 'Previous day', nav.canGoBack ? nav.previousDay : null),
          Semantics(
            button: true,
            label: 'Day: ${nav.dayTitle}. Pick a day',
            excludeSemantics: true,
            child: PressScale(
              onTap: () => nav.pickDay(context),
              child: Container(
                constraints: BoxConstraints(minHeight: 36.sp, minWidth: 64.sp),
                padding: EdgeInsets.symmetric(horizontal: 8.sp),
                alignment: Alignment.center,
                child: Text(
                  nav.dayTitle,
                  maxLines: 1,
                  style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: k.text),
                ),
              ),
            ),
          ),
          arrow(PhosphorIconsBold.caretRight, 'Next day', nav.canGoForward ? nav.nextDay : null),
        ],
      );
    });
  }
}

/// "Adding to Mon, 28 Sep · Back to today" shown on past days.
class PastDayBanner extends StatelessWidget {
  const PastDayBanner({super.key, required this.nav, this.verb = 'Adding to'});

  final DayNav nav;
  final String verb;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final fg = dark ? AppColors.amberSoft : AppColors.amberText;
    return Obx(() {
      nav.day.value;
      return AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: nav.isToday
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 8.sp),
                child: Container(
                  padding: EdgeInsets.fromLTRB(14.sp, 4.sp, 4.sp, 4.sp),
                  decoration: BoxDecoration(
                    color: dark ? k.card : AppColors.amberWash,
                    borderRadius: BorderRadius.circular(16.sp),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsBold.calendarDots, size: 16.sp, color: fg),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: Text(
                          '$verb ${nav.dayTitle == 'Yesterday' ? 'yesterday' : nav.dayTitle}',
                          style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: fg),
                        ),
                      ),
                      LinkButton(label: 'Back to today', onTap: nav.backToToday, color: k.text),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}
