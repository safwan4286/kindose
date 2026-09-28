import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../services/tracker_service.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'weight_sheet.dart';

/// "Log something" sheet opened from the + button.
Future<void> showLogSheet() {
  Haptics.instance.lightImpact();
  return Get.bottomSheet<void>(const LogSheet(), isScrollControlled: true);
}

class LogSheet extends StatelessWidget {
  const LogSheet({super.key});

  TrackerService get _t => Get.find<TrackerService>();

  void _goTo(String route, [Object? args]) {
    Haptics.instance.selectionClick();
    popRoute();
    Get.toNamed<void>(route, arguments: args);
  }

  static String _litres(int ml) {
    final l = ml / 1000;
    return l == l.roundToDouble() ? l.toStringAsFixed(0) : l.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return KSafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: k.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.sp)),
        ),
        padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 40.sp),
        child: Obx(() {
          final p = _t.profile.value;
          final day = _t.today;
          final proteinGoal = p?.proteinGoalG ?? 100;
          final proteinLeft = (proteinGoal - day.proteinG).clamp(0, 999);
          final waterGoal = p?.waterGoalMl ?? 2500;
          final lastKg = _t.latestWeightKg;
          final useKg = p?.useKg ?? true;
          final lastWeight = lastKg == null
              ? 'Not logged yet'
              : 'Last: ${(useKg ? lastKg : lastKg * 2.20462).toStringAsFixed(1)} ${useKg ? 'kg' : 'lb'}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.sp,
                  height: 5.sp,
                  decoration: BoxDecoration(
                    color: k.border,
                    borderRadius: BorderRadius.circular(3.sp),
                  ),
                ),
              ),
              SizedBox(height: 14.sp),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Log something',
                        style: AppText.h2.copyWith(
                          fontSize: 24.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: PhosphorIconsBold.x,
                    label: 'Close',
                    size: 40,
                    onTap: popRoute,
                  ),
                ],
              ),
              SizedBox(height: 14.sp),
              const _DoseRow().enter(motion, delay: 80, dy: 0.3),
              SizedBox(height: 10.sp),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      icon: Img3d.biceps,
                      title: 'Protein',
                      sub: proteinLeft == 0
                          ? 'Goal reached'
                          : '$proteinLeft g to go',
                      bg: AppColors.tangerineSoft,
                      subColor: AppColors.tangerineText,
                      onTap: () => _goTo(Routes.addIntake, 'protein'),
                    ),
                  ),
                  SizedBox(width: 10.sp),
                  Expanded(
                    child: _Tile(
                      icon: Img3d.droplet,
                      title: 'Water',
                      sub: '${_litres(day.waterMl)} of ${_litres(waterGoal)} L',
                      bg: AppColors.aquaSoft,
                      subColor: AppColors.aquaText,
                      onTap: () => _goTo(Routes.addIntake, 'water'),
                    ),
                  ),
                ],
              ).enter(motion, delay: 130, dy: 0.3),
              SizedBox(height: 10.sp),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      icon: Img3d.chartDown,
                      title: 'Weight',
                      sub: lastWeight,
                      bg: k.card,
                      subColor: k.muted,
                      titleColor: k.text,
                      onTap: () {
                        Haptics.instance.selectionClick();
                        popRoute();
                        showWeightSheet();
                      },
                    ),
                  ),
                  SizedBox(width: 10.sp),
                  Expanded(
                    child: _Tile(
                      icon: Img3d.nauseated,
                      title: 'How I feel',
                      sub: 'Side effects, notes',
                      bg: AppColors.limeSoft,
                      subColor: AppColors.limeText,
                      onTap: () => _goTo(Routes.checkIn),
                    ),
                  ),
                ],
              ).enter(motion, delay: 170, dy: 0.3),
            ],
          );
        }),
      ),
    );
  }
}

/// Dose row at the top. Ink + "DUE TODAY" on dose day, quiet otherwise.
class _DoseRow extends StatelessWidget {
  const _DoseRow();

  @override
  Widget build(BuildContext context) {
    final t = Get.find<TrackerService>();
    final k = context.k;
    return Obx(() {
      final p = t.profile.value;
      var noMedicine = true;
      var tablet = false;
      var due = false;
      var sub = 'Add your medicine to get reminders';
      if (p != null && p.medicineId != Catalog.undecided) {
        noMedicine = false;
        tablet = p.form == 'tablet';
        due = t.isDoseDay();
        final name = Catalog.medicineName(p.medicineId, p.customMedicine);
        final mark = Catalog.medicine(p.medicineId).mark ?? '';
        final dose = p.strengthMg <= 0
            ? ''
            : ' ${Catalog.mgLabel(p.strengthMg)}';
        final next = t.nextDoseAt();
        if (due) {
          sub = tablet
              ? '$name$mark$dose'
              : '$name$mark$dose · ${Catalog.siteName(t.nextSiteId).toLowerCase()} next';
        } else if (t.doseOn(DateTime.now()) != null) {
          sub = 'Logged today · add another or fix a time';
        } else {
          sub = next == null
              ? '$name$mark$dose'
              : 'Next: ${Dates.relativeDay(next, DateTime.now())}';
        }
      }

      final bg = due ? AppColors.hero : k.card;
      final fg = due ? AppColors.white : k.text;
      final subColor = due ? AppColors.heroMuted : k.muted;
      final dark = k.selectedBorder == AppColors.lime;

      return PressScale(
        semanticLabel: noMedicine
            ? 'Add your medicine'
            : 'Log dose. $sub${due ? '. Due today' : ''}',
        onTap: () {
          Haptics.instance.selectionClick();
          popRoute();
          Get.toNamed<void>(noMedicine ? Routes.editPlan : Routes.logDose);
        },
        child: ExcludeSemantics(
          child: Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22.sp),
              border: due && dark ? Border.all(color: k.border) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 52.sp,
                  height: 52.sp,
                  decoration: BoxDecoration(
                    color: due ? AppColors.lime : AppColors.limeSoft,
                    borderRadius: BorderRadius.circular(16.sp),
                  ),
                  alignment: Alignment.center,
                  child: PhosphorIcon(
                    tablet ? PhosphorIconsBold.pill : PhosphorIconsBold.syringe,
                    size: 26.sp,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(width: 14.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tablet ? 'Tablet' : 'Dose',
                        style: AppText.title.copyWith(
                          fontSize: 17.sp,
                          color: fg,
                        ),
                      ),
                      SizedBox(height: 2.sp),
                      Text(
                        sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (due) ...[
                  SizedBox(width: 8.sp),
                  const KTag(
                    'Due today',
                    bg: AppColors.lime,
                    fg: AppColors.ink,
                  ),
                ] else
                  PhosphorIcon(
                    PhosphorIconsBold.caretRight,
                    size: 18.sp,
                    color: k.muted,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.bg,
    required this.subColor,
    required this.onTap,
    this.titleColor = AppColors.ink,
  });

  final String icon;
  final String title;
  final String sub;
  final Color bg;
  final Color subColor;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      semanticLabel: 'Log $title. $sub',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(14.sp),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22.sp),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThreeD(icon, size: 36.sp),
              SizedBox(height: 10.sp),
              Text(
                title,
                style: AppText.title.copyWith(
                  fontSize: 16.sp,
                  color: titleColor,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.small.copyWith(
                  fontSize: 12.5.sp,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
