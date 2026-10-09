import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../features/home/home_controller.dart';
import '../plus/access_service.dart';
import '../plus/plus_access.dart';
import 'notif_prefs.dart';
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
  static const int _freeWeekId = 140;
  static const int _waterFirstId = 150;
  static const int _waterMax = 30;
  static const int _proteinFirstId = 180;
  static const int _proteinMax = 6;
  static const String logDosePayload = 'log_dose';
  static const String reportPayload = 'report';
  static const String pensPayload = 'pens';
  static const String plusPayload = 'plus';
  static const String waterPayload = 'water';
  static const String proteinPayload = 'protein';

  NotifPrefs get _prefs => Get.find<NotifPrefs>();

  static List<int> get _allIds => [
    _doseId,
    _followUpId,
    _visitId,
    _refillId,
    _freeWeekId,
    for (var i = 0; i < _waterMax; i++) _waterFirstId + i,
    for (var i = 0; i < _proteinMax; i++) _proteinFirstId + i,
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
      PlusAccess.freeWeek,
      tracker.days,
      _prefs.version,
      if (Get.isRegistered<AccessService>()) ...[
        Get.find<AccessService>().endsAt,
        Get.find<AccessService>().config,
      ],
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

  // ------------------------------------------------------------- debug

  static const int _testWaterId = 990;
  static const int _testProteinId = 991;

  /// Debug: a water and a protein reminder in 10 and 15 seconds, using
  /// the real scheduling path but ignoring windows and quiet hours.
  Future<void> debugTest() async {
    final now = DateTime.now();
    await _notes.scheduleAt(
      id: _testWaterId,
      when: now.add(const Duration(seconds: 10)),
      title: 'Time for some water',
      body: 'Test reminder. Tap to open Water.',
      payload: waterPayload,
    );
    await _notes.scheduleAt(
      id: _testProteinId,
      when: now.add(const Duration(seconds: 15)),
      title: 'Protein check',
      body: 'Test reminder. Tap to open Protein.',
      payload: proteinPayload,
    );
  }

  /// Debug: why water / protein may be quiet right now.
  List<String> debugReasons() {
    final p = tracker.profile.value;
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    return [
      if (p == null) 'No plan yet',
      if (!_prefs.waterOn.value) 'Water reminders are off in Notifications',
      if (!_prefs.proteinOn.value)
        'Protein reminders are off in Notifications',
      if (!_habitsOpen) 'Water and protein need Plus (free week is over)',
      if (_prefs.isQuiet(m)) 'Quiet hours right now',
      if (_prefs.waterOn.value &&
          (m < _prefs.waterStart.value || m > _prefs.waterEnd.value))
        'Outside the water window right now',
      if (p != null && tracker.today.waterMl >= p.waterGoalMl)
        'Water goal already met today (today is skipped)',
      if (p != null && tracker.today.proteinG >= p.proteinGoalG)
        'Protein goal already met today (today is skipped)',
    ];
  }

  void _open(String payload) {
    if (payload == waterPayload || payload == proteinPayload) {
      if (Get.currentRoute != Routes.addIntake) {
        Get.toNamed<void>(Routes.addIntake, arguments: payload);
      }
      return;
    }
    if (payload == plusPayload) {
      if (Get.currentRoute != Routes.plus) Get.toNamed<void>(Routes.plus);
      return;
    }
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
    if (_prefs.offersOn.value) await _planFreeWeek();
    await _planWater(p);
    await _planProtein(p);
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
      if (_prefs.followUpOn.value &&
          evening.difference(next) >= const Duration(hours: 3)) {
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
      if (!_prefs.followUpOn.value) return;
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
    if (!_prefs.missedOn.value) return;
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

  /// 1, 3 or 7 days (Notifications) before the next appointment, 9 AM:
  /// the report is ready.
  Future<void> _planVisit() async {
    final appt = tracker.nextAppointment.value;
    if (appt == null) return;
    final day = Dates.dateOnly(appt);
    final when = _prefs.outsideQuiet(
      day
          .subtract(Duration(days: _prefs.visitDays.value))
          .add(const Duration(hours: 9)),
    );
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
    final plus = PlusAccess.unlocked || kDebugMode;
    if (!plus || !supply.refillReminder.value) return;
    if (!supply.runningLow) return;
    final last = tracker.lastDose?.takenAt ?? DateTime.now();
    final when = _prefs.outsideQuiet(
      Dates.dateOnly(last).add(const Duration(days: 1, hours: 10)),
    );
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

  /// One heads-up at 10 AM the day before the free week ends, so the
  /// paywall is never a surprise. Only for people who allowed reminders,
  /// never once Plus is on. Past times are skipped by scheduleAt.
  Future<void> _planFreeWeek() async {
    if (!Get.isRegistered<AccessService>()) return;
    final a = Get.find<AccessService>();
    if (PlusAccess.active.value || !a.config.value.gatingOn || !a.started.value)
      return;
    final end = a.endsAt.value;
    final when = _prefs.outsideQuiet(
      Dates.dateOnly(end).subtract(const Duration(days: 1)).add(const Duration(hours: 10)),
    );
    if (!when.isBefore(end)) return;
    await _notes.scheduleAt(
      id: _freeWeekId,
      when: when,
      title: 'Your free week ends tomorrow',
      body:
          'Everything stays open until then, and your data is always safe. Tap to see Plus.',
      payload: plusPayload,
    );
  }

  /// Plus, or the end of the free week (null when reminders may run on).
  /// Habit reminders stop when the free week does.
  DateTime? get _freeUntil {
    if (PlusAccess.active.value || kDebugMode) return null;
    if (!Get.isRegistered<AccessService>()) return null;
    final a = Get.find<AccessService>();
    if (!a.config.value.gatingOn) return null;
    return a.endsAt.value;
  }

  bool get _habitsOpen => PlusAccess.unlocked || kDebugMode;

  static const List<String> _waterLines = [
    'A glass of water now helps with nausea and energy.',
    'Small sips count. Tap to add a glass.',
    'Water keeps things moving on your medicine. Tap to log it.',
    'Quick check: had some water lately?',
  ];

  /// Every 2 or 3 hours inside the chosen window, today and the next two
  /// days. Today is skipped once the water goal is met. Quiet hours win.
  Future<void> _planWater(UserProfile p) async {
    if (!_prefs.waterOn.value || !_habitsOpen) return;
    final now = DateTime.now();
    final until = _freeUntil;
    final goalMet = tracker.today.waterMl >= p.waterGoalMl;
    final step = Duration(hours: _prefs.waterEvery.value);
    final start = _prefs.waterStart.value;
    final end = _prefs.waterEnd.value;
    if (end <= start) return;
    var n = 0;
    for (var d = 0; d < 3 && n < _waterMax; d++) {
      if (d == 0 && goalMet) continue;
      final day = Dates.dateOnly(now).add(Duration(days: d));
      var when = day.add(Duration(minutes: start));
      final last = day.add(Duration(minutes: end));
      while (!when.isAfter(last) && n < _waterMax) {
        final m = when.hour * 60 + when.minute;
        final ok = when.isAfter(now) &&
            !_prefs.isQuiet(m) &&
            (until == null || when.isBefore(until));
        if (ok) {
          await _notes.scheduleAt(
            id: _waterFirstId + n,
            when: when,
            title: 'Time for some water',
            body: _waterLines[n % _waterLines.length],
            payload: waterPayload,
          );
          n++;
        }
        when = when.add(step);
      }
    }
  }

  /// 12:30 PM and 3:30 PM, today and the next two days. Today is skipped
  /// once the protein goal is met.
  Future<void> _planProtein(UserProfile p) async {
    if (!_prefs.proteinOn.value || !_habitsOpen) return;
    final now = DateTime.now();
    final until = _freeUntil;
    final goalMet = tracker.today.proteinG >= p.proteinGoalG;
    const times = [12 * 60 + 30, 15 * 60 + 30];
    var n = 0;
    for (var d = 0; d < 3 && n < _proteinMax; d++) {
      if (d == 0 && goalMet) continue;
      final day = Dates.dateOnly(now).add(Duration(days: d));
      for (final t in times) {
        final when = day.add(Duration(minutes: t));
        if (!when.isAfter(now) || _prefs.isQuiet(t)) continue;
        if (until != null && !when.isBefore(until)) continue;
        await _notes.scheduleAt(
          id: _proteinFirstId + n,
          when: when,
          title: t < 14 * 60 ? 'Protein with lunch?' : 'Protein check',
          body: t < 14 * 60
              ? 'Protein first helps protect muscle. Tap to log your lunch.'
              : 'A protein snack keeps you on track for today. Tap to log it.',
          payload: proteinPayload,
        );
        n++;
      }
    }
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
