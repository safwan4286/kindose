import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/access_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';
import '../log_dose/log_dose_controller.dart' show logMissedDose;

/// History filter on the Doses tab.
enum DoseRange { month, quarter, all, custom }

/// Doses tab: next dose on top (the Today dose card), then every logged
/// dose to check, edit or delete.
class DosesController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();

  final Rx<DoseRange> range = DoseRange.quarter.obs;

  /// Days picked for "Custom" (date only, both included).
  final Rxn<DateTimeRange> custom = Rxn<DateTimeRange>();

  /// Rebuild hook for Obx.
  void watch() {
    tracker.doses.length;
    tracker.profile.value;
    range.value;
    custom.value;
  }

  bool get isTablet => tracker.profile.value?.form == 'tablet';
  bool get isDaily => tracker.profile.value?.isDaily ?? false;

  /// "MOUNJARO® · WEEKLY" above the title.
  String get eyebrow {
    final p = tracker.profile.value;
    if (p == null || p.medicineId == Catalog.undecided) return '';
    final name = Catalog.medicineName(p.medicineId, p.customMedicine);
    final mark = Catalog.medicine(p.medicineId).mark ?? '';
    final every = switch (p.everyDays) {
      1 => 'daily',
      7 => 'weekly',
      14 => 'every 2 weeks',
      _ => 'every ${p.everyDays} days',
    };
    return '$name$mark · $every';
  }

  String get title => isTablet ? 'Tablets' : 'Doses';

  // ---------------------------------------------------------------- range

  static String rangeLabel(DoseRange r) => switch (r) {
    DoseRange.month => '1 month',
    DoseRange.quarter => '3 months',
    DoseRange.all => 'All',
    DoseRange.custom => 'Custom',
  };

  Future<void> pickRange(DoseRange r) async {
    if (r != DoseRange.custom) {
      if (range.value == r) return;
      Haptics.instance.selectionClick();
      range.value = r;
      return;
    }
    final context = Get.context;
    if (context == null) return;
    final today = Dates.dateOnly(DateTime.now());
    final oldest = tracker.doses.isEmpty
        ? today
        : Dates.dateOnly(tracker.doses.last.takenAt);
    // At least a year back, further if doses go back further.
    final yearAgo = Dates.addDays(today, -365);
    final first = oldest.isBefore(yearAgo) ? oldest : yearAgo;
    // The picker asserts the starting range sits inside first…today.
    DateTime clamp(DateTime d) =>
        d.isBefore(first) ? first : (d.isAfter(today) ? today : d);
    final start = custom.value?.start ?? Dates.addDays(today, -30);
    final end = custom.value?.end ?? today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today,
      initialDateRange: DateTimeRange(start: clamp(start), end: clamp(end)),
      helpText: 'Show doses from',
    );
    if (picked == null) return;
    Haptics.instance.selectionClick();
    custom.value = DateTimeRange(
      start: Dates.dateOnly(picked.start),
      end: Dates.dateOnly(picked.end),
    );
    range.value = DoseRange.custom;
  }

  /// First day shown, or null for all.
  DateTime? get _from {
    final today = Dates.dateOnly(DateTime.now());
    return switch (range.value) {
      DoseRange.month => Dates.addDays(today, -30),
      DoseRange.quarter => Dates.addDays(today, -91),
      DoseRange.all => null,
      DoseRange.custom => custom.value?.start,
    };
  }

  /// Day after the last day shown, or null for up to now.
  DateTime? get _until {
    final end = range.value == DoseRange.custom ? custom.value?.end : null;
    return end == null ? null : Dates.addDays(end, 1);
  }

  /// Doses in the range, newest first.
  List<DoseLog> get shown {
    final from = _from;
    final until = _until;
    return [
      for (final d in tracker.doses)
        if ((from == null || !d.takenAt.isBefore(from)) &&
            (until == null || d.takenAt.isBefore(until)))
          d,
    ];
  }

  /// "4 doses", plus the dates for Custom.
  String get countLabel {
    final n = shown.length;
    final word = isTablet
        ? (n == 1 ? 'tablet' : 'tablets')
        : (n == 1 ? 'dose' : 'doses');
    final c = custom.value;
    if (range.value == DoseRange.custom && c != null) {
      return '$n $word · ${Dates.short(c.start)} – ${Dates.short(c.end)}';
    }
    return '$n $word';
  }

  /// Shown doses grouped by month: ("OCTOBER 2026", doses).
  List<(String, List<DoseLog>)> get groups {
    final out = <(String, List<DoseLog>)>[];
    for (final d in shown) {
      final label =
          '${Dates.months[d.takenAt.month - 1].toUpperCase()} ${d.takenAt.year}';
      if (out.isEmpty || out.last.$1 != label) {
        out.add((label, [d]));
      } else {
        out.last.$2.add(d);
      }
    }
    return out;
  }

  // ---------------------------------------------------------------- a dose

  int numberOf(DoseLog d) => tracker.doseNumberOf(d.id);

  /// "Dose 4 · 5 mg" (tablets: "5 mg").
  String titleOf(DoseLog d) {
    final mg = Catalog.mgLabel(d.strengthMg);
    return isTablet ? mg : 'Dose ${numberOf(d)} · $mg';
  }

  /// "8:12 AM · Lower left belly · Sore". Pain only when there was some.
  String lineOf(DoseLog d) {
    final pain = d.pain;
    return [
      Dates.time(d.takenAt),
      if (d.site.isNotEmpty) Catalog.siteName(d.site),
      if (pain != null && pain > 0 && pain < Catalog.painLabels.length)
        Catalog.painLabels[pain],
    ].join(' · ');
  }

  /// "On time", "2 days late", "1 day early", or null (first dose, daily
  /// plans: a chip on every tablet would just be noise).
  (String, bool)? statusOf(DoseLog d) {
    if (isDaily) return null;
    final i = tracker.doses.indexWhere((x) => x.id == d.id);
    if (i < 0 || i + 1 >= tracker.doses.length) return null;
    final prev = tracker.doses[i + 1].takenAt;
    if (tracker.onTimeAfter(prev, d.takenAt)) return ('On time', true);
    final due = tracker.nextDoseAfter(prev);
    if (due == null) return null;
    final off = Dates.daysBetween(due, d.takenAt);
    if (off == 0) return ('On time', true);
    final n = off.abs();
    final days = n == 1 ? '1 day' : '$n days';
    return (off > 0 ? '$days late' : '$days early', false);
  }

  String? noteOf(DoseLog d) {
    final n = d.note?.trim();
    return n == null || n.isEmpty ? null : n;
  }

  /// Medicine line for the detail sheet: "Mounjaro® 5 mg".
  String medicineOf(DoseLog d) {
    final p = tracker.profile.value;
    final name = Catalog.medicineName(d.medicineId, p?.customMedicine);
    final mark = Catalog.medicine(d.medicineId).mark ?? '';
    return '$name$mark ${Catalog.mgLabel(d.strengthMg)}';
  }

  String painOf(DoseLog d) {
    final pain = d.pain;
    if (pain == null || pain < 0 || pain >= Catalog.painLabels.length) {
      return 'Not noted';
    }
    return pain == 0 ? 'No pain' : Catalog.painLabels[pain];
  }

  // -------------------------------------------------------------- actions

  /// A dose that wasn't logged on the day: Log dose opens on picking the
  /// earlier date and time.
  void logPastDose() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.logDose, arguments: logMissedDose);
  }

  void edit(DoseLog d) {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.logDose, arguments: d);
  }

  /// Delete with Undo (same record back, Pens & cost counts it again).
  /// Returns false when nothing was deleted (paywall closed).
  Future<bool> delete(DoseLog d) async {
    if (!await AccessService.ensure()) return false;
    Haptics.instance.mediumImpact();
    final u = await tracker.removeDoseAndRestore(d.id);
    showUndoToast(
      isTablet ? 'Tablet removed' : 'Dose removed',
      () => tracker.restoreDose(d, u),
    );
    return true;
  }
}
