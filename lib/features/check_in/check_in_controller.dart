import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/date_utils.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

/// How-I-feel check-in for today. Opens pre-filled with anything already
/// logged today, so it works as an edit screen too.
class CheckInController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController noteCtrl = TextEditingController();
  final FocusNode noteFocus = FocusNode();

  final RxnInt mood = RxnInt();
  final RxSet<String> symptoms = <String>{}.obs;
  final RxnInt nausea = RxnInt();
  final RxnInt foodNoise = RxnInt();
  final RxnInt appetite = RxnInt();
  final RxBool saving = false.obs;

  /// Opened from the "Note" tile: jump straight to the note field.
  late final bool focusNote = Get.arguments == 'note';

  @override
  void onInit() {
    super.onInit();
    final d = tracker.today;
    mood.value = d.mood;
    symptoms.assignAll(d.symptoms);
    nausea.value = d.nausea;
    foodNoise.value = d.foodNoise;
    appetite.value = d.appetite;
    noteCtrl.text = d.note ?? '';
  }

  @override
  void onReady() {
    super.onReady();
    if (focusNote) noteFocus.requestFocus();
  }

  @override
  void onClose() {
    noteCtrl.dispose();
    noteFocus.dispose();
    super.onClose();
  }

  /// "Day 1 after your dose", or empty if no dose is logged yet.
  String get dayLabel {
    final last = tracker.lastDose;
    if (last == null) return '';
    final n = Dates.daysBetween(last.takenAt, DateTime.now());
    if (n == 0) return 'Dose day';
    return 'Day $n after your dose';
  }

  void toggleSymptom(String id) {
    if (symptoms.contains(id)) {
      symptoms.remove(id);
      if (id == 'nausea') nausea.value = null;
    } else {
      symptoms.add(id);
    }
  }

  /// Tapping the selected level again clears it.
  void setLevel(RxnInt target, int value) {
    target.value = target.value == value ? null : value;
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    try {
      final note = noteCtrl.text.trim();
      final d = tracker.today;
      // Build a fresh record so cleared answers really become empty.
      await tracker.saveDay(DayLog(
        key: d.key,
        proteinG: d.proteinG,
        waterMl: d.waterMl,
        mood: mood.value,
        symptoms: symptoms.toList(),
        nausea: symptoms.contains('nausea') ? nausea.value : null,
        foodNoise: foodNoise.value,
        appetite: appetite.value,
        note: note.isEmpty ? null : note,
      ));
      popRoute();
      showToast('Check-in saved');
    } finally {
      saving.value = false;
    }
  }
}
