import 'dart:convert';
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
import '../../services/haptics/haptics.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/plus/plus_access.dart';
import '../../services/tracker_service.dart';
import '../../widgets/mood_row.dart';
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
    exporting.value;
    version.value;
  }

  bool get isPlus => PlusAccess.active.value;
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

  String get planTitle {
    final p = tracker.profile.value;
    if (p == null || !hasMedicine) return 'Add your medicine';
    final dose = p.strengthMg > 0 ? ' ${Catalog.mgLabel(p.strengthMg)}' : '';
    return '${Catalog.medicineName(p.medicineId, p.customMedicine)}$dose';
  }

  String get planSub {
    final p = tracker.profile.value;
    if (p == null || !hasMedicine)
      return 'So we can remind you and track your doses.';
    final time = Dates.timeOfDay(p.shotMinutes);
    final day = Dates.weekdayName(p.shotWeekday);
    final when = switch (p.everyDays) {
      1 => 'Every day at $time',
      7 => '${day}s at $time',
      14 => 'Every other $day at $time',
      _ => 'Every ${p.everyDays} days at $time',
    };
    return '${Catalog.formLabel(p.form)} · $when';
  }

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

  String get scheduleTime => Dates.timeOfDay(tracker.profile.value?.shotMinutes ?? 480);

  DateTime? get _next => hasMedicine ? tracker.nextDoseAt(DateTime.now()) : null;

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
    final days = Dates.daysBetween(Dates.dateOnly(DateTime.now()), Dates.dateOnly(next));
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

  void openPlus() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.plus);
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
    return '${(ml / 1000).toStringAsFixed(1)} L a day';
  }

  static const Map<String, String> dietNames = {
    'veg': 'Vegetarian',
    'egg': 'Eggetarian',
    'nonveg': 'Non-vegetarian',
    'vegan': 'Vegan',
    'jain': 'Jain',
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
    final v = await askNumber(
      context,
      title: 'Daily water goal',
      unit: 'L',
      initial: p.waterGoalMl / 1000,
      min: 1,
      max: 6,
    );
    if (v == null || v.isNaN) return;
    await tracker.saveProfile(p.copyWith(waterGoalMl: (v * 1000).round()));
  }

  Future<void> editDiet() async {
    final p = tracker.profile.value;
    if (p == null) return;
    Haptics.instance.selectionClick();
    final picked = await showDietSheet(p.diet);
    if (picked == null || picked == p.diet) return;
    await tracker.saveProfile(
      p.copyWith(diet: picked, vegDiet: picked != 'egg' && picked != 'nonveg'),
    );
  }

  // ------------------------------------------------------------- reminders

  bool get doseReminders => tracker.profile.value?.remindersOn ?? false;
  bool get visitReminders => tracker.visitReminderOn.value;

  Future<void> setDoseReminders(bool on) async {
    final p = tracker.profile.value;
    if (p == null) return;
    if (on && !await _allowNotifications()) return;
    Haptics.instance.selectionClick();
    await tracker.saveProfile(p.copyWith(remindersOn: on));
  }

  Future<void> setVisitReminders(bool on) async {
    if (on && !await _allowNotifications()) return;
    Haptics.instance.selectionClick();
    await tracker.setVisitReminderOn(on);
  }

  /// Protein & water nudges are a Plus feature and are not built yet.
  void foodNudges() {
    if (!isPlus) {
      openPlus();
      return;
    }
    Haptics.instance.selectionClick();
    showToast('Protein & water nudges are coming in the next update.');
  }

  Future<bool> _allowNotifications() async {
    final granted = await NotificationService.instance.requestPermission();
    if (!granted)
      showToast('Allow notifications for Kindose in your phone settings.');
    return granted;
  }

  // ------------------------------------------------------------ units/theme

  Future<void> setUseKg(bool v) async {
    final p = tracker.profile.value;
    if (p == null || p.useKg == v) return;
    await tracker.saveProfile(p.copyWith(useKg: v));
  }

  Future<void> setTheme(ThemeMode mode) => tracker.setThemeMode(mode);

  // ---------------------------------------------------------------- backup

  /// Cloud backup needs sign-in (Firebase), which is not built yet. Until
  /// then this offers a backup file the user can keep.
  Future<void> backup() async {
    Haptics.instance.selectionClick();
    final save = await showBackupSoonSheet();
    if (save == true) await exportJson();
  }

  // ---------------------------------------------------------------- export

  Future<void> export() async {
    if (exporting.value) return;
    Haptics.instance.selectionClick();
    final choice = await showExportSheet();
    switch (choice) {
      case ExportChoice.csv:
        await exportCsv();
      case ExportChoice.json:
        await exportJson();
      case null:
        return;
    }
  }

  Future<void> exportJson() async {
    const encoder = JsonEncoder.withIndent('  ');
    await _share({
      'kindose-backup-${Dates.key(DateTime.now())}.json': encoder.convert(
        tracker.exportAll(),
      ),
    });
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
      'date,protein_g,water_ml,mood,symptoms,nausea,food_noise,appetite,note\n',
    );
    final sorted = tracker.days.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final d in sorted) {
      days.writeln(
        [
          d.key,
          d.proteinG,
          d.waterMl,
          d.mood == null ? '' : Catalog.moods[d.mood!.clamp(0, 4)].label,
          d.symptoms
              .map(
                (s) => s == 'nausea'
                    ? 'Nausea'
                    : '${Catalog.symptoms[s] ?? s} (${Catalog.levelWords[d.levelOf(s)]})',
              )
              .join('; '),
          _level(d.nausea, const ['mild', 'moderate', 'severe']),
          _level(d.foodNoise, const ['quiet', 'some', 'loud']),
          _level(d.appetite, const ['low', 'normal', 'high']),
          d.note,
        ].map(esc).join(','),
      );
    }

    final weights = StringBuffer('date,weight_kg\n');
    for (final w in tracker.weights) {
      weights.writeln('${w.key},${w.kg.toStringAsFixed(2)}');
    }

    await _share({
      'kindose-doses.csv': doses.toString(),
      'kindose-days.csv': days.toString(),
      'kindose-weights.csv': weights.toString(),
    });
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
    final ok = await showDeleteAllSheet();
    if (ok != true) return;
    Haptics.instance.heavyImpact();
    await tracker.deleteAll();
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

  String get _storeUrl =>
      Platform.isIOS ? AppLinks.appStoreUrl : AppLinks.playStoreUrl;
  bool get canRate => _storeUrl.isNotEmpty;

  Future<void> contactSupport() async {
    Haptics.instance.selectionClick();
    final subject = Uri.encodeComponent('Kindose ${version.value} support');
    final uri = Uri.parse('mailto:${AppLinks.supportEmail}?subject=$subject');
    if (!await _launch(uri)) showToast('Email us at ${AppLinks.supportEmail}');
  }

  Future<void> rateApp() async {
    Haptics.instance.selectionClick();
    if (!await _launch(Uri.parse(_storeUrl)))
      showToast("Couldn't open the store.");
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
