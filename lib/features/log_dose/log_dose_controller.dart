import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/tracker_service.dart';
import '../../widgets/ask_number.dart';
import '../../widgets/toast.dart';
import '../dose_done/dose_done_controller.dart';
import '../guide/guide_controller.dart';
import 'widgets/dose_sheets.dart';
import '../../widgets/k_date_picker.dart';

/// When the dose was taken: right now, earlier today, or a picked date.
enum DoseTime { now, earlier, pick }

/// Log dose screen. Pass a [DoseLog] as the route argument to edit it.
class LogDoseController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController noteCtrl = TextEditingController();

  /// The dose being edited, or null for a new one.
  final Rxn<DoseLog> editing = Rxn<DoseLog>();

  final Rx<DateTime> takenAt = DateTime.now().obs;
  final Rx<DoseTime> timeMode = DoseTime.now.obs;
  final RxString site = ''.obs;

  /// 0–3 (Catalog.painLabels) or null when skipped.
  final RxnInt pain = RxnInt();
  final RxBool showNote = false.obs;
  final RxBool saving = false.obs;

  /// Strength for this dose ("Change"). Starts at the usual dose.
  final RxDouble strengthMg = 0.0.obs;

  /// "Also make this my usual dose" in the Change sheet.
  final RxBool makeUsual = false.obs;

  /// Late dose: keep the usual weekday (true) or count from this dose.
  final RxBool keepDay = true.obs;

  @override
  void onInit() {
    super.onInit();
    strengthMg.value = tracker.profile.value?.strengthMg ?? 0;
    site.value = tracker.nextSiteId;
    final arg = Get.arguments;
    if (arg is DoseLog) _startEditing(arg);
  }

  @override
  void onClose() {
    noteCtrl.dispose();
    super.onClose();
  }

  void _startEditing(DoseLog d) {
    editing.value = d;
    takenAt.value = d.takenAt;
    timeMode.value = DoseTime.pick;
    if (d.site.isNotEmpty) site.value = d.site;
    pain.value = d.pain;
    strengthMg.value = d.strengthMg;
    noteCtrl.text = d.note ?? '';
    showNote.value = noteCtrl.text.isNotEmpty;
    makeUsual.value = false;
  }

  // ---------------------------------------------------------------- basics

  UserProfile? get profile => tracker.profile.value;
  bool get isTablet => profile?.form == 'tablet';
  bool get isEditing => editing.value != null;

  /// Injection guide on top; its last step comes back here.
  void openGuide() {
    Haptics.instance.lightImpact();
    Get.toNamed<void>(
      Routes.guide,
      arguments: const GuideArgs(fromLogDose: true),
    );
  }

  String get medicineName {
    final p = profile;
    return p == null
        ? 'Dose'
        : Catalog.medicineName(p.medicineId, p.customMedicine);
  }

  Medicine? get medicine {
    final p = profile;
    return p == null ? null : Catalog.medicine(p.medicineId);
  }

  String? get medicineMark => medicine?.mark;

  String get strengthLabel =>
      strengthMg.value > 0 ? Catalog.mgLabel(strengthMg.value) : '';

  bool get isUsualStrength => strengthMg.value == (profile?.strengthMg ?? 0);

  String get medicineSub {
    if (isEditing) return 'Editing a saved dose';
    if (makeUsual.value) return 'Your new usual dose';
    return isUsualStrength ? 'Your usual dose' : 'Just for this dose';
  }

  /// "DOSE 16 · WEEK 16" (or "DAY 38" for daily tablets).
  String get eyebrow {
    final e = editing.value;
    final n = e == null ? tracker.doses.length + 1 : tracker.doseNumberOf(e.id);
    final week = _treatmentWeek;
    if (profile?.isDaily ?? false) {
      final start = profile?.treatmentStartedAt;
      if (start == null) return 'DOSE $n';
      return 'DAY ${Dates.daysBetween(start, takenAt.value) + 1}';
    }
    return week == null ? 'DOSE $n' : 'DOSE $n · WEEK $week';
  }

  int? get _treatmentWeek {
    final start =
        profile?.treatmentStartedAt ??
        (tracker.doses.isEmpty ? null : tracker.doses.last.takenAt);
    if (start == null || start.isAfter(takenAt.value)) return null;
    return Dates.daysBetween(start, takenAt.value) ~/ 7 + 1;
  }

  String get title {
    if (isEditing) return 'Edit dose';
    return isTablet ? 'Taken today?' : 'Log your dose';
  }

  String get saveLabel {
    if (isEditing) return 'Save changes';
    if (isTablet) return 'Mark as taken';
    return 'Log dose · ${Catalog.siteName(site.value)}';
  }

  // ------------------------------------------------------------------ time

  String timeSub(DoseTime t) => switch (t) {
    DoseTime.now => Dates.time(DateTime.now()),
    DoseTime.earlier =>
      timeMode.value == DoseTime.earlier ? Dates.time(takenAt.value) : 'Today',
    DoseTime.pick =>
      timeMode.value == DoseTime.pick
          ? Dates.short(takenAt.value)
          : 'Date & time',
  };

  Future<void> pickTime(BuildContext context, DoseTime t) async {
    Haptics.instance.selectionClick();
    final now = DateTime.now();
    switch (t) {
      case DoseTime.now:
        takenAt.value = now;
        timeMode.value = t;
      case DoseTime.earlier:
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(takenAt.value),
          helpText: 'When today?',
        );
        if (time == null) return;
        final picked = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        takenAt.value = picked.isAfter(now) ? now : picked;
        timeMode.value = t;
      case DoseTime.pick:
        final date = await showKDatePicker(
          context: context,
          initialDate: takenAt.value,
          firstDate: now.subtract(const Duration(days: 90)),
          lastDate: now,
          title: 'When did you take it?',
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(takenAt.value),
        );
        if (time == null) return;
        final picked = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        takenAt.value = picked.isAfter(now) ? now : picked;
        timeMode.value = t;
    }
  }

  // ------------------------------------------------------------------ site

  String get suggestedSite => tracker.nextSiteId;

  /// Last 3 injections with a site, newest first (not the one being edited).
  List<DoseLog> get recentSites => tracker.siteDoses
      .where((d) => d.id != editing.value?.id)
      .take(3)
      .toList();

  /// 1 = used last time, 2, 3, or 0 when not in the last 3.
  int recentRank(String id) {
    final list = recentSites;
    for (var i = 0; i < list.length; i++) {
      if (list[i].site == id) return i + 1;
    }
    return 0;
  }

  void pickSite(String id) {
    if (site.value == id) return;
    Haptics.instance.selectionClick();
    site.value = id;
  }

  /// Tag under the selected spot name.
  SiteTag get siteTag {
    final id = site.value;
    final rank = recentRank(id);
    if (rank == 1) return SiteTag.usedLast;
    if (id == suggestedSite && !isEditing) return SiteTag.suggested;
    if (rank > 0) return SiteTag.usedRecently;
    return SiteTag.fresh;
  }

  String get siteTagText => switch (siteTag) {
    SiteTag.suggested => 'Suggested next',
    SiteTag.usedLast => 'Used last time',
    SiteTag.usedRecently => 'Used ${recentRank(site.value)} doses ago',
    SiteTag.fresh => 'Not used recently',
  };

  String get siteHint => switch (siteTag) {
    SiteTag.suggested =>
      recentSites.isEmpty
          ? 'We will suggest a new spot each time so your skin can rest.'
          : 'Not used in your last ${recentSites.length} doses, so it is next in your rotation.',
    SiteTag.usedLast =>
      'You used this spot last time. Picking a different one is gentler on your skin.',
    _ => 'Rotating spots is gentler on your skin. Tap any spot to choose it.',
  };

  // ------------------------------------------------------------------ pain

  void pickPain(int i) {
    Haptics.instance.selectionClick();
    pain.value = pain.value == i ? null : i;
  }

  // ---------------------------------------------------------- change dose

  Future<void> changeDose(BuildContext context) async {
    Haptics.instance.selectionClick();
    final med = medicine;
    final strengths = med?.strengths ?? const <double>[];
    if (strengths.isEmpty) {
      final v = await askNumber(
        context,
        title: 'Dose for this time',
        unit: 'mg',
        initial: strengthMg.value > 0 ? strengthMg.value : null,
        min: 0.05,
        max: 100,
        decimals: 2,
      );
      if (v != null && !v.isNaN) strengthMg.value = v;
      return;
    }
    final result = await showChangeDoseSheet(
      strengths: strengths,
      current: strengthMg.value,
      usual: profile?.strengthMg ?? 0,
      makeUsual: makeUsual.value,
      medicineName: medicineName,
    );
    if (result == null) return;
    if (result.switchMedicine) {
      await Get.toNamed<void>(Routes.editPlan);
      strengthMg.value = profile?.strengthMg ?? strengthMg.value;
      makeUsual.value = false;
      // Tablets have no injection spot or injection pain.
      if (isTablet) {
        site.value = '';
        pain.value = null;
      } else if (site.value.isEmpty) {
        site.value = tracker.nextSiteId;
      }
      return;
    }
    strengthMg.value = result.strength;
    makeUsual.value =
        result.makeUsual && result.strength != (profile?.strengthMg ?? 0);
  }

  // ------------------------------------------------------------ late dose

  /// Days after the planned day, for weekly and two-weekly plans. 0 when
  /// on time, daily, editing, or no plan yet.
  int get lateDays {
    final p = profile;
    if (p == null || isEditing || !(p.everyDays == 7 || p.everyDays == 14))
      return 0;
    final due = tracker.nextDoseAt(takenAt.value);
    if (due == null) return 0;
    final d = Dates.daysBetween(
      Dates.dateOnly(due),
      Dates.dateOnly(takenAt.value),
    );
    return d >= 2 ? d : 0;
  }

  String get usualDayName => Dates.weekdayName(profile?.shotWeekday ?? 1);
  String get todayDayName => Dates.weekdayName(takenAt.value.weekday);

  String get nextIfKeep => _fmtNext(tracker.nextDoseAfter(takenAt.value));
  String get nextIfCount => _fmtNext(
    tracker.nextDoseAfter(takenAt.value, weekday: takenAt.value.weekday),
  );

  String _fmtNext(DateTime? d) => d == null ? '' : Dates.shortWithDay(d);

  void pickKeepDay(bool keep) {
    Haptics.instance.selectionClick();
    keepDay.value = keep;
  }

  // ------------------------------------------------------------------ save

  /// A saved dose so close to this one that it may be a double log.
  DoseLog? get _closeDose {
    final p = profile;
    final at = takenAt.value;
    for (final d in tracker.doses) {
      if (d.id == editing.value?.id) continue;
      if (p == null || p.isDaily) {
        if (Dates.sameDay(d.takenAt, at)) return d;
      } else {
        final gap = d.takenAt.difference(at).abs();
        if (gap < Duration(hours: p.everyDays * 12)) return d;
      }
    }
    return null;
  }

  Future<void> save() async {
    if (saving.value) return;
    final close = _closeDose;
    if (close != null) {
      final choice = await showCloseDoseSheet(
        close,
        daily: profile?.isDaily ?? false,
      );
      if (choice == null) return;
      if (choice == CloseDoseChoice.editThat) {
        _startEditing(close);
        return;
      }
    }
    saving.value = true;
    try {
      final e = editing.value;
      if (e != null) {
        await tracker.updateDose(
          e.copyWith(
            takenAt: takenAt.value,
            strengthMg: strengthMg.value,
            site: isTablet ? '' : site.value,
            pain: () => isTablet ? null : pain.value,
            note: () => noteCtrl.text,
          ),
        );
        Haptics.instance.mediumImpact();
        popRoute();
        showToast('Dose updated');
        return;
      }

      final before = profile;
      final late = lateDays > 0 && !keepDay.value;
      final dose = await tracker.addDose(
        takenAt: takenAt.value,
        site: isTablet ? '' : site.value,
        pain: isTablet ? null : pain.value,
        note: noteCtrl.text,
        strengthMg: strengthMg.value,
      );
      if (before != null && (late || makeUsual.value)) {
        await tracker.saveProfile(
          before.copyWith(
            shotWeekday: late ? takenAt.value.weekday : null,
            strengthMg: makeUsual.value ? strengthMg.value : null,
          ),
        );
      }
      Haptics.instance.mediumImpact();
      unawaited(
        Get.offNamed<void>(
          Routes.doseDone,
          arguments: DoseDoneArgs(
            dose: dose,
            profileBefore: before != tracker.profile.value ? before : null,
          ),
        ),
      );
    } catch (_) {
      showToast("Couldn't save. Please try again.");
    } finally {
      saving.value = false;
    }
  }
}

enum SiteTag { suggested, usedLast, usedRecently, fresh }
