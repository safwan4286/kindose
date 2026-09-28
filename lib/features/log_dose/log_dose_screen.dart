import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/body_map.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_sheet.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'log_dose_controller.dart';

/// Log (or edit) a dose: when, where on the body, how it felt, a note.
/// Tablet users get the short version: when + note.
class LogDoseScreen extends GetView<LogDoseController> {
  const LogDoseScreen({super.key});

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
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 0),
              child: Row(
                children: [
                  BackCircle(onTap: popRoute),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Obx(() => Text(
                          controller.eyebrow,
                          style: AppText.caps.copyWith(fontSize: 12.sp, letterSpacing: 1.1, color: k.muted),
                        )),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 24.sp),
                children: [
                  Obx(() => Semantics(
                        header: true,
                        child: Text(controller.title, style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text)),
                      )).enter(motion),
                  SizedBox(height: 16.sp),
                  const _MedicineCard().enter(motion, delay: 60),
                  const _LateCard(),
                  _Label('When').enter(motion, delay: 110),
                  const _WhenRow().enter(motion, delay: 130),
                  if (!controller.isTablet) ...[
                    _Label('Where · ${Catalog.sites.length} spots', trailing: 'Body facing you').enter(motion, delay: 170),
                    const _SiteCard().enter(motion, delay: 190),
                    _Label('How did it feel?', optional: true).enter(motion, delay: 230),
                    const _PainRow().enter(motion, delay: 250),
                  ],
                  SizedBox(height: 12.sp),
                  const _NoteField().enter(motion, delay: 290),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 12.sp),
              child: Obx(() => PillButton(
                    label: controller.saveLabel,
                    icon: PhosphorIconsBold.check,
                    busy: controller.saving.value,
                    onPressed: controller.save,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ parts

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing, this.optional = false});

  final String text;
  final String? trailing;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: EdgeInsets.only(top: 22.sp, bottom: 10.sp),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: text.toUpperCase()),
                if (optional)
                  TextSpan(
                    text: '  (optional)',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0, color: k.faint),
                  ),
              ]),
              style: AppText.caps.copyWith(fontSize: 12.sp, letterSpacing: 1.1, color: k.muted),
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: AppText.small.copyWith(fontSize: 12.5.sp, color: k.muted)),
        ],
      ),
    );
  }
}

class _MedicineCard extends GetView<LogDoseController> {
  const _MedicineCard();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      final mark = controller.medicineMark;
      final strength = controller.strengthLabel;
      return Container(
        padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 12.sp, 14.sp),
        decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(22.sp)),
        child: Row(
          children: [
            KIconTile(
              icon: controller.isTablet ? PhosphorIconsBold.pill : PhosphorIconsBold.syringe,
              bg: AppColors.limeSoft,
              fg: AppColors.ink,
              size: 44,
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: controller.medicineName),
                      if (mark != null)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.top,
                          child: Text(mark, style: AppText.tiny.copyWith(fontSize: 9.sp, color: k.text)),
                        ),
                      if (strength.isNotEmpty) TextSpan(text: ' $strength'),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(fontSize: 16.sp, color: k.text),
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    controller.medicineSub,
                    style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: k.muted),
                  ),
                ],
              ),
            ),
            SoftButton(
              label: 'Change',
              height: 36,
              outlined: true,
              onPressed: () => controller.changeDose(context),
            ),
          ],
        ),
      );
    });
  }
}

/// Shown when the dose is 2+ days after the planned day. Only moves the
/// reminder, as the user chooses. Never says what to take.
class _LateCard extends GetView<LogDoseController> {
  const _LateCard();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      final late = controller.lateDays;
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: late == 0
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: EdgeInsets.only(top: 12.sp),
                child: Container(
                  padding: EdgeInsets.all(14.sp),
                  decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(18.sp)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$late days after your usual ${controller.usualDayName}',
                        style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        'When should your next reminder be?',
                        style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: k.muted),
                      ),
                      SizedBox(height: 12.sp),
                      _LateOption(
                        title: 'Keep ${controller.usualDayName}s',
                        sub: 'next ${controller.nextIfKeep}',
                        selected: controller.keepDay.value,
                        onTap: () => controller.pickKeepDay(true),
                      ),
                      SizedBox(height: 8.sp),
                      _LateOption(
                        title: 'Count from ${controller.todayDayName}',
                        sub: 'next ${controller.nextIfCount}',
                        selected: !controller.keepDay.value,
                        onTap: () => controller.pickKeepDay(false),
                      ),
                      SizedBox(height: 12.sp),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
                        decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(14.sp)),
                        child: Text(
                          "Not sure what to do about a late dose? Check your medicine's leaflet or ask your doctor or pharmacist.",
                          style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: k.textSoft),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}

class _LateOption extends StatelessWidget {
  const _LateOption({required this.title, required this.sub, required this.selected, required this.onTap});

  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ChoiceBox(
        selected: selected,
        onTap: onTap,
        radius: 14,
        idleBorder: k.border,
        alignment: Alignment.centerLeft,
        semanticLabel: '$title, $sub',
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: title),
            TextSpan(text: ' · $sub', style: TextStyle(fontWeight: FontWeight.w600, color: k.muted)),
          ]),
          style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: k.text),
        ),
    );
  }
}

class _WhenRow extends GetView<LogDoseController> {
  const _WhenRow();

  static const Map<DoseTime, String> _labels = {
    DoseTime.now: 'Now',
    DoseTime.earlier: 'Earlier',
    DoseTime.pick: 'Pick',
  };

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      final mode = controller.timeMode.value;
      return Row(
        children: [
          for (final t in DoseTime.values) ...[
            if (t != DoseTime.now) SizedBox(width: 8.sp),
            Expanded(
              child: ChoiceBox(
                selected: t == mode,
                height: 56.sp,
                semanticLabel: '${_labels[t]}, ${controller.timeSub(t)}',
                onTap: () => controller.pickTime(context, t),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_labels[t] ?? '', style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text)),
                    Text(
                      controller.timeSub(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tiny.copyWith(fontSize: 12.sp, color: k.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _SiteCard extends GetView<LogDoseController> {
  const _SiteCard();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      final site = controller.site.value;
      final recent = controller.recentSites;
      final tag = controller.siteTag;
      final (tagBg, tagFg) = switch (tag) {
        SiteTag.suggested => (AppColors.limeSoft, AppColors.limeText),
        SiteTag.usedLast => (AppColors.amberSoft, AppColors.amberText),
        _ => (k.cardAlt, k.muted),
      };
      final warn = tag == SiteTag.usedLast;
      return Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(24.sp)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: BodyMap(
                selected: site,
                suggested: controller.isEditing ? null : controller.suggestedSite,
                rankOf: controller.recentRank,
                onPick: controller.pickSite,
              ),
            ),
            SizedBox(height: 14.sp),
            Divider(height: 1, color: k.border),
            SizedBox(height: 14.sp),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SELECTED', style: AppText.caps.copyWith(fontSize: 11.5.sp, color: k.muted)),
                      SizedBox(height: 2.sp),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          Catalog.siteName(site),
                          key: ValueKey(site),
                          style: AppText.h3.copyWith(fontSize: 19.sp, color: k.text),
                        ),
                      ),
                      SizedBox(height: 6.sp),
                      KTag(controller.siteTagText, bg: tagBg, fg: tagFg),
                    ],
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  flex: 1,
                  child: recent.isEmpty
                      ? Text(
                          'Your first logged spot will show here.',
                          style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: k.muted),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last used', style: AppText.small.copyWith(fontSize: 12.5.sp, color: k.text)),
                            for (var i = 0; i < recent.length; i++)
                              Text(
                                '${i + 1} · ${Catalog.siteName(recent[i].site)} · ${Dates.short(recent[i].takenAt)}',
                                style: AppText.small.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600, color: k.muted),
                              ),
                          ],
                        ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
              decoration: BoxDecoration(
                color: warn ? AppColors.amberWash : k.bg,
                borderRadius: BorderRadius.circular(14.sp),
              ),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  controller.siteHint,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: warn ? AppColors.amberText : k.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PainRow extends GetView<LogDoseController> {
  const _PainRow();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      final picked = controller.pain.value;
      return Row(
        children: [
          for (var i = 0; i < Catalog.painLabels.length; i++) ...[
            if (i > 0) SizedBox(width: 8.sp),
            Expanded(
              child: ChoiceBox(
                selected: picked == i,
                height: 56.sp,
                radius: 16,
                padding: EdgeInsets.symmetric(horizontal: 4.sp),
                semanticLabel: 'Felt: ${Catalog.painLabels[i]}',
                onTap: () => controller.pickPain(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var d = 1; d <= 3; d++)
                            Container(
                              width: 6.sp,
                              height: 6.sp,
                              margin: EdgeInsets.symmetric(horizontal: 1.5.sp),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i >= d ? (i == 3 ? AppColors.pain : k.text) : k.border,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5.sp),
                    Text(
                      Catalog.painLabels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: k.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _NoteField extends GetView<LogDoseController> {
  const _NoteField();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      if (controller.showNote.value) {
        return TextField(
          controller: controller.noteCtrl,
          autofocus: controller.noteCtrl.text.isEmpty,
          maxLines: 3,
          minLines: 1,
          maxLength: 280,
          textCapitalization: TextCapitalization.sentences,
          style: AppText.bodyStrong.copyWith(fontSize: 14.5.sp, color: k.text),
          decoration: InputDecoration(hintText: controller.isTablet ? 'Anything worth remembering?' : 'New pen, bruise, anything to remember'),
        );
      }
      return Material(
        color: k.card,
        borderRadius: BorderRadius.circular(18.sp),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.sp),
          onTap: () => controller.showNote.value = true,
          child: Container(
            constraints: BoxConstraints(minHeight: 52.sp),
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsBold.pencilSimple, size: 18.sp, color: k.muted),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    controller.isTablet ? 'Add a note' : 'Add a note (new pen, bruise…)',
                    style: AppText.bodyStrong.copyWith(fontSize: 14.5.sp, color: k.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
