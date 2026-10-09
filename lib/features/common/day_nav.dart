import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/user_profile.dart';
import '../../resources/date_utils.dart';
import '../../services/haptics/haptics.dart';
import '../../services/tracker_service.dart';
import '../../widgets/k_date_picker.dart';

/// Moving between days on screens that show one day (Protein, Water, Day).
///
/// Every day back to the start of treatment can be browsed (soft paywall:
/// looking is free, changes ask for Plus). Future days are never shown.
mixin DayNav on GetxController {
  /// The day being shown (date only).
  final Rx<DateTime> day = Dates.dateOnly(DateTime.now()).obs;

  UserProfile? get _navProfile => Get.find<TrackerService>().profile.value;

  /// Called after the day changes (clear open rows, etc.).
  void onDayChanged() {}

  DateTime get today => Dates.dateOnly(DateTime.now());
  bool get isToday => Dates.sameDay(day.value, today);
  /// Oldest day that can be opened.
  DateTime get firstDay {
    final p = _navProfile;
    final start = p?.treatmentStartedAt ?? p?.startedAt ?? today;
    final earliest = Dates.dateOnly(start).subtract(const Duration(days: 30));
    final twoYears = today.subtract(const Duration(days: 730));
    return earliest.isBefore(twoYears) ? twoYears : earliest;
  }

  bool get canGoBack => day.value.isAfter(firstDay);
  bool get canGoForward => day.value.isBefore(today);

  /// "Today", "Yesterday" or "Mon, 28 Sep".
  String get dayTitle {
    if (isToday) return 'Today';
    if (Dates.sameDay(day.value, today.subtract(const Duration(days: 1))))
      return 'Yesterday';
    return Dates.shortWithDay(day.value);
  }

  /// Sets the day from a route argument (DateTime), clamped to what the
  /// user can see.
  void initDay(Object? arg) {
    if (arg is! DateTime) return;
    var d = Dates.dateOnly(arg);
    if (d.isAfter(today)) d = today;
    if (d.isBefore(firstDay)) d = firstDay;
    day.value = d;
  }

  void setDay(DateTime d) {
    final next = Dates.dateOnly(d);
    if (Dates.sameDay(next, day.value)) return;
    Haptics.instance.selectionClick();
    day.value = next;
    onDayChanged();
  }

  void previousDay() {
    final prev = day.value.subtract(const Duration(days: 1));
    if (prev.isBefore(firstDay)) return;
    setDay(prev);
  }

  void nextDay() {
    if (canGoForward) setDay(day.value.add(const Duration(days: 1)));
  }

  void backToToday() => setDay(today);

  Future<void> pickDay(BuildContext context) async {
    final picked = await showKDatePicker(
      context: context,
      initialDate: day.value,
      firstDate: firstDay,
      lastDate: today,
      marked: hasLogOn,
    );
    if (picked != null) setDay(picked);
  }

  /// Anything logged that day: dose, protein, water, check-in or weight.
  bool hasLogOn(DateTime d) {
    final t = Get.find<TrackerService>();
    final log = t.days[Dates.key(d)];
    if (log != null && (log.proteinG > 0 || log.waterMl > 0 || log.hasCheckIn))
      return true;
    if (t.doseOn(d) != null) return true;
    return t.weights.any((w) => Dates.sameDay(w.date, d));
  }
}
