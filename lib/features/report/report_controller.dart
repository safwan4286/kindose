import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';

import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/notifications/notif_prefs.dart';
import '../../services/plus/plus_access.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';
import 'report_data.dart';
import 'report_pdf.dart';
import '../../widgets/choice_sheet.dart';
import '../notifications/notification_permission.dart';
import '../../widgets/k_date_picker.dart';

enum ReportPeriod { lastVisit, weeks4, months3, all, custom }

/// Doctor report tab. Name and birth date live only in memory for this
/// screen and are never written to storage. Questions are saved so they
/// are still there at the visit.
class ReportController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();
  final TextEditingController questionCtrl = TextEditingController();

  late final Rx<ReportPeriod> period =
      (tracker.lastAppointment.value != null
              ? ReportPeriod.lastVisit
              : ReportPeriod.weeks4)
          .obs;

  final RxBool doses = true.obs;
  final RxBool weight = true.obs;
  final RxBool sideEffects = true.obs;
  final RxBool nutrition = true.obs;
  final RxBool notes = false.obs;
  final RxBool includeName = false.obs;
  final RxBool sharing = false.obs;
  final RxBool saving = false.obs;

  /// Neutral questions people often bring. Never answers, only prompts.
  static const List<String> ideaPool = [
    'Should my dose change?',
    'Is my weight change OK for me?',
    'What should I do if I miss a dose?',
    'How can I protect my muscle?',
    'Are my side effects expected?',
  ];

  AppLifecycleListener? _life;

  @override
  void onInit() {
    super.onInit();
    tracker.rollAppointment();
    // The tab lives for the whole session: a visit that passes while the
    // app sits in the background becomes "last visit" on return.
    _life = AppLifecycleListener(onResume: tracker.rollAppointment);
  }

  @override
  void onClose() {
    _life?.dispose();
    nameCtrl.dispose();
    dobCtrl.dispose();
    questionCtrl.dispose();
    super.onClose();
  }

  void watch() {
    tracker.nextAppointment.value;
    tracker.lastAppointment.value;
    tracker.reportQuestions.length;
    tracker.visitReminderOn.value;
    _prefs.visitDays.value;
    customFrom.value;
    customTo.value;
    tracker.doses.length;
    tracker.days.length;
    tracker.weights.length;
    period.value;
    doses.value;
    weight.value;
    sideEffects.value;
    nutrition.value;
    notes.value;
    includeName.value;
    PlusAccess.unlocked;
  }

  bool get isPlus => PlusAccess.unlocked;

  // ------------------------------------------------------------ appointment

  DateTime? get nextAppointment => tracker.nextAppointment.value;

  String get appointmentTitle {
    final a = nextAppointment;
    if (a == null) return 'Add your next visit';
    final days = Dates.daysBetween(DateTime.now(), a);
    final when = switch (days) {
      < 0 => 'passed',
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $days days',
    };
    return '${Dates.shortWithDay(a)} · $when';
  }

  NotifPrefs get _prefs => Get.find<NotifPrefs>();

  /// "3 days before" (from Notifications), or "Off".
  String get reminderLabel {
    if (!tracker.visitReminderOn.value) return 'Off';
    final d = _prefs.visitDays.value;
    return d == 7 ? '1 week before' : '$d ${d == 1 ? 'day' : 'days'} before';
  }

  /// Reminder timing, the same setting as Me → Notifications. 0 = off.
  Future<void> pickReminder() async {
    final current = tracker.visitReminderOn.value ? _prefs.visitDays.value : 0;
    final picked = await showChoiceSheet<int>(
      title: 'Visit reminder',
      sub: 'A nudge at 9 AM to check your report and add questions.',
      options: const [1, 2, 3, 7, 0],
      selected: current,
      labelOf: (d) => switch (d) {
        0 => 'Off',
        1 => '1 day before',
        7 => '1 week before',
        _ => '$d days before',
      },
    );
    if (picked == null || picked == current) return;
    if (picked == 0) {
      await tracker.setVisitReminderOn(false);
      return;
    }
    if (!await askForNotifications()) return;
    _prefs.visitDays.value = picked;
    await _prefs.save();
    if (!tracker.visitReminderOn.value) await tracker.setVisitReminderOn(true);
  }

  Future<void> pickAppointment(BuildContext context) async {
    Haptics.instance.selectionClick();
    final now = DateTime.now();
    final first = Dates.dateOnly(now);
    final saved = nextAppointment;
    final initial = (saved == null || saved.isBefore(first))
        ? Dates.addDays(now, 7)
        : saved;
    final picked = await showKDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: Dates.addDays(now, 365),
      title: 'Next appointment',
      note: tracker.visitReminderOn.value
          ? 'We’ll remind you ${reminderLabel.toLowerCase()}.'
          : null,
    );
    if (picked == null) return;
    await tracker.setNextAppointment(picked);
    // First visit with the reminder on: ask the phone now, so the
    // reminder can actually arrive.
    if (tracker.visitReminderOn.value) await askForNotifications();
  }

  // ---------------------------------------------------------------- period

  List<ReportPeriod> get periods => [
    if (tracker.lastAppointment.value != null) ReportPeriod.lastVisit,
    ReportPeriod.weeks4,
    ReportPeriod.months3,
    ReportPeriod.all,
    ReportPeriod.custom,
  ];

  /// Dates picked for [ReportPeriod.custom].
  final Rxn<DateTime> customFrom = Rxn<DateTime>();
  final Rxn<DateTime> customTo = Rxn<DateTime>();

  /// Start, then end. Cancelling either keeps what was there.
  Future<void> pickCustom(BuildContext context) async {
    final today = Dates.dateOnly(DateTime.now());
    final earliest = _treatmentStart == null
        ? Dates.addDays(today, -365 * 3)
        : Dates.dateOnly(_treatmentStart!);
    final start = await showKDatePicker(
      context: context,
      initialDate: customFrom.value ?? Dates.addDays(today, -27),
      firstDate: earliest.isAfter(today) ? today : earliest,
      lastDate: today,
      title: 'Report from',
    );
    if (start == null || !context.mounted) return;
    final s = Dates.dateOnly(start);
    final end = await showKDatePicker(
      context: context,
      initialDate: customTo.value == null || customTo.value!.isBefore(s)
          ? today
          : customTo.value!,
      firstDate: s,
      lastDate: today,
      title: 'Report until',
    );
    if (end == null) return;
    customFrom.value = s;
    customTo.value = Dates.dateOnly(end);
    period.value = ReportPeriod.custom;
  }

  String periodLabel(ReportPeriod p) => switch (p) {
    ReportPeriod.lastVisit => 'Last visit',
    ReportPeriod.weeks4 => '4 weeks',
    ReportPeriod.months3 => '3 months',
    ReportPeriod.all => 'All',
    ReportPeriod.custom => 'Custom',
  };

  String periodSub(ReportPeriod p) {
    switch (p) {
      case ReportPeriod.lastVisit:
        final l = tracker.lastAppointment.value;
        return l == null ? '' : Dates.short(l);
      case ReportPeriod.custom:
        final f = customFrom.value;
        return f == null ? '' : Dates.short(f);
      default:
        return '';
    }
  }

  void pickPeriod(ReportPeriod p, BuildContext context) {
    // Custom always opens the dates, so they can be changed.
    if (p == ReportPeriod.custom) {
      Haptics.instance.selectionClick();
      pickCustom(context);
      return;
    }
    if (period.value == p) return;
    Haptics.instance.selectionClick();
    period.value = p;
  }

  DateTime? get _treatmentStart {
    final t = tracker;
    final started = t.profile.value?.treatmentStartedAt;
    final candidates = <DateTime>[
      ?started,
      if (t.doses.isNotEmpty) t.doses.last.takenAt,
      if (t.weights.isNotEmpty) t.weights.first.date,
    ];
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  DateTime get from {
    final today = Dates.dateOnly(DateTime.now());
    switch (period.value) {
      case ReportPeriod.lastVisit:
        return Dates.dateOnly(
          tracker.lastAppointment.value ??
              Dates.addDays(today, -27),
        );
      case ReportPeriod.weeks4:
        return Dates.addDays(today, -27);
      case ReportPeriod.months3:
        return Dates.addDays(today, -90);
      case ReportPeriod.all:
        return Dates.dateOnly(
          _treatmentStart ?? Dates.addDays(today, -27),
        );
      case ReportPeriod.custom:
        return customFrom.value ?? Dates.addDays(today, -27);
    }
  }

  DateTime get to {
    final end = customTo.value;
    return period.value == ReportPeriod.custom && end != null
        ? end
        : Dates.dateOnly(DateTime.now());
  }

  String get periodNote => switch (period.value) {
    ReportPeriod.lastVisit => 'since last visit',
    ReportPeriod.weeks4 => 'last 4 weeks',
    ReportPeriod.months3 => 'last 3 months',
    ReportPeriod.all => 'whole treatment',
    ReportPeriod.custom => 'chosen dates',
  };

  String get periodTitle {
    final days = Dates.daysBetween(from, to) + 1;
    final length = days >= 14
        ? '${(days / 7).round()} weeks'
        : '$days ${days == 1 ? 'day' : 'days'}';
    return '${Dates.short(from)} – ${Dates.short(to)} · $length';
  }

  // -------------------------------------------------------------- sections

  ReportSections get sections => ReportSections(
    doses: doses.value,
    weight: weight.value,
    sideEffects: sideEffects.value,
    nutrition: nutrition.value,
    notes: notes.value,
  );

  bool get anySection =>
      doses.value ||
      weight.value ||
      sideEffects.value ||
      nutrition.value ||
      notes.value;

  void flip(RxBool v) {
    Haptics.instance.selectionClick();
    v.value = !v.value;
  }

  String get summary {
    final parts = [
      if (doses.value) 'doses',
      if (weight.value) 'weight',
      if (sideEffects.value) 'side effects',
      if (nutrition.value) 'protein & water',
      if (notes.value) 'notes',
    ];
    if (parts.isEmpty) return 'Pick at least one section.';
    final qs = questions.length;
    final joined = parts.length == 1
        ? parts.first
        : '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
    return 'Includes $joined${qs == 0 ? '.' : ', plus $qs ${qs == 1 ? 'question' : 'questions'}.'}';
  }

  // ------------------------------------------------------------- questions

  List<String> get questions => tracker.reportQuestions;

  List<String> get ideas =>
      ideaPool.where((q) => !questions.contains(q)).take(3).toList();

  Future<void> addQuestion([String? text]) async {
    final q = (text ?? questionCtrl.text).trim();
    if (q.isEmpty || questions.contains(q)) return;
    Haptics.instance.lightImpact();
    await tracker.setReportQuestions([...questions, q]);
    if (text == null) questionCtrl.clear();
  }

  Future<void> removeQuestion(int i) async {
    Haptics.instance.selectionClick();
    final list = [...questions]..removeAt(i);
    await tracker.setReportQuestions(list);
  }

  // --------------------------------------------------------- preview/share

  ReportData buildData() => ReportData.build(
    tracker,
    from: from,
    to: to,
    sections: sections,
    periodNote: periodNote,
    questions: questions,
    patientName: includeName.value ? nameCtrl.text.trim() : null,
    patientDob: includeName.value ? dobCtrl.text.trim() : null,
  );

  void preview() {
    if (!anySection) {
      showToast('Pick at least one section.');
      return;
    }
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.reportPreview, arguments: buildData());
  }

  Future<void> sharePdf() async {
    if (!anySection) {
      showToast('Pick at least one section.');
      return;
    }
    await share(buildData(), sharing);
  }

  Future<void> downloadPdf() async {
    if (!anySection) {
      showToast('Pick at least one section.');
      return;
    }
    await download(buildData(), saving);
  }

  static String get _fileName =>
      'kindose-report-${Dates.key(DateTime.now())}.pdf';

  /// Save the PDF where the user picks, with the phone's own Save dialog
  /// (Android: e.g. Downloads; iPhone: Files). Plus, like sharing.
  static Future<void> download(ReportData data, RxBool busy) async {
    if (!PlusAccess.unlocked) {
      Haptics.instance.selectionClick();
      await Get.toNamed<void>(Routes.plus);
      return;
    }
    if (busy.value) return;
    busy.value = true;
    try {
      Haptics.instance.lightImpact();
      final bytes = await ReportPdf.build(data);
      final saved = await FilePicker.saveFile(
        fileName: _fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
        dialogTitle: 'Save report',
      );
      if (saved != null) {
        Haptics.instance.mediumImpact();
        showToast('Report saved');
      }
    } catch (_) {
      showToast("Couldn't save the PDF. Please try again.");
    } finally {
      busy.value = false;
    }
  }

  /// Share the PDF (Plus). Free users are taken to the Plus screen.
  static Future<void> share(ReportData data, RxBool busy) async {
    if (!PlusAccess.unlocked) {
      Haptics.instance.selectionClick();
      await Get.toNamed<void>(Routes.plus);
      return;
    }
    if (busy.value) return;
    busy.value = true;
    try {
      Haptics.instance.mediumImpact();
      final bytes = await ReportPdf.build(data);
      await Printing.sharePdf(
        bytes: bytes,
        filename: _fileName,
      );
    } catch (_) {
      showToast("Couldn't create the PDF. Please try again.");
    } finally {
      busy.value = false;
    }
  }
}
