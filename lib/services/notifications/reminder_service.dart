import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../features/home/home_controller.dart';
import '../plus/plus_access.dart';
import '../supply/supply_service.dart';
import '../tracker_service.dart';
import 'notification_service.dart';

/// Plans the dose reminders from the user's schedule and log.
///
/// It re-plans (cancel + schedule) whenever doses, the profile or a moved
/// dose change, so reminders are always about the *next* dose:
/// * Injections: "It's dose day" at the usual time, plus one evening
///   follow-up that disappears as soon as the dose is logged. If the dose
///   is overdue, one calm nudge the next morning (up to 3 days late).
/// * Daily tablets: the next 7 days at the usual time (today skipped once
///   taken). Refreshed on every app start and every log.
///
/// Texts never name the medicine, so nothing private shows on a lock
/// screen, and they never say what to take.
class ReminderService extends GetxService {
  final TrackerService tracker = Get.find<TrackerService>();
  final SupplyService supply = Get.find<SupplyService>();
  final NotificationService _notes = NotificationService.instance;

  static const int _doseId = 100;
  static const int _followUpId = 101;
  static const int _dailyFirstId = 110;
  static const int _dailyCount = 7;
  static const int _visitId = 120;
  static const int _refillId = 130;
  static const String logDosePayload = 'log_dose';
  static const String reportPayload = 'report';
  static const String pensPayload = 'pens';

  static List<int> get _allIds => [
    _doseId,
    _followUpId,
    _visitId,
    _refillId,
    for (var i = 0; i < _dailyCount; i++) _dailyFirstId + i,
  ];

  Timer? _debounce;
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    _notes.onOpen = _open;
    _worker = everAll([
      tracker.doses,
      tracker.profile,
      tracker.nextDoseOverride,
      tracker.nextAppointment,
      tracker.visitReminderOn,
      supply.packStartedAt,
      supply.usedOffset,
      supply.dosesPerPack,
      supply.spare,
      supply.refillReminder,
      PlusAccess.active,
    ], (_) => _queue());
    unawaited(_notes.init().then((_) => sync()));
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _worker?.dispose();
    _notes.onOpen = null;
    super.onClose();
  }

  void _queue() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), sync);
  }

  /// Opens Log dose if the app was started from a reminder. Call once the
  /// home screen is showing.
  void openLaunchPayload() {
    final p = _notes.takeLaunchPayload();
    if (p != null) _open(p);
  }

  void _open(String payload) {
    if (payload == pensPayload) {
      if (Get.currentRoute != Routes.pens) Get.toNamed<void>(Routes.pens);
      return;
    }
    if (payload == reportPayload) {
      if (Get.isRegistered<HomeController>())
        Get.find<HomeController>().select(HomeTab.report);
      return;
    }
    if (payload != logDosePayload || tracker.profile.value == null) return;
    if (Get.currentRoute == Routes.logDose) return;
    Get.toNamed<void>(Routes.logDose);
  }

  /// Cancels every reminder and schedules the current ones. Dose and visit
  /// reminders are switched on and off separately in Me.
  Future<void> sync() async {
    await _notes.cancelIds(_allIds);
    final p = tracker.profile.value;
    if (p == null) return;
    if (tracker.visitReminderOn.value) await _planVisit();
    await _planRefill();
    if (!p.remindersOn || p.medicineId == Catalog.undecided) return;
    if (p.isDaily) {
      await _planDaily(p);
    } else {
      await _planDose(p);
    }
  }

  Future<void> _planDose(UserProfile p) async {
    final now = DateTime.now();
    final next = tracker.nextDoseAt(now);
    if (next == null) return;
    final nextSite = Catalog.siteName(tracker.nextSiteId);
    final tablet = p.form == 'tablet';
    final spot = tablet ? '' : ' $nextSite is next.';

    if (next.isAfter(now)) {
      await _notes.scheduleAt(
        id: _doseId,
        when: next,
        title: "It's dose day",
        body: 'Tap to log it when you’re done.$spot',
        payload: logDosePayload,
      );
      // Evening follow-up on the same day, only if the usual time is
      // well before it. Replaced on the next sync once the dose is logged.
      final evening = DateTime(next.year, next.month, next.day, 20);
      if (evening.difference(next) >= const Duration(hours: 3)) {
        await _notes.scheduleAt(
          id: _followUpId,
          when: evening,
          title: 'Still to log: your dose',
          body:
              'Took it already? Tap to log it. Taking it another day? You can move it in the app.',
          payload: logDosePayload,
        );
      }
      return;
    }

    // Due earlier today and not logged yet: keep the evening follow-up.
    final evening = DateTime(now.year, now.month, now.day, 20);
    if (Dates.sameDay(next, now) && evening.isAfter(now)) {
      await _notes.scheduleAt(
        id: _followUpId,
        when: evening,
        title: 'Still to log: your dose',
        body:
            'Took it already? Tap to log it. Taking it another day? You can move it in the app.',
        payload: logDosePayload,
      );
      return;
    }

    // Overdue and not logged: one calm nudge the next morning, only while
    // it is at most 3 days late.
    final lateDays = Dates.daysBetween(next, now);
    if (lateDays > 3) return;
    final tomorrow = Dates.dateOnly(
      now,
    ).add(Duration(days: 1, minutes: p.shotMinutes));
    await _notes.scheduleAt(
      id: _followUpId,
      when: tomorrow,
      title: 'Did you take your dose?',
      body:
          'It was due ${Dates.weekdayName(next.weekday)}. Log it if you took it. '
          'If you missed it, check your medicine leaflet or ask your doctor.',
      payload: logDosePayload,
    );
  }

  /// 3 days before the next appointment, 9 AM: the report is ready.
  Future<void> _planVisit() async {
    final appt = tracker.nextAppointment.value;
    if (appt == null) return;
    final day = Dates.dateOnly(appt);
    final when = day
        .subtract(const Duration(days: 3))
        .add(const Duration(hours: 9));
    await _notes.scheduleAt(
      id: _visitId,
      when: when,
      title: 'Doctor visit on ${Dates.weekdayName(day.weekday)}',
      body:
          'Your one-page report is ready. Tap to check it and add any questions.',
      payload: reportPayload,
    );
  }

  /// Pens & cost (Plus): once the supply is down to its last dose (a
  /// week's worth for daily tablets), one reminder at 10 AM the day after
  /// the latest dose. Past times are skipped, so it shows once.
  Future<void> _planRefill() async {
    // Debug builds too, like the Pens screen, so it can be tested.
    final plus = PlusAccess.active.value || kDebugMode;
    if (!plus || !supply.refillReminder.value) return;
    if (!supply.runningLow) return;
    final last = tracker.lastDose?.takenAt ?? DateTime.now();
    final when = Dates.dateOnly(last).add(const Duration(days: 1, hours: 10));
    final left = supply.dosesLeft;
    await _notes.scheduleAt(
      id: _refillId,
      when: when,
      title: 'Time to plan a refill',
      body: left == 0
          ? 'Your supply at home looks empty. Tap to update it.'
          : 'You have $left ${left == 1 ? 'dose' : 'doses'} left at home.',
      payload: pensPayload,
    );
  }

  Future<void> _planDaily(UserProfile p) async {
    final now = DateTime.now();
    final takenToday = tracker.doseOn(now) != null;
    var scheduled = 0;
    for (var d = 0; scheduled < _dailyCount && d <= _dailyCount; d++) {
      final day = Dates.dateOnly(now).add(Duration(days: d));
      if (d == 0 && takenToday) continue;
      final when = day.add(Duration(minutes: p.shotMinutes));
      if (!when.isAfter(now)) continue;
      await _notes.scheduleAt(
        id: _dailyFirstId + scheduled,
        when: when,
        title: 'Time for today’s dose',
        body: 'Tap to mark it as taken.',
        payload: logDosePayload,
      );
      scheduled++;
    }
  }
}
