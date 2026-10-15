import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/logs.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../services/plus/access_service.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/press_scale.dart';
import '../home/home_screen.dart';
import '../today/widgets/dose_card.dart';
import 'doses_controller.dart';
import 'widgets/dose_detail_sheet.dart';

/// Doses tab: the next dose (same card as Today), then the history with
/// a 1 month / 3 months / All / Custom filter. Tap a dose for its details,
/// Edit and Delete; swipe left to delete.
class DosesScreen extends GetView<DosesController> {
  const DosesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      bottom: false,
      child: Obx(() {
        controller.watch();
        if (controller.tracker.profile.value == null) {
          return const SizedBox.shrink();
        }
        final groups = controller.groups;
        final hasAny = controller.tracker.doses.isNotEmpty;
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, kNavClearance),
          children: [
            if (controller.eyebrow.isNotEmpty)
              Text(
                controller.eyebrow.toUpperCase(),
                style: AppText.caps.copyWith(
                  fontSize: 12.sp,
                  letterSpacing: 1.1,
                  color: k.faint,
                ),
              ).enter(motion),
            SizedBox(height: 4.sp),
            Semantics(
              header: true,
              child: Text(
                controller.title,
                style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text),
              ),
            ).enter(motion),
            SizedBox(height: 16.sp),
            const DoseCard().enter(motion, delay: 60),
            SizedBox(height: 24.sp),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'History',
                      style: AppText.h2.copyWith(
                        fontSize: 21.sp,
                        color: k.text,
                      ),
                    ),
                  ),
                ),
                if (hasAny) _Count(controller: controller),
              ],
            ).enter(motion, delay: 100),
            SizedBox(height: 10.sp),
            if (!hasAny)
              _Empty(tablet: controller.isTablet).enter(motion, delay: 120)
            else ...[
              KSegmented<DoseRange>(
                options: DoseRange.values,
                selected: controller.range.value,
                onChanged: controller.pickRange,
                labelOf: DosesController.rangeLabel,
                dense: true,
              ).enter(motion, delay: 120),
              if (groups.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 28.sp),
                  child: Text(
                    'Nothing logged in this range.',
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: k.muted,
                    ),
                  ),
                ),
              for (final (month, doses) in groups) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(4.sp, 18.sp, 4.sp, 8.sp),
                  child: Text(
                    month,
                    style: AppText.caps.copyWith(
                      fontSize: 11.5.sp,
                      letterSpacing: 1.1,
                      color: k.faint,
                    ),
                  ),
                ),
                for (final d in doses)
                  _DoseTile(key: ValueKey(d.id), dose: d, controller: controller),
              ],
            ],
          ],
        );
      }),
    );
  }
}

/// "4 doses"; with Custom it also shows the dates and taps to change them.
class _Count extends StatelessWidget {
  const _Count({required this.controller});

  final DosesController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final custom = controller.range.value == DoseRange.custom;
    final text = Text(
      controller.countLabel,
      style: AppText.small.copyWith(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w700,
        color: custom ? k.text : k.faint,
        decoration: custom ? TextDecoration.underline : null,
      ),
    );
    if (!custom) return text;
    return PressScale(
      semanticLabel: 'Change dates, ${controller.countLabel}',
      onTap: () => controller.pickRange(DoseRange.custom),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.sp),
        child: text,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.tablet});

  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Container(
      padding: EdgeInsets.fromLTRB(18.sp, 22.sp, 18.sp, 22.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        children: [
          Container(
            width: 56.sp,
            height: 56.sp,
            decoration: BoxDecoration(
              color: dark
                  ? AppColors.lime.withValues(alpha: 0.14)
                  : AppColors.limeSoft,
              borderRadius: BorderRadius.circular(18.sp),
            ),
            child: Icon(
              tablet ? PhosphorIconsBold.pill : PhosphorIconsBold.syringe,
              size: 26.sp,
              color: dark ? AppColors.lime : AppColors.ink,
            ),
          ),
          SizedBox(height: 10.sp),
          Text(
            tablet ? 'No tablets logged yet' : 'No doses yet',
            style: AppText.title.copyWith(fontSize: 16.sp, color: k.text),
          ),
          SizedBox(height: 6.sp),
          Text(
            tablet
                ? 'Every tablet you log shows here with its date and dose. Tap one to fix it.'
                : 'Every dose you log shows here with its date, spot and dose. Tap one to fix it.',
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(
              fontSize: 13.5.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: k.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseTile extends StatelessWidget {
  const _DoseTile({super.key, required this.dose, required this.controller});

  final DoseLog dose;
  final DosesController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final d = dose;
    final status = controller.statusOf(d);
    final note = controller.noteOf(d);
    final title = controller.titleOf(d);
    final line = controller.lineOf(d);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.sp),
        child: Dismissible(
          key: ValueKey('dose-${d.id}'),
          direction: DismissDirection.endToStart,
          // Paywall before the row slides away; a locked swipe springs back.
          confirmDismiss: (_) => AccessService.ensure(),
          onDismissed: (_) => controller.delete(d),
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
                '$title, ${Dates.shortWithDay(d.takenAt)}, $line${status == null ? '' : ', ${status.$1}'}. Opens details.',
            excludeSemantics: true,
            child: PressScale(
              pressedScale: 0.98,
              onTap: () => showDoseDetailSheet(controller, d),
              child: Container(
                padding: EdgeInsets.fromLTRB(12.sp, 12.sp, 10.sp, 12.sp),
                color: k.card,
                child: Row(
                  children: [
                    _DayTile(date: d.takenAt),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.title.copyWith(
                                    fontSize: 15.sp,
                                    color: k.text,
                                  ),
                                ),
                              ),
                              if (status != null) ...[
                                SizedBox(width: 6.sp),
                                _StatusChip(
                                  text: status.$1,
                                  ok: status.$2,
                                  dark: dark,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2.sp),
                          Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.small.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: k.muted,
                            ),
                          ),
                          if (note != null) ...[
                            SizedBox(height: 4.sp),
                            Text(
                              '“$note”',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.small.copyWith(
                                fontSize: 12.5.sp,
                                fontStyle: FontStyle.italic,
                                color: k.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 6.sp),
                    Icon(
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

/// "16 / FRI" calendar tile.
class _DayTile extends StatelessWidget {
  const _DayTile({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      width: 46.sp,
      height: 50.sp,
      decoration: BoxDecoration(
        color: k.bg,
        borderRadius: BorderRadius.circular(14.sp),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: AppText.number(20.sp).copyWith(color: k.text),
          ),
          Text(
            Dates.weekdayShort(date.weekday).toUpperCase(),
            style: AppText.caps.copyWith(
              fontSize: 10.sp,
              letterSpacing: 0.8,
              color: k.faint,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.ok, required this.dark});

  final String text;
  final bool ok;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = ok
        ? (dark ? AppColors.lime.withValues(alpha: 0.14) : AppColors.limeSoft)
        : (dark
              ? AppColors.tangerine.withValues(alpha: 0.18)
              : AppColors.tangerineSoft);
    final fg = ok
        ? (dark ? AppColors.lime : const Color(0xFF4B5E0A))
        : (dark ? AppColors.tangerine : AppColors.tangerineText);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Text(
        text,
        style: AppText.small.copyWith(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
