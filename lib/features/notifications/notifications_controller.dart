import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/notifications/notif_prefs.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/plus/plus_access.dart';
import '../../services/supply/supply_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<NotificationsController>(NotificationsController.new);
}

/// Me → Notifications: one switch per reminder. Saving re-plans reminders
/// on its own (ReminderService watches every value used here).
class NotificationsController extends GetxController
    with WidgetsBindingObserver {
  final TrackerService tracker = Get.find<TrackerService>();
  final SupplyService supply = Get.find<SupplyService>();
  final NotifPrefs prefs = Get.find<NotifPrefs>();

  /// False when the phone blocks Kindose notifications (null = unknown).
  final RxnBool systemOn = RxnBool();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkSystem();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Back from phone settings: check again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkSystem();
  }

  Future<void> _checkSystem() async {
    systemOn.value = await NotificationService.instance.areEnabled();
  }

  /// Rebuild hook for Obx.
  void watch() {
    tracker.profile.value;
    tracker.visitReminderOn.value;
    supply.refillReminder.value;
    PlusAccess.active.value;
    PlusAccess.freeWeek.value;
    prefs.version.value;
    systemOn.value;
  }

  bool get unlocked => PlusAccess.unlocked;
  bool get isPlus => PlusAccess.active.value;
  bool get blocked => systemOn.value == false;

  // ------------------------------------------------------------ treatment

  bool get hasPlan => tracker.profile.value != null;
  bool get isDaily => tracker.profile.value?.isDaily ?? false;
  bool get doseOn => tracker.profile.value?.remindersOn ?? false;
  int get doseMinutes => tracker.profile.value?.shotMinutes ?? 9 * 60;
  String get doseTime => Dates.timeOfDay(doseMinutes);

  String get doseSub => isDaily
      ? 'Every day at $doseTime'
      : 'On dose day at $doseTime';

  Future<void> setDose(bool on) async {
    final p = tracker.profile.value;
    if (p == null) return;
    if (on && !await _allow()) return;
    Haptics.instance.selectionClick();
    await tracker.saveProfile(p.copyWith(remindersOn: on));
  }

  Future<void> pickDoseTime(BuildContext context) async {
    final p = tracker.profile.value;
    if (p == null) return;
    Haptics.instance.selectionClick();
    final m = await _pickTime(context, doseMinutes, 'Dose reminder');
    if (m == null || m == p.shotMinutes) return;
    await tracker.saveProfile(p.copyWith(shotMinutes: m));
  }

  Future<void> setFollowUp(bool on) => _setPref(prefs.followUpOn, on);
  Future<void> setMissed(bool on) => _setPref(prefs.missedOn, on);

  // --------------------------------------------------------- daily habits

  Future<void> setWater(bool on) => _setPlusPref(prefs.waterOn, on);
  Future<void> setProtein(bool on) => _setPlusPref(prefs.proteinOn, on);

  Future<void> setWaterEvery(int hours) async {
    if (prefs.waterEvery.value == hours) return;
    Haptics.instance.selectionClick();
    prefs.waterEvery.value = hours;
    await prefs.save();
  }

  String get waterWindow =>
      '${Dates.timeOfDay(prefs.waterStart.value)} – ${Dates.timeOfDay(prefs.waterEnd.value)}';

  Future<void> pickWaterStart(BuildContext context) async {
    final m = await _pickTime(context, prefs.waterStart.value, 'First reminder');
    if (m == null) return;
    if (m >= prefs.waterEnd.value) {
      showToast('Pick a time before ${Dates.timeOfDay(prefs.waterEnd.value)}.');
      return;
    }
    prefs.waterStart.value = m;
    await prefs.save();
  }

  Future<void> pickWaterEnd(BuildContext context) async {
    final m = await _pickTime(context, prefs.waterEnd.value, 'Last reminder');
    if (m == null) return;
    if (m <= prefs.waterStart.value) {
      showToast('Pick a time after ${Dates.timeOfDay(prefs.waterStart.value)}.');
      return;
    }
    prefs.waterEnd.value = m;
    await prefs.save();
  }

  // ---------------------------------------------------- visits & supplies

  bool get visitOn => tracker.visitReminderOn.value;
  bool get refillOn => unlocked && supply.refillReminder.value;

  String get visitSub => switch (prefs.visitDays.value) {
    1 => 'The day before, to get your report ready',
    7 => 'A week before, to get your report ready',
    _ => '3 days before, to get your report ready',
  };

  Future<void> setVisit(bool on) async {
    if (on && !await _allow()) return;
    Haptics.instance.selectionClick();
    await tracker.setVisitReminderOn(on);
  }

  Future<void> setVisitDays(int days) async {
    if (prefs.visitDays.value == days) return;
    Haptics.instance.selectionClick();
    prefs.visitDays.value = days;
    await prefs.save();
  }

  Future<void> setRefill(bool on) async {
    if (on && !unlocked) return _openPlus();
    if (on && !await _allow()) return;
    Haptics.instance.selectionClick();
    await supply.setRefillReminder(on);
  }

  // -------------------------------------------------------------- kindose

  Future<void> setOffers(bool on) => _setPref(prefs.offersOn, on);

  // ---------------------------------------------------------- quiet hours

  Future<void> setQuiet(bool on) async {
    Haptics.instance.selectionClick();
    prefs.quietOn.value = on;
    await prefs.save();
  }

  String get quietWindow =>
      '${Dates.timeOfDay(prefs.quietStart.value)} – ${Dates.timeOfDay(prefs.quietEnd.value)}';

  Future<void> pickQuietStart(BuildContext context) async {
    final m = await _pickTime(context, prefs.quietStart.value, 'Quiet from');
    if (m == null || m == prefs.quietEnd.value) return;
    prefs.quietStart.value = m;
    await prefs.save();
  }

  Future<void> pickQuietEnd(BuildContext context) async {
    final m = await _pickTime(context, prefs.quietEnd.value, 'Quiet until');
    if (m == null || m == prefs.quietStart.value) return;
    prefs.quietEnd.value = m;
    await prefs.save();
  }

  // ----------------------------------------------------- phone permission

  /// iOS opens Kindose in Settings. Android asks again (shows the system
  /// prompt unless it was blocked for good).
  Future<void> openSystemSettings() async {
    Haptics.instance.lightImpact();
    if (Platform.isIOS) {
      try {
        if (await launchUrl(Uri.parse('app-settings:'))) return;
      } catch (_) {}
    } else {
      if (await NotificationService.instance.requestPermission()) {
        await _checkSystem();
        return;
      }
    }
    showToast('Open Settings › Apps › Kindose › Notifications and turn them on.');
  }

  // -------------------------------------------------------------- helpers

  Future<void> _setPref(RxBool field, bool on) async {
    if (on && !await _allow()) return;
    Haptics.instance.selectionClick();
    field.value = on;
    await prefs.save();
  }

  Future<void> _setPlusPref(RxBool field, bool on) async {
    if (on && !unlocked) return _openPlus();
    await _setPref(field, on);
  }

  void _openPlus() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.plus);
  }

  Future<bool> _allow() async {
    final granted = await NotificationService.instance.requestPermission();
    await _checkSystem();
    if (!granted) {
      showToast('Allow notifications for Kindose in your phone settings.');
    }
    return granted;
  }

  Future<int?> _pickTime(BuildContext context, int minutes, String help) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: help,
    );
    if (t == null) return null;
    Haptics.instance.selectionClick();
    return t.hour * 60 + t.minute;
  }
}
