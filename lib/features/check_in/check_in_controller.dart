import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

/// How-I-feel check-in for today. Opens pre-filled with anything already
/// logged today, so it works as an edit screen too.
class CheckInController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController noteCtrl = TextEditingController();
  final FocusNode noteFocus = FocusNode();

  final RxnInt mood = RxnInt();

  /// -1 none, 0 mild, 1 moderate, 2 severe; null = not answered.
  final RxnInt nausea = RxnInt();
  final RxnInt foodNoise = RxnInt();
  final RxnInt appetite = RxnInt();

  /// Side effect id → 1 mild, 2 moderate, 3 severe (absent = not felt).
  final RxMap<String, int> levels = <String, int>{}.obs;
  final RxBool showNote = false.obs;
  final RxBool saving = false.obs;

  /// Opened from a "Note" shortcut: jump straight to the note field.
  late final bool focusNote = Get.arguments == 'note';

  @override
  void onInit() {
    super.onInit();
    final d = tracker.today;
    mood.value = d.mood;
    nausea.value = d.symptoms.contains('nausea')
        ? (d.nausea ?? 0).clamp(0, 2)
        : (d.nausea == -1 ? -1 : null);
    foodNoise.value = d.foodNoise;
    appetite.value = d.appetite;
    for (final id in Catalog.checkInEffects) {
      final l = d.levelOf(id);
      if (l > 0) levels[id] = l;
    }
    noteCtrl.text = d.note ?? '';
    showNote.value = focusNote || noteCtrl.text.isNotEmpty;
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

  /// "DAY 2 AFTER YOUR DOSE", "DOSE DAY", or today's date before any dose.
  String get eyebrow {
    final last = tracker.lastDose;
    if (last == null || (tracker.profile.value?.isDaily ?? false)) {
      return Dates.long(DateTime.now()).toUpperCase();
    }
    final n = Dates.daysBetween(last.takenAt, DateTime.now());
    if (n == 0) return 'DOSE DAY';
    return 'DAY $n AFTER YOUR DOSE';
  }

  void pickMood(int i) {
    Haptics.instance.selectionClick();
    mood.value = mood.value == i ? null : i;
  }

  /// On screen 0 None, 1 Mild, 2 Moderate, 3 Severe (stored one lower,
  /// so None is -1). Tapping the selected one again clears the answer.
  void pickNausea(int onScreen) {
    Haptics.instance.selectionClick();
    final v = onScreen - 1;
    nausea.value = nausea.value == v ? null : v;
  }

  /// Selected button on screen, or null when not answered.
  int? get nauseaOnScreen {
    final n = nausea.value;
    return n == null ? null : n + 1;
  }

  void pickLevel(RxnInt target, int value) {
    Haptics.instance.selectionClick();
    target.value = target.value == value ? null : value;
  }

  /// Not felt → mild → moderate → severe → not felt.
  void tapEffect(String id) {
    final next = ((levels[id] ?? 0) + 1) % 4;
    if (next == 3) {
      Haptics.instance.mediumImpact();
    } else {
      Haptics.instance.selectionClick();
    }
    if (next == 0) {
      levels.remove(id);
    } else {
      levels[id] = next;
    }
  }

  int levelOf(String id) => levels[id] ?? 0;

  /// Something marked severe: show the "get help" card.
  bool get anySevere => nausea.value == 2 || levels.values.any((l) => l >= 3);

  void openPlus() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.plus);
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    try {
      final note = noteCtrl.text.trim();
      final d = tracker.today;
      final effects = Map<String, int>.from(levels);
      // Build a fresh record so cleared answers really become empty.
      await tracker.saveDay(
        DayLog(
          key: d.key,
          proteinG: d.proteinG,
          waterMl: d.waterMl,
          entries: d.entries,
          mood: mood.value,
          symptoms: [
            if ((nausea.value ?? -1) >= 0) 'nausea',
            ...effects.keys,
          ],
          symptomLevels: effects,
          nausea: nausea.value,
          foodNoise: foodNoise.value,
          appetite: appetite.value,
          note: note.isEmpty ? null : note,
        ),
      );
      Haptics.instance.mediumImpact();
      popRoute();
      showToast('Check-in saved');
    } finally {
      saving.value = false;
    }
  }
}
