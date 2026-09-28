import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/press_scale.dart';
import '../today_controller.dart';

/// The top card on Today. One widget, many states (see [DoseCardState]).
class DoseCard extends GetView<TodayController> {
  const DoseCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(a), child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey(controller.doseState),
        child: switch (controller.doseState) {
          DoseCardState.noMedicine => const _NoMedicine(),
          DoseCardState.doseDay => const _DoseDay(),
          DoseCardState.overdue => const _Overdue(),
          DoseCardState.takenToday => const _TakenToday(),
          DoseCardState.daily => const _Daily(),
          DoseCardState.firstDose || DoseCardState.upcoming => const _Upcoming(),
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ pieces

TextStyle _big(Color c, {double size = 34}) =>
    AppText.h1.copyWith(fontSize: size.sp, height: 1.05, letterSpacing: -1, color: c);

TextStyle _caps(Color c) => AppText.caps.copyWith(fontSize: 12.sp, letterSpacing: 1.1, color: c);

class _InkCard extends StatelessWidget {
  const _InkCard({required this.child, this.color = AppColors.hero});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = context.k.selectedBorder == AppColors.lime;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.sp),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24.sp),
        border: dark && color == AppColors.hero ? Border.all(color: context.k.border) : null,
      ),
      child: child,
    );
  }
}

class _MedicineLine extends GetView<TodayController> {
  const _MedicineLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    final mark = controller.medicineMark;
    final dose = controller.doseLabel;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: controller.medicineName),
        if (mark != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Text(mark, style: AppText.small.copyWith(fontSize: 8.sp, color: color)),
          ),
        if (dose.isNotEmpty) TextSpan(text: ' $dose'),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: color),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip(this.cells, {this.daily = false});

  final List<(String, String)> cells;
  final bool daily;

  @override
  Widget build(BuildContext context) {
    final size = daily ? 26.sp : 30.sp;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final (letter, state) in cells)
            Expanded(
              child: Column(
                children: [
                  Text(
                    letter,
                    style: AppText.small.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: state == 'today'
                          ? AppColors.white
                          : state == 'dose'
                              ? AppColors.lime
                              : AppColors.heroMuted,
                    ),
                  ),
                  SizedBox(height: 6.sp),
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: switch (state) {
                        'done' => daily ? AppColors.lime : AppColors.lime.withValues(alpha: 0.18),
                        'dose' => AppColors.lime,
                        'today' => null,
                        _ => AppColors.white.withValues(alpha: daily ? 0.12 : 0.08),
                      },
                      border: state == 'today' ? Border.all(color: AppColors.white, width: 2) : null,
                    ),
                    child: switch (state) {
                      'done' when !daily => Icon(PhosphorIconsBold.check, size: 14.sp, color: AppColors.lime),
                      'dose' => Icon(PhosphorIconsBold.syringe, size: 15.sp, color: AppColors.ink),
                      _ => null,
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 12.sp),
        child: Container(height: 1, color: AppColors.heroMuted.withValues(alpha: 0.18)),
      );
}

class _TextLink extends StatelessWidget {
  const _TextLink(this.label, this.onTap, {required this.color});

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 40.sp),
          child: Center(
            widthFactor: 1,
            child: Text(label, style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: color)),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ states

class _Upcoming extends GetView<TodayController> {
  const _Upcoming();

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    final first = controller.doseState == DoseCardState.firstDose;
    final week = controller.treatmentWeek;
    return Semantics(
      container: true,
      label: '${first ? 'First dose' : 'Next dose'} ${controller.countdownLabel}, ${controller.nextDoseWhen}',
      child: _InkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    first ? 'YOUR FIRST DOSE' : week == null ? 'NEXT DOSE' : 'NEXT DOSE · WEEK $week',
                    style: _caps(AppColors.heroMuted),
                  ),
                ),
                Flexible(child: _MedicineLine(color: AppColors.heroMuted)),
              ],
            ),
            SizedBox(height: 8.sp),
            Text(controller.countdownLabel, style: _big(AppColors.lime)),
            SizedBox(height: 2.sp),
            Text(
              controller.nextDoseWhen,
              style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.white),
            ),
            SizedBox(height: 16.sp),
            _Strip(controller.weekStrip),
            const _Divider(),
            Row(
              children: [
                if (!controller.isTablet) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10.sp),
                    ),
                    child: Text(
                      controller.nextSiteName,
                      style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.lime),
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Text('next site', style: AppText.small.copyWith(fontSize: 13.sp, color: AppColors.heroMuted)),
                ],
                const Spacer(),
                _TextLink('Move date ›', () => controller.moveDate(context), color: AppColors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseDay extends GetView<TodayController> {
  const _DoseDay();

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    Widget box(String label, String value) => Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _caps(AppColors.limeText).copyWith(fontSize: 11.sp, letterSpacing: 0.6)),
                SizedBox(height: 2.sp),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
        );

    return _InkCard(
      color: AppColors.lime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(9.sp)),
                child: Text('DOSE DAY', style: _caps(AppColors.lime).copyWith(fontSize: 11.5.sp, letterSpacing: 1)),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _MedicineLine(color: AppColors.limeText),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          Semantics(header: true, child: Text('Today, ${controller.doseTime}', style: _big(AppColors.ink, size: 32))),
          if (!controller.isTablet) ...[
            SizedBox(height: 14.sp),
            Row(
              children: [
                box('NEXT SITE', controller.nextSiteName),
                SizedBox(width: 8.sp),
                box('LAST TIME', controller.lastSiteName ?? 'First dose'),
              ],
            ),
          ],
          SizedBox(height: 14.sp),
          PillButton(
            label: controller.isTablet ? 'Log my tablet' : 'Log my dose',
            icon: PhosphorIconsBold.check,
            ink: true,
            onPressed: controller.logDose,
          ),
          Center(
            child: _TextLink('Taking it another day?', () => controller.moveDate(context), color: AppColors.limeText),
          ),
        ],
      ),
    );
  }
}

class _Overdue extends GetView<TodayController> {
  const _Overdue();

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    final k = context.k;
    final next = controller.nextDoseAt;
    final day = next == null ? 'your last' : '${controller.nextDoseWhen.split(' · ').first}’s';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(24.sp),
        border: Border.all(color: AppColors.tangerine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10.sp, height: 10.sp, decoration: const BoxDecoration(color: AppColors.tangerine, shape: BoxShape.circle)),
              SizedBox(width: 8.sp),
              Text(
                controller.daysUntilNext == -1 ? 'DUE YESTERDAY' : 'DUE ${-controller.daysUntilNext} DAYS AGO',
                style: _caps(AppColors.tangerineText),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Text('Did you take $day dose?', style: AppText.h1.copyWith(fontSize: 24.sp, height: 1.1, color: k.text)),
          SizedBox(height: 6.sp),
          Text(
            'Log it with the real time, so your schedule stays right.',
            style: AppText.bodyText.copyWith(fontSize: 13.5.sp, height: 1.45, color: k.muted),
          ),
          SizedBox(height: 14.sp),
          Row(
            children: [
              Expanded(child: PillButton(label: 'Yes, log it', onPressed: controller.logDose)),
              SizedBox(width: 8.sp),
              _TextLink('Move date', () => controller.moveDate(context), color: k.text),
            ],
          ),
          SizedBox(height: 6.sp),
          Text(
            'Missed a dose? Check your medicine leaflet or ask your doctor what to do.',
            style: AppText.small.copyWith(fontSize: 12.sp, height: 1.45, color: k.faint),
          ),
        ],
      ),
    );
  }
}

class _TakenToday extends GetView<TodayController> {
  const _TakenToday();

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    final dose = controller.doseToday;
    final site = dose == null || dose.site.isEmpty ? '' : ' · ${controller.siteName(dose.site)}';
    return _InkCard(
      child: Row(
        children: [
          Container(
            width: 48.sp,
            height: 48.sp,
            decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
            child: Icon(PhosphorIconsBold.check, size: 24.sp, color: AppColors.ink),
          ),
          SizedBox(width: 14.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dose logged', style: AppText.h1.copyWith(fontSize: 22.sp, color: AppColors.white)),
                SizedBox(height: 2.sp),
                Text(
                  '${dose == null ? '' : controller.timeOf(dose.takenAt)}$site · next ${controller.nextDoseWhen.split(' · ').first}',
                  style: AppText.small.copyWith(fontSize: 13.sp, color: AppColors.heroMuted),
                ),
              ],
            ),
          ),
          _TextLink('Undo', controller.undoDoseToday, color: AppColors.lime),
        ],
      ),
    );
  }
}

class _Daily extends GetView<TodayController> {
  const _Daily();

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    final taken = controller.doseToday;
    return _InkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(controller.isTablet ? "TODAY'S TABLET" : "TODAY'S DOSE", style: _caps(AppColors.heroMuted))),
              Flexible(child: _MedicineLine(color: AppColors.heroMuted)),
            ],
          ),
          SizedBox(height: 8.sp),
          Text(controller.doseTime, style: _big(AppColors.white, size: 30)),
          if (controller.isTablet)
            Text(
              'Follow the timing your leaflet gives for food and water.',
              style: AppText.small.copyWith(fontSize: 13.sp, color: AppColors.heroMuted),
            ),
          SizedBox(height: 14.sp),
          _Strip(controller.dailyStrip, daily: true),
          SizedBox(height: 14.sp),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: taken == null
                ? PillButton(
                    key: const ValueKey('take'),
                    label: 'Taken',
                    icon: PhosphorIconsBold.check,
                    lime: true,
                    busy: controller.busy.value,
                    onPressed: controller.markTaken,
                  )
                : Row(
                    key: const ValueKey('done'),
                    children: [
                      Icon(PhosphorIconsBold.check, size: 18.sp, color: AppColors.lime),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: Text(
                          'Taken at ${controller.timeOf(taken.takenAt)}',
                          style: AppText.bodyStrong.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.white),
                        ),
                      ),
                      _TextLink('Undo', controller.undoDoseToday, color: AppColors.lime),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoMedicine extends GetView<TodayController> {
  const _NoMedicine();

  @override
  Widget build(BuildContext context) => Obx(() {
        controller.watch();
        return _build(context);
      });

  Widget _build(BuildContext context) {
    return _InkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR MEDICINE', style: _caps(AppColors.heroMuted)),
          SizedBox(height: 8.sp),
          Text('Not added yet', style: _big(AppColors.white, size: 28)),
          SizedBox(height: 4.sp),
          Text(
            'Add it once you and your doctor decide. Everything else works already.',
            style: AppText.small.copyWith(fontSize: 13.5.sp, height: 1.45, color: AppColors.heroMuted),
          ),
          SizedBox(height: 14.sp),
          PillButton(label: 'Add my medicine', lime: true, onPressed: controller.chooseMedicine),
        ],
      ),
    );
  }
}
