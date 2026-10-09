import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../resources/app_links.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../resources/water_units.dart';
import '../../services/backend/backend_service.dart';
import '../../services/haptics/haptics.dart';
import '../../services/notifications/notif_prefs.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/notifications/reminder_service.dart';
import '../../services/plus/access_service.dart';
import '../../services/plus/plus_access.dart';
import '../../services/purchases/purchase_service.dart';
import '../../services/review/review_service.dart';
import '../../services/supply/supply_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/mood_row.dart';
import '../../widgets/no_internet_sheet.dart';
import '../../widgets/toast.dart';
import '../legal/legal_sheet.dart';
import 'widgets/me_sheets.dart';

/// Me tab: plan, goals, reminders, units and theme, backup, export,
/// delete and legal. Everything is read from [TrackerService], so edits
/// made elsewhere (e.g. Edit plan) show up here at once.
class MeController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final RxBool exporting = false.obs;
  final RxString version = ''.obs;

  static const double _lbPerKg = 2.20462;

  @override
  void onInit() {
    super.onInit();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version.value = info.version;
    } catch (_) {
      // Version is only shown in the footer; leave it empty.
    }
  }

  /// Reads every value the screen shows, so one `Obx` rebuilds on change.
  void watch() {
    tracker.profile.value;
    tracker.themeMode.value;
    tracker.visitReminderOn.value;
    tracker.doses.length;
    tracker.nextDoseOverride.value;
    PlusAccess.active.value;
    PlusAccess.freeWeek.value;
    access.endsAt.value;
    access.started.value;
    _purchases?.info.value;
    supply.packStartedAt.value;
    supply.usedOffset.value;
    supply.spare.value;
    supply.dosesPerPack.value;
    exporting.value;
    version.value;
    backend.user.value;
    backend.lastBackupAt.value;
    backend.busy.value;
    backend.pending.value;
  }

  bool get isPlus => PlusAccess.active.value;

  // ------------------------------------------------------------ plan card

  AccessService get access => Get.find<AccessService>();

  PurchaseService? get _purchases =>
      Get.isRegistered<PurchaseService>() ? Get.find<PurchaseService>() : null;

  /// "Yearly · Renews Oct 1, 2027" from the store, when known.
  String get _plusLine {
    final e = _purchases?.plus;
    if (e == null) return 'Thank you for supporting Kindose';
    final kind = e.productIdentifier.contains('month') ? 'Monthly' : 'Yearly';
    final exp = DateTime.tryParse(e.expirationDate ?? '')?.toLocal();
    if (exp == null) return kind;
    return '$kind · ${e.willRenew ? 'Renews' : 'Ends'} ${Dates.short(exp)}';
  }

  /// 'plus', 'free' (week running or not started) or 'ended'.
  String get planState => isPlus ? 'plus' : (access.locked ? 'ended' : 'free');

  String get planTitle => switch (planState) {
    'plus' => 'Kindose Plus is on',
    'ended' => 'Free week ended',
    _ =>
      access.started.value
          ? 'Free until ${Dates.shortWithDay(access.endsAt.value)}'
          : 'Your free week',
  };

  String get planSub {
    switch (planState) {
      case 'plus':
        return _plusLine;
      case 'ended':
        return 'Your data is safe. Get Plus to keep logging.';
    }
    if (!access.started.value) return 'Starts with your first dose';
    final d = access.daysLeft;
    return '$d ${d == 1 ? 'day' : 'days'} left · everything is open';
  }

  String get planButton => switch (planState) {
    'plus' => 'Manage',
    'ended' => 'Get Plus',
    _ => 'See plans',
  };

  // Debug builds only: try the free week states without waiting.
  Future<void> debugRestartWeek() => access.debugRestart();
  Future<void> debugEndWeek() => access.debugEnd();
  Future<void> debugRealDates() => access.debugClear();

  /// Debug: water + protein test reminders in 10 / 15 seconds.
  Future<void> debugTestReminders() async {
    Haptics.instance.selectionClick();
    final ok = await NotificationService.instance.requestPermission();
    if (!ok) {
      showToast('Notifications are off for Kindose in phone settings.');
      return;
    }
    await Get.find<ReminderService>().debugTest();
    showToast('Water in 10 s, protein in 15 s. You can leave the app.');
  }

  /// Debug: every reminder the phone is holding, with its time.
  Future<void> debugShowPlanned() async {
    Haptics.instance.selectionClick();
    final notes = NotificationService.instance;
    final ids = await notes.pendingIds();
    final rows = [
      for (final e in notes.plannedLog.entries)
        if (ids.contains(e.key)) (e.key, e.value.$1, e.value.$2),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final enabled = await notes.areEnabled();
    await showPlannedSheet(
      enabled: enabled,
      pendingCount: ids.length,
      rows: [
        for (final r in rows)
          '${Dates.shortWithDay(r.$2)} ${Dates.time(r.$2)} · ${r.$3} (#${r.$1})',
      ],
      reasons: Get.find<ReminderService>().debugReasons(),
    );
  }

  /// Act as a paying Plus user (debug builds only).
  Future<void> debugTogglePlus() async {
    Haptics.instance.selectionClick();
    await PlusAccess.setDebugPlus(!PlusAccess.debugPlus.value);
    showToast(
      PlusAccess.debugPlus.value ? 'Debug: Plus is on' : 'Debug: Plus is off',
    );
  }
  bool get useKg => tracker.profile.value?.useKg ?? true;
  ThemeMode get themeMode => tracker.themeMode.value;

  // ------------------------------------------------------------------ plan

  bool get hasMedicine {
    final p = tracker.profile.value;
    return p != null && p.medicineId != Catalog.undecided;
  }

  /// "YOUR PLAN · WEEK 16"
  String get planCaption {
    final p = tracker.profile.value;
    final start =
        p?.treatmentStartedAt ??
        (tracker.doses.isEmpty ? null : tracker.doses.last.takenAt);
    final now = DateTime.now();
    if (start == null || start.isAfter(now)) return 'YOUR PLAN';
    return 'YOUR PLAN · WEEK ${Dates.daysBetween(start, now) ~/ 7 + 1}';
  }

  // String get planTitle {
  //   final p = tracker.profile.value;
  //   if (p == null || !hasMedicine) return 'Add your medicine';
  //   final dose = p.strengthMg > 0 ? ' ${Catalog.mgLabel(p.strengthMg)}' : '';
  //   return '${Catalog.medicineName(p.medicineId, p.customMedicine)}$dose';
  // }
  //
  // String get planSub {
  //   final p = tracker.profile.value;
  //   if (p == null || !hasMedicine)
  //     return 'So we can remind you and track your doses.';
  //   final time = Dates.timeOfDay(p.shotMinutes);
  //   final day = Dates.weekdayName(p.shotWeekday);
  //   final when = switch (p.everyDays) {
  //     1 => 'Every day at $time',
  //     7 => '${day}s at $time',
  //     14 => 'Every other $day at $time',
  //     _ => 'Every ${p.everyDays} days at $time',
  //   };
  //   return '${Catalog.formLabel(p.form)} · $when';
  // }

  String get formLabel {
    final p = tracker.profile.value;
    return p == null ? '' : Catalog.formLabel(p.form);
  }

  /// "Injection" or "By mouth", under the form.
  String get formSub => isTablet ? 'By mouth' : 'Injection';

  /// "Tuesdays", "Daily", "Every 2nd Tue", "Every 10 days".
  String get scheduleDay {
    final p = tracker.profile.value;
    if (p == null) return '—';
    return switch (p.everyDays) {
      1 => 'Daily',
      7 => '${Dates.weekdayShort(p.shotWeekday)}s',
      14 => 'Every 2nd ${Dates.weekdayShort(p.shotWeekday)}',
      _ => 'Every ${p.everyDays} days',
    };
  }

  String get scheduleTime =>
      Dates.timeOfDay(tracker.profile.value?.shotMinutes ?? 480);

  DateTime? get _next =>
      hasMedicine ? tracker.nextDoseAt(DateTime.now()) : null;

  /// "Tue, 6 Oct", or "Overdue".
  String get nextShort {
    final next = _next;
    if (next == null) return '—';
    final today = Dates.dateOnly(DateTime.now());
    if (Dates.dateOnly(next).isBefore(today)) return 'Overdue';
    return Dates.shortWithDay(next);
  }

  /// "today", "tomorrow", "in 6 days", or "log it when taken".
  String get nextSub {
    final next = _next;
    if (next == null) return '';
    final days = Dates.daysBetween(
      Dates.dateOnly(DateTime.now()),
      Dates.dateOnly(next),
    );
    if (days < 0) return 'Log it when taken';
    return switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => 'In $days days',
    };
  }

  bool get isTablet => tracker.profile.value?.form == 'tablet';

  String get nextDoseLine {
    if (!hasMedicine) return '';
    final now = DateTime.now();
    final next = tracker.nextDoseAt(now);
    if (next == null) return '';
    if (Dates.dateOnly(next).isBefore(Dates.dateOnly(now)))
      return 'Dose was due ${Dates.shortWithDay(next)}';
    final day = Dates.relativeDay(next, now);
    return 'Next dose ${day == 'Today' || day == 'Tomorrow' ? day.toLowerCase() : day}';
  }

  void editPlan() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.editPlan);
  }

  /// Paywall, or for Plus users the store's subscription page (change
  /// plan, cancel). RevenueCat's Customer Center needs a paid RevenueCat
  /// plan, so the store page is used instead.
  Future<void> openPlus() async {
    Haptics.instance.selectionClick();
    if (!isPlus) {
      await Get.toNamed<void>(Routes.plus);
      return;
    }
    final url = _purchases?.managementUrl;
    if (url != null) {
      try {
        if (await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ))
          return;
      } catch (_) {}
    }
    showToast('Manage Plus in your App Store or Google Play subscriptions.');
  }

  // ------------------------------------------------------------- treatment

  SupplyService get supply => Get.find<SupplyService>();

  /// "Pens & cost" / "Vials & cost" / "Tablets & cost".
  String get pensLabel => switch (tracker.profile.value?.form) {
    'vial' => 'Vials & cost',
    'tablet' => 'Tablets & cost',
    _ => 'Pens & cost',
  };

  /// "3 doses left" once set up.
  String? get pensValue {
    if (!supply.isSetUp) return null;
    final n = supply.dosesLeft;
    final word = isTablet ? 'tablet' : 'dose';
    return '$n ${n == 1 ? word : '${word}s'} left';
  }

  void openPens() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.pens);
  }

  void openGuide() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.guide);
  }

  // ----------------------------------------------------------------- goals

  String get goalWeightLabel {
    final g = tracker.profile.value?.goalWeightKg;
    if (g == null) return 'Not set';
    return useKg
        ? '${g.toStringAsFixed(1)} kg'
        : '${(g * _lbPerKg).round()} lb';
  }

  String get proteinLabel =>
      '${tracker.profile.value?.proteinGoalG ?? 0} g a day';

  String get waterLabel {
    final ml = tracker.profile.value?.waterGoalMl ?? 0;
    return '${Water.totalWithUnit(ml)} a day';
  }

  static const Map<String, String> dietNames = {
    'nonveg': 'Everything',
    'pesc': 'Pescatarian',
    'veg': 'Vegetarian',
    'vegan': 'Vegan',
    // Older saved values.
    'egg': 'Vegetarian',
    'jain': 'Vegetarian',
  };

  String get dietLabel => dietNames[tracker.profile.value?.diet] ?? 'Not set';

  Future<void> editGoalWeight(BuildContext context) async {
    final p = tracker.profile.value;
    if (p == null) return;
    final kg = p.useKg;
    final current = p.goalWeightKg;
    final v = await askNumber(
      context,
      title: 'Goal weight',
      unit: kg ? 'kg' : 'lb',
      initial: current == null
          ? null
          : (kg ? current : (current * _lbPerKg).roundToDouble()),
      min: kg ? 35 : 77,
      max: kg ? 300 : 660,
      allowClear: true,
    );
    if (v == null) return;
    if (v.isNaN) {
      await tracker.saveProfile(p.copyWith(clearGoalWeight: true));
      return;
    }
    await tracker.saveProfile(p.copyWith(goalWeightKg: kg ? v : v / _lbPerKg));
  }

  Future<void> editProteinGoal(BuildContext context) async {
    final p = tracker.profile.value;
    if (p == null) return;
    final v = await askNumber(
      context,
      title: 'Daily protein goal',
      unit: 'g',
      initial: p.proteinGoalG.toDouble(),
      min: 30,
      max: 250,
      decimals: 0,
    );
    if (v == null || v.isNaN) return;
    await tracker.saveProfile(p.copyWith(proteinGoalG: v.round()));
  }

  Future<void> editWaterGoal(BuildContext context) async {
    final p = tracker.profile.value;
    if (p == null) return;
    final oz = p.useOz;
    final v = await askNumber(
      context,
      title: 'Daily water goal',
      unit: oz ? 'fl oz' : 'L',
      initial: oz
          ? Water.toOz(p.waterGoalMl).roundToDouble()
          : p.waterGoalMl / 1000,
      min: oz ? 34 : 1,
      max: oz ? 203 : 6,
      decimals: oz ? 0 : 1,
    );
    if (v == null || v.isNaN) return;
    final ml = oz ? Water.fromOz(v) : (v * 1000).round();
    await tracker.saveProfile(p.copyWith(waterGoalMl: ml));
  }

  Future<void> editDiet() async {
    final p = tracker.profile.value;
    if (p == null) return;
    Haptics.instance.selectionClick();
    final picked = await showDietSheet(p.diet);
    if (picked == null || picked == p.diet) return;
    await tracker.saveProfile(
      p.copyWith(diet: picked, vegDiet: Catalog.isMeatFree(picked)),
    );
  }

  // ------------------------------------------------------------- reminders

  bool get doseReminders => tracker.profile.value?.remindersOn ?? false;
  bool get visitReminders => tracker.visitReminderOn.value;

  NotifPrefs get _notifPrefs => Get.find<NotifPrefs>();

  /// "4 on · Quiet 10:00 PM – 7:00 AM" under the Notifications row.
  String get notificationsSummary {
    final n = _notifPrefs;
    n.version.value;
    final unlocked = PlusAccess.unlocked;
    final on = [
      doseReminders,
      visitReminders,
      unlocked && n.waterOn.value,
      unlocked && n.proteinOn.value,
      unlocked && supply.refillReminder.value,
    ].where((v) => v).length;
    final count = on == 0 ? 'All off' : '$on on';
    if (!n.quietOn.value) return count;
    return '$count · Quiet ${Dates.timeOfDay(n.quietStart.value)} – ${Dates.timeOfDay(n.quietEnd.value)}';
  }

  void openNotifications() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.notifications);
  }

  // ------------------------------------------------------------ units/theme

  Future<void> setUseKg(bool v) async {
    final p = tracker.profile.value;
    if (p == null || p.useKg == v) return;
    await tracker.saveProfile(p.copyWith(useKg: v));
  }

  bool get useOz => tracker.profile.value?.useOz ?? false;

  Future<void> setUseOz(bool v) async {
    final p = tracker.profile.value;
    if (p == null || p.useOz == v) return;
    await tracker.saveProfile(p.copyWith(useOz: v));
  }

  Future<void> setTheme(ThemeMode mode) => tracker.setThemeMode(mode);

  // ---------------------------------------------------------------- backup

  /// Cloud backup needs sign-in (Firebase), which is not built yet. Until
  /// then this offers a backup file the user can keep.
  // ---------------------------------------------------------------- backup

  BackendService get backend => Get.find<BackendService>();

  bool get signedIn => backend.signedIn;

  /// Changes on the phone that aren't in the account yet.
  bool get syncWaiting => backend.pending.value;
  String get accountEmail => backend.email ?? 'your account';

  /// "Signed in with Google" / "Signed in with Apple".
  String get accountVia => switch (backend.provider) {
    'apple' => 'Signed in with Apple',
    'google' => 'Signed in with Google',
    _ => 'Signed in',
  };

  /// First letter for the account circle.
  String get accountInitial {
    final e = backend.email;
    return e == null || e.isEmpty ? '?' : e[0].toUpperCase();
  }

  /// "Backed up today, 9:41 PM" / "Not backed up yet".
  String get backupLine {
    if (backend.busy.value) return 'Syncing…';
    if (backend.pending.value) return 'Changes waiting to sync';
    final at = backend.lastBackupAt.value;
    if (at == null) return 'Not synced yet';
    final mins = DateTime.now().difference(at).inMinutes;
    if (mins < 2) return 'All synced · just now';
    final day = Dates.relativeDay(at, DateTime.now());
    return 'All synced · ${day == 'Today' || day == 'Tomorrow' ? day.toLowerCase() : day}, ${Dates.time(at)}';
  }

  /// Signed out: sign in with Google, then back up (or restore a backup
  /// found in the cloud).
  Future<void> backup() async {
    Haptics.instance.selectionClick();
    if (!backend.ready) {
      _explain(BackendResult.notReady);
      return;
    }
    if (signedIn) {
      await backupNow();
      return;
    }
    backend.autoPaused = true;
    try {
      final r = await backend.signInWithGoogle();
      if (r != BackendResult.ok) {
        _explain(r);
        return;
      }
      final check = await backend.checkBackup();
      if (!check.ok) {
        // Never guess "no backup": that could overwrite a real one.
        await backend.signOut();
        await showNoInternetSheet(what: 'Checking your backup');
        return;
      }
      final cloud = check.backup;
      if (cloud != null) {
        final restore = await showWelcomeBackSheet(
          backup: cloud,
          otherLabel: "Keep this phone's data",
          otherNote:
              "This phone's data replaces what is saved in your account.",
        );
        if (restore == null) {
          // Closed without choosing: nothing changes.
          await backend.signOut();
          return;
        }
        if (restore == true) {
          final rr = await backend.restore(cloud);
          if (rr == BackendResult.ok) {
            showToast('Backup restored');
          } else {
            _explain(rr);
          }
          return;
        }
      }
      // No backup yet, or "Keep this phone": the phone's data is theirs.
      await backend.claimLocal();
    } finally {
      backend.autoPaused = false;
    }
    await backupNow();
  }

  Future<void> backupNow() async {
    final r = await backend.backupNow();
    if (r == BackendResult.ok) {
      Haptics.instance.mediumImpact();
      showToast('All synced');
    } else {
      _explain(r);
    }
  }

  Future<void> restoreBackup() async {
    Haptics.instance.selectionClick();
    final check = await backend.checkBackup();
    if (!check.ok) {
      await showNoInternetSheet(what: 'Restoring');
      return;
    }
    final cloud = check.backup;
    if (cloud == null) {
      showToast('No backup found for this account yet.');
      return;
    }
    final ok = await showRestoreSheet(
      when: _when(cloud.updatedAt),
      phoneHasData: true,
    );
    if (ok != true) return;
    final r = await backend.restore(cloud);
    if (r == BackendResult.ok) {
      showToast('Backup restored');
    } else {
      _explain(r);
    }
  }

  /// Last backup, then sign out and clear the phone (their data waits in
  /// the cloud). Warns first when the latest changes couldn't upload.
  Future<void> signOut() async {
    Haptics.instance.selectionClick();
    final email = accountEmail;
    final synced = await backend.flushBeforeSignOut();
    final ok = await showSignOutSheet(synced: synced, email: email);
    if (ok != true) return;
    Haptics.instance.mediumImpact();
    await backend.signOutAndClear();
    Get.offAllNamed<void>(Routes.welcome);
    showToast('Signed out. Sign in again to get your data back.');
  }

  Future<void> deleteAccount() async {
    Haptics.instance.mediumImpact();
    final ok = await showDeleteAccountSheet();
    if (ok != true) return;
    final r = await backend.deleteAccount();
    if (r == BackendResult.ok) {
      Haptics.instance.heavyImpact();
      Get.offAllNamed<void>(Routes.welcome);
      showToast('Account deleted.');
    } else {
      _explain(r);
    }
  }

  String _when(DateTime at) {
    final day = Dates.relativeDay(at, DateTime.now());
    return '${day == 'Today' || day == 'Tomorrow' ? day.toLowerCase() : day} at ${Dates.time(at)}';
  }

  void _explain(BackendResult r) {
    switch (r) {
      case BackendResult.ok:
      case BackendResult.cancelled:
        return;
      case BackendResult.offline:
        showNoInternetSheet();
      case BackendResult.notReady:
        showToast('Sign-in is being set up. Your data is safe on this phone.');
      case BackendResult.failed:
        showToast('Something went wrong. Please try again.');
    }
  }

  // ---------------------------------------------------------------- export

  /// Spreadsheet files (CSV) through the share sheet. Cloud sync is the
  /// backup, so there is no separate backup file.
  Future<void> export() async {
    if (exporting.value) return;
    Haptics.instance.selectionClick();
    await exportCsv();
  }

  Future<void> exportCsv() async {
    String esc(Object? v) {
      final s = v?.toString() ?? '';
      return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final doses = StringBuffer(
      'date,time,medicine,strength_mg,site,how_it_felt,note\n',
    );
    for (final d in tracker.doses.reversed) {
      doses.writeln(
        [
          Dates.key(d.takenAt),
          Dates.time(d.takenAt),
          Catalog.medicineName(
            d.medicineId,
            tracker.profile.value?.customMedicine,
          ),
          d.strengthMg,
          d.site.isEmpty ? '' : Catalog.siteName(d.site),
          d.pain == null ? '' : Catalog.painLabels[d.pain!],
          d.note,
        ].map(esc).join(','),
      );
    }

    final days = StringBuffer(
      'date,protein_g,water_ml,water_fl_oz,mood,symptoms,nausea,food_noise,appetite,note\n',
    );
    final sorted = tracker.days.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final d in sorted) {
      days.writeln(
        [
          d.key,
          d.proteinG,
          d.waterMl,
          Water.toOz(d.waterMl).round(),
          d.mood == null ? '' : Catalog.moods[d.mood!.clamp(0, 4)].label,
          d.symptoms
              .map(
                (s) => s == 'nausea'
                    ? 'Nausea'
                    : '${Catalog.symptoms[s] ?? s} (${Catalog.levelWords[d.levelOf(s)]})',
              )
              .join('; '),
          d.nausea == -1
              ? 'none'
              : _level(d.nausea, const ['mild', 'moderate', 'severe']),
          _level(d.foodNoise, const ['quiet', 'some', 'loud']),
          _level(d.appetite, const ['low', 'normal', 'high']),
          d.note,
        ].map(esc).join(','),
      );
    }

    final weights = StringBuffer('date,weight_kg,weight_lb\n');
    for (final w in tracker.weights) {
      weights.writeln(
        '${w.key},${w.kg.toStringAsFixed(2)},${(w.kg * _lbPerKg).toStringAsFixed(1)}',
      );
    }

    // Every protein and water entry with its time and food name.
    final log = StringBuffer('date,time,type,item,amount,unit\n');
    for (final d in sorted) {
      final entries = d.entries.toList()..sort((a, b) => a.at.compareTo(b.at));
      for (final e in entries) {
        log.writeln(
          [
            d.key,
            Dates.time(e.at),
            e.isProtein ? 'protein' : 'water',
            e.label ?? '',
            e.amount,
            e.isProtein ? 'g' : 'ml',
          ].map(esc).join(','),
        );
      }
    }

    final myFoods = StringBuffer('name,portion,protein_g\n');
    for (final f in tracker.myFoods) {
      myFoods.writeln([f.name, f.portion, f.grams].map(esc).join(','));
    }

    final purchases = StringBuffer(
      'date,count,strength_mg,price,currency,note\n',
    );
    for (final p in supply.purchases.reversed) {
      purchases.writeln(
        [
          Dates.key(p.date),
          p.packs,
          p.strengthMg ?? '',
          p.price.toStringAsFixed(2),
          supply.currency.value,
          p.note,
        ].map(esc).join(','),
      );
    }

    await _share({
      'kindose-doses.csv': doses.toString(),
      'kindose-days.csv': days.toString(),
      'kindose-weights.csv': weights.toString(),
      'kindose-food-and-water.csv': log.toString(),
      'kindose-plan.csv': _planCsv(esc),
      if (tracker.myFoods.isNotEmpty) 'kindose-my-foods.csv': myFoods.toString(),
      if (supply.purchases.isNotEmpty)
        'kindose-purchases.csv': purchases.toString(),
    });
  }

  /// The plan and goals as "item,value" rows.
  String _planCsv(String Function(Object?) esc) {
    final p = tracker.profile.value;
    String day(DateTime? d) => d == null ? '' : Dates.key(d);
    final rows = <(String, Object?)>[
      if (p != null) ...[
        ('medicine', Catalog.medicineName(p.medicineId, p.customMedicine)),
        ('form', p.form),
        ('strength_mg', p.strengthMg),
        ('every_days', p.everyDays),
        if (!p.isDaily) ('dose_weekday', Dates.weekdayName(p.shotWeekday)),
        ('dose_time', Dates.timeOfDay(p.shotMinutes)),
        ('treatment_started', day(p.treatmentStartedAt)),
        ('start_weight_kg', p.startWeightKg.toStringAsFixed(1)),
        ('goal_weight_kg', p.goalWeightKg?.toStringAsFixed(1) ?? ''),
        ('height_cm', p.heightCm?.toStringAsFixed(0) ?? ''),
        ('protein_goal_g', p.proteinGoalG),
        ('water_goal_ml', p.waterGoalMl),
        ('diet', p.diet ?? ''),
        ('kindose_started', day(p.startedAt)),
      ],
      ('last_doctor_visit', day(tracker.lastAppointment.value)),
      ('next_doctor_visit', day(tracker.nextAppointment.value)),
      for (final q in tracker.reportQuestions) ('question_for_doctor', q),
    ];
    final b = StringBuffer('item,value\n');
    for (final (k, v) in rows) {
      b.writeln('${esc(k)},${esc(v)}');
    }
    return b.toString();
  }

  String _level(int? v, List<String> names) =>
      v == null || v < 0 || v >= names.length ? '' : names[v];

  Future<void> _share(Map<String, String> files) async {
    if (exporting.value) return;
    exporting.value = true;
    try {
      final dir = await getTemporaryDirectory();
      final xfiles = <XFile>[];
      for (final e in files.entries) {
        final f = File('${dir.path}/${e.key}');
        await f.writeAsString(e.value, flush: true);
        xfiles.add(XFile(f.path));
      }
      final size = Get.size;
      await SharePlus.instance.share(
        ShareParams(
          files: xfiles,
          subject: 'My Kindose data',
          sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
        ),
      );
    } catch (_) {
      showToast("Couldn't export. Please try again.");
    } finally {
      exporting.value = false;
    }
  }

  // ---------------------------------------------------------------- delete

  Future<void> confirmDeleteAll() async {
    Haptics.instance.mediumImpact();
    final ok = await showDeleteAllSheet(signedIn: signedIn);
    if (ok != true) return;
    Haptics.instance.heavyImpact();
    // Signed in: sign out too, so an empty phone is never tied to the
    // account (the cloud backup stays).
    if (signedIn) {
      await backend.signOutAndClear();
    } else {
      await tracker.deleteAll();
      Get.find<NotifPrefs>().load();
    }
    Get.offAllNamed<void>(Routes.welcome);
  }

  // ----------------------------------------------------------------- about

  void openLegal() {
    Haptics.instance.selectionClick();
    showLegalSheet();
  }

  void openLicences(BuildContext context) {
    Haptics.instance.selectionClick();
    showLicensePage(
      context: context,
      applicationName: 'Kindose',
      applicationVersion: version.value,
      applicationLegalese: 'A personal GLP-1 log. Not medical advice.',
    );
  }

  bool get canContact => AppLinks.supportEmail.isNotEmpty;


  /// Always shown: opens the store page, or the rating dialog until the
  /// App Store id is known (ReviewService.openStore).
  bool get canRate => true;

  Future<void> contactSupport() async {
    Haptics.instance.selectionClick();
    final subject = Uri.encodeComponent('Kindose ${version.value} support');
    final uri = Uri.parse('mailto:${AppLinks.supportEmail}?subject=$subject');
    if (!await _launch(uri)) showToast('Email us at ${AppLinks.supportEmail}');
  }

  Future<void> rateApp() async {
    Haptics.instance.selectionClick();
    if (!await ReviewService.openStore()) {
      showToast("Couldn't open the store.");
    }
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
