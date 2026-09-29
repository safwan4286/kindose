import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/plus_access.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';
import '../common/day_nav.dart';

/// Everything logged on one day: dose, protein, water, weight and how it
/// felt. Open with a DateTime (defaults to today).
class DayController extends GetxController with DayNav {
  final TrackerService tracker = Get.find<TrackerService>();

  @override
  void onInit() {
    super.onInit();
    initDay(Get.arguments);
  }

  /// Reads every Rx the screen depends on.
  void watch() {
    day.value;
    tracker.days.length;
    tracker.doses.length;
    tracker.weights.length;
    tracker.profile.value;
    PlusAccess.active.value;
  }

  DayLog get log => tracker.dayLog(day.value);

  /// "Tuesday, 29 September".
  String get longDate => Dates.long(day.value);

  // ------------------------------------------------------------------ dose

  DoseLog? get dose => tracker.doseOn(day.value);

  String get doseTitle {
    final d = dose;
    if (d == null) return '';
    final mg = d.strengthMg > 0 ? ' · ${Catalog.mgLabel(d.strengthMg)}' : '';
    return '${Catalog.medicineName(d.medicineId, tracker.profile.value?.customMedicine)}$mg';
  }

  String get doseLine {
    final d = dose;
    if (d == null) return '';
    return [
      Dates.time(d.takenAt),
      if (d.site.isNotEmpty) Catalog.siteName(d.site),
      if (d.pain != null && d.pain! > 0) 'felt ${Catalog.painLabels[d.pain!].toLowerCase()}',
    ].join(' · ');
  }

  void editDose() {
    final d = dose;
    if (d == null) return;
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.logDose, arguments: d);
  }

  // -------------------------------------------------------- protein & water

  int get proteinGoal => tracker.profile.value?.proteinGoalG ?? 100;
  int get waterGoal => tracker.profile.value?.waterGoalMl ?? 2500;

  List<LogEntry> entries(String kind) => log.entries.where((e) => e.kind == kind).toList();

  String litres(int ml) {
    final s = (ml / 1000).toStringAsFixed(2);
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }

  String entryTitle(LogEntry e) {
    final l = e.label;
    if (l != null && l.isNotEmpty) return l;
    return e.isProtein ? 'Protein' : 'Water';
  }

  void openIntake(String kind) {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.addIntake, arguments: {'kind': kind, 'day': day.value});
  }

  Future<void> removeEntry(LogEntry e) async {
    Haptics.instance.mediumImpact();
    await tracker.removeEntry(log.key, e.id);
    showToast('${entryTitle(e)} removed');
  }

  // ---------------------------------------------------------------- weight

  WeightEntry? get weighIn {
    for (final w in tracker.weights) {
      if (Dates.sameDay(w.date, day.value)) return w;
    }
    return null;
  }

  bool get useKg => tracker.profile.value?.useKg ?? true;

  String weightLabel(double kg) => useKg ? '${kg.toStringAsFixed(1)} kg' : '${(kg * 2.20462).toStringAsFixed(1)} lb';

  // ------------------------------------------------------------- check-in

  bool get hasCheckIn => log.hasCheckIn || (log.note?.isNotEmpty ?? false);

  String? get moodLabel {
    final m = log.mood;
    if (m == null) return null;
    return Catalog.moods[m.clamp(0, Catalog.moods.length - 1)].label;
  }

  String? get moodIcon {
    final m = log.mood;
    if (m == null) return null;
    return Catalog.moods[m.clamp(0, Catalog.moods.length - 1)].icon;
  }

  /// "Nausea · moderate", "Tiredness · mild" …
  List<String> get effects => [
        for (final s in log.symptoms)
          if (s == 'nausea')
            'Nausea${_word(log.nausea, const ['mild', 'moderate', 'severe'])}'
          else
            '${Catalog.symptoms[s] ?? s}${log.levelOf(s) > 0 ? ' · ${Catalog.levelWords[log.levelOf(s)]}' : ''}',
      ];

  List<String> get scales => [
        if (log.foodNoise != null) 'Food noise${_word(log.foodNoise, const ['quiet', 'some', 'loud'])}',
        if (log.appetite != null) 'Appetite${_word(log.appetite, const ['low', 'normal', 'high'])}',
      ];

  String _word(int? v, List<String> names) => v == null || v < 0 || v >= names.length ? '' : ' · ${names[v]}';

  void openCheckIn() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.checkIn);
  }
}
