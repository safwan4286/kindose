import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/plus_access.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';
import 'report_data.dart';
import 'report_pdf.dart';
import '../../widgets/k_date_picker.dart';

enum ReportPeriod { lastVisit, weeks4, months3, all }

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

  /// Neutral questions people often bring. Never answers, only prompts.
  static const List<String> ideaPool = [
    'Should my dose change?',
    'Is my weight change OK for me?',
    'What should I do if I miss a dose?',
    'How can I protect my muscle?',
    'Are my side effects expected?',
  ];

  @override
  void onInit() {
    super.onInit();
    tracker.rollAppointment();
  }

  @override
  void onClose() {
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
    if (a == null) return 'Add your next appointment';
    final days = Dates.daysBetween(DateTime.now(), a);
    final when = switch (days) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $days days',
    };
    return '${Dates.shortWithDay(a)} · $when';
  }

  String get appointmentSub => nextAppointment == null
      ? 'We’ll remind you 3 days before to get your report ready.'
      : tracker.visitReminderOn.value
      ? 'We’ll remind you 3 days before.'
      : 'Turn on Doctor visit reminders in Me to get a nudge 3 days before.';

  Future<void> pickAppointment(BuildContext context) async {
    Haptics.instance.selectionClick();
    final now = DateTime.now();
    final first = Dates.dateOnly(now);
    final saved = nextAppointment;
    final initial = (saved == null || saved.isBefore(first))
        ? now.add(const Duration(days: 7))
        : saved;
    final picked = await showKDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      title: 'Next appointment',
      note: 'We’ll remind you 3 days before.',
    );
    if (picked != null) await tracker.setNextAppointment(picked);
  }

  // ---------------------------------------------------------------- period

  List<ReportPeriod> get periods => [
    if (tracker.lastAppointment.value != null) ReportPeriod.lastVisit,
    ReportPeriod.weeks4,
    ReportPeriod.months3,
    ReportPeriod.all,
  ];

  String periodLabel(ReportPeriod p) => switch (p) {
    ReportPeriod.lastVisit => 'Last visit',
    ReportPeriod.weeks4 => '4 weeks',
    ReportPeriod.months3 => '3 months',
    ReportPeriod.all => 'All',
  };

  String periodSub(ReportPeriod p) {
    switch (p) {
      case ReportPeriod.lastVisit:
        final l = tracker.lastAppointment.value;
        return l == null ? '' : Dates.short(l);
      case ReportPeriod.all:
        final s = _treatmentStart;
        return s == null ? '' : 'since ${Dates.monthShort(s.month)}';
      default:
        return '';
    }
  }

  void pickPeriod(ReportPeriod p) {
    if (period.value == p) return;
    Haptics.instance.selectionClick();
    period.value = p;
  }

  DateTime? get _treatmentStart {
    final t = tracker;
    final started = t.profile.value?.treatmentStartedAt;
    final candidates = <DateTime>[
      if (started != null) started,
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
              today.subtract(const Duration(days: 27)),
        );
      case ReportPeriod.weeks4:
        return today.subtract(const Duration(days: 27));
      case ReportPeriod.months3:
        return today.subtract(const Duration(days: 90));
      case ReportPeriod.all:
        return Dates.dateOnly(
          _treatmentStart ?? today.subtract(const Duration(days: 27)),
        );
    }
  }

  DateTime get to => Dates.dateOnly(DateTime.now());

  String get periodNote => switch (period.value) {
    ReportPeriod.lastVisit => 'since last visit',
    ReportPeriod.weeks4 => 'last 4 weeks',
    ReportPeriod.months3 => 'last 3 months',
    ReportPeriod.all => 'whole treatment',
  };

  String get periodTitle {
    final days = Dates.daysBetween(from, to) + 1;
    final length = days >= 14 ? '${(days / 7).round()} weeks' : '$days days';
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
        filename: 'kindose-report-${Dates.key(DateTime.now())}.pdf',
      );
    } catch (_) {
      showToast("Couldn't create the PDF. Please try again.");
    } finally {
      busy.value = false;
    }
  }
}
