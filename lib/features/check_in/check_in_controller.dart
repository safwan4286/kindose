import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/access_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

/// How-I-feel check-in, for today or a past day (pass the DateTime as the
/// argument; 'note' opens today's with the note field focused). Opens
/// pre-filled with anything already logged, so it works as an edit too.
class CheckInController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController noteCtrl = TextEditingController();
  final FocusNode noteFocus = FocusNode();

  final RxnInt mood = RxnInt();

  /// -1 none, 0 mild, 1 moderate, 2 severe; null = not answered.
  final RxnInt nausea = RxnInt();
  final RxnInt foodNoise = RxnInt();
  final RxnInt appetite = RxnInt();

  /// Side effect id → 1 mild, 2 moderate, 3 severe (absent = not felt),
  /// in the order they were picked.
  final RxMap<String, int> levels = <String, int>{}.obs;
  final RxBool showNote = false.obs;
  final RxBool saving = false.obs;

  /// Opened from a "Note" shortcut: jump straight to the note field.
  late final bool focusNote = Get.arguments == 'note';

  /// The day being logged; never after today.
  late final DateTime day = () {
    final arg = Get.arguments;
    final today = Dates.dateOnly(DateTime.now());
    if (arg is! DateTime) return today;
    final d = Dates.dateOnly(arg);
    return d.isAfter(today) ? today : d;
  }();

  bool get isToday => Dates.sameDay(day, DateTime.now());

  @override
  void onInit() {
    super.onInit();
    final d = tracker.dayLog(day);
    mood.value = d.mood;
    nausea.value = d.symptoms.contains('nausea')
        ? (d.nausea ?? 0).clamp(0, 2)
        : (d.nausea == -1 ? -1 : null);
    foodNoise.value = d.foodNoise;
    appetite.value = d.appetite;
    for (final id in d.symptoms) {
      if (id == 'nausea') continue;
      final l = d.levelOf(id);
      if (l > 0) levels[id] = l.clamp(1, 3);
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

  /// "DAY 2 AFTER YOUR DOSE", "DOSE DAY", or the date: always the date
  /// for a past day, so it's clear which day is being logged.
  String get eyebrow {
    final date = Dates.long(day).toUpperCase();
    if (!isToday) return date;
    final last = tracker.lastDose;
    if (last == null || (tracker.profile.value?.isDaily ?? false)) {
      return date;
    }
    final n = Dates.daysBetween(last.takenAt, day);
    if (n == 0) return 'DOSE DAY';
    return 'DAY $n AFTER YOUR DOSE';
  }

  String get title => isToday ? 'How are you today?' : 'How did you feel?';

  String get sub => isToday
      ? 'About 20 seconds. Everything is optional.'
      : 'Logging for ${Dates.shortWithDay(day)}. Everything is optional.';

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

  /// Side effects on the screen: the person's list, then anything already
  /// logged for this day that isn't on it (so it can still be changed).
  List<String> get effects {
    final custom = tracker.customSymptoms.map(Catalog.customId).toSet();
    final shown = [
      for (final id in tracker.checkInShown)
        if (Catalog.symptoms.containsKey(id) || custom.contains(id)) id,
    ];
    return [
      ...shown,
      for (final id in levels.keys)
        if (!shown.contains(id)) id,
    ];
  }

  /// Picks a side effect (mild to start) or takes it off.
  void toggleEffect(String id) {
    Haptics.instance.selectionClick();
    if (levels.containsKey(id)) {
      levels.remove(id);
    } else {
      levels[id] = 1;
    }
  }

  /// 1 mild, 2 moderate, 3 severe.
  void setLevel(String id, int level) {
    if (levels[id] == level) return;
    if (level == 3) {
      Haptics.instance.mediumImpact();
    } else {
      Haptics.instance.selectionClick();
    }
    levels[id] = level;
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
    if (!await AccessService.ensure()) return;
    saving.value = true;
    try {
      final note = noteCtrl.text.trim();
      final d = tracker.dayLog(day);
      final effects = Map<String, int>.from(levels);
      // Build a fresh record so cleared answers really become empty.
      await tracker.saveDay(
        DayLog(
          key: d.key,
          proteinG: d.proteinG,
          waterMl: d.waterMl,
          entries: d.entries,
          mood: mood.value,
          symptoms: [if ((nausea.value ?? -1) >= 0) 'nausea', ...effects.keys],
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
