import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/access_service.dart';
import '../../services/tracker_service.dart';
import '../../services/upsell/upsell_service.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/toast.dart';
import '../common/day_nav.dart';

/// How-I-feel check-in, for today or a past day (pass the DateTime as the
/// argument; 'note' opens today's with the note field focused). Opens
/// pre-filled with anything already logged, so it works as an edit too.
/// ‹ day › moves between days; unsaved changes are confirmed first.
class CheckInController extends GetxController with DayNav {
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

  /// The form as it was loaded, to tell when there are unsaved changes.
  String _loaded = '';

  @override
  void onInit() {
    super.onInit();
    initDay(Get.arguments);
    _load();
    showNote.value = focusNote || noteCtrl.text.isNotEmpty;
  }

  /// Fills the form from [day]'s saved check-in (empty if none).
  void _load() {
    final d = tracker.dayLog(day.value);
    mood.value = d.mood;
    nausea.value = d.symptoms.contains('nausea')
        ? (d.nausea ?? 0).clamp(0, 2)
        : (d.nausea == -1 ? -1 : null);
    foodNoise.value = d.foodNoise;
    appetite.value = d.appetite;
    levels.clear();
    for (final id in d.symptoms) {
      if (id == 'nausea') continue;
      final l = d.levelOf(id);
      if (l > 0) levels[id] = l.clamp(1, 3);
    }
    noteCtrl.text = d.note ?? '';
    showNote.value = noteCtrl.text.isNotEmpty;
    _loaded = _form;
  }

  String get _form => [
    mood.value,
    nausea.value,
    foodNoise.value,
    appetite.value,
    (levels.entries.map((e) => '${e.key}:${e.value}').toList()..sort()).join(
      ',',
    ),
    noteCtrl.text.trim(),
  ].join('|');

  bool get _dirty => _form != _loaded;

  @override
  void onDayChanged() => _load();

  /// Asks before leaving a day with unsaved changes.
  @override
  void setDay(DateTime d) {
    if (Dates.sameDay(d, day.value) || !_dirty) {
      super.setDay(d);
      return;
    }
    () async {
      final ok = await confirmRemove(
        title: 'Discard your changes?',
        message:
            "You haven't saved this check-in. Switching to "
            '${Dates.shortWithDay(d)} will lose them.',
        action: 'Discard',
      );
      if (ok) super.setDay(d);
    }();
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
    final date = Dates.long(day.value).toUpperCase();
    if (!isToday) return date;
    final last = tracker.lastDose;
    if (last == null || (tracker.profile.value?.isDaily ?? false)) {
      return date;
    }
    final n = Dates.daysBetween(last.takenAt, day.value);
    if (n == 0) return 'DOSE DAY';
    return 'DAY $n AFTER YOUR DOSE';
  }

  String get title => isToday ? 'How are you today?' : 'How did you feel?';

  String get sub => isToday
      ? 'About 20 seconds. Everything is optional.'
      : 'Logging for ${Dates.shortWithDay(day.value)}. Everything is optional.';

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
      final d = tracker.dayLog(day.value);
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
      // Near the end of the free week, once (skipped on a severe day).
      if (!anySevere) Get.find<UpsellService>().afterLog();
    } finally {
      saving.value = false;
    }
  }
}
