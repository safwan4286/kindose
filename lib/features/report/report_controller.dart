import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';
import 'report_data.dart';
import 'report_pdf.dart';

/// Builds the doctor report. Name and birth date live only in memory for
/// this screen and are never written to storage.
class ReportController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();

  late final Rx<DateTimeRange> range = DateTimeRange(
    start: Dates.dateOnly(DateTime.now()).subtract(const Duration(days: 30)),
    end: Dates.dateOnly(DateTime.now()),
  ).obs;

  final RxBool doses = true.obs;
  final RxBool weight = true.obs;
  final RxBool sideEffects = true.obs;
  final RxBool nutrition = true.obs;
  final RxBool notes = false.obs;
  final RxBool includeName = false.obs;
  final RxBool sharing = false.obs;

  @override
  void onClose() {
    nameCtrl.dispose();
    dobCtrl.dispose();
    super.onClose();
  }

  String get rangeLabel => '${Dates.short(range.value.start)} – ${Dates.short(range.value.end)}';

  String get appointmentLabel {
    final a = tracker.nextAppointment.value;
    return a == null ? 'Add date' : Dates.shortWithDay(a);
  }

  ReportSections get sections => ReportSections(
        doses: doses.value,
        weight: weight.value,
        sideEffects: sideEffects.value,
        nutrition: nutrition.value,
        notes: notes.value,
      );

  ReportData buildData() => ReportData.build(
        tracker,
        from: range.value.start,
        to: range.value.end,
        sections: sections,
        patientName: includeName.value ? nameCtrl.text.trim() : null,
        patientDob: includeName.value ? dobCtrl.text.trim() : null,
      );

  Future<void> pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 730)),
      lastDate: now,
      initialDateRange: range.value,
      helpText: 'Report period',
    );
    if (picked != null) range.value = picked;
  }

  Future<void> pickAppointment(BuildContext context) async {
    final now = DateTime.now();
    final first = Dates.dateOnly(now).subtract(const Duration(days: 1));
    final saved = tracker.nextAppointment.value;
    // A past appointment can't be the initial date (picker asserts).
    final initial = (saved == null || saved.isBefore(first)) ? now.add(const Duration(days: 7)) : saved;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Next appointment',
    );
    if (picked != null) await tracker.setNextAppointment(picked);
  }

  void preview() => Get.toNamed<void>(Routes.reportPreview, arguments: buildData());

  Future<void> sharePdf() async {
    if (sharing.value) return;
    sharing.value = true;
    try {
      final bytes = await ReportPdf.build(buildData());
      final name = 'kindose-report-${Dates.key(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (_) {
      showToast("Couldn't create the PDF. Please try again.");
    } finally {
      sharing.value = false;
    }
  }
}
