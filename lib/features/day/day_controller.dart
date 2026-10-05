import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../resources/water_units.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/plus_access.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';
import '../common/day_nav.dart';
import '../today/next_bite.dart';

/// Drinks of the same kind logged one after another, shown as one row.
class DrinkGroup {
  DrinkGroup(this.name, this.icon, this.each);

  final String name;
  final String icon;
  final int each;

  /// Newest first.
  final List<LogEntry> entries = [];

  int get total => each * entries.length;
}

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
    PlusAccess.unlocked;
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
      if (d.pain != null && d.pain! > 0)
        'felt ${Catalog.painLabels[d.pain!].toLowerCase()}',
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

  List<LogEntry> entries(String kind) =>
      log.entries.where((e) => e.kind == kind).toList();

  /// Number only ("1.25" or "42"); the unit is [Water.unit].
  String litres(int ml) => Water.total(ml);

  String entryTitle(LogEntry e) {
    final l = e.label;
    if (l != null && l.isNotEmpty) return l;
    return e.isProtein ? 'Protein' : 'Water';
  }

  void openIntake(String kind) {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(
      Routes.addIntake,
      arguments: {'kind': kind, 'day': day.value},
    );
  }

  /// Swipe to remove. Undo puts it back at the same time.
  Future<void> removeEntry(LogEntry e) async {
    Haptics.instance.mediumImpact();
    await tracker.removeEntry(log.key, e.id);
    showUndoToast('${entryName(e)} removed', () async {
      Haptics.instance.selectionClick();
      if (e.isProtein) {
        await tracker.addProtein(e.amount, e.at, e.label);
      } else {
        await tracker.addWater(e.amount, e.at, e.label);
      }
    });
  }

  // --------------------------------------------------------- protein detail

  /// Newest first.
  List<LogEntry> get proteinList => entries('protein').reversed.toList();

  /// "Greek yogurt" from "Greek yogurt, 1/2 cup, 85 g".
  String entryName(LogEntry e) {
    final t = entryTitle(e);
    if (!e.isProtein) return drinkName(e.label);
    final i = t.indexOf(', ');
    return i < 0 ? t : t.substring(0, i);
  }

  /// "1/2 cup, 85 g" (older entries may still carry "· sip slowly").
  String entryPortion(LogEntry e) {
    final t = entryTitle(e);
    final i = t.indexOf(', ');
    return i < 0 ? '' : t.substring(i + 2).split(' · ').first;
  }

  String entryTime(LogEntry e) => Dates.time(e.at);

  /// 3D icon for a logged food: library, Next bite idea, or My foods.
  String foodIcon(LogEntry e) {
    final label = e.label;
    if (label == null || label.isEmpty) return Img3d.biceps;
    final food = Catalog.foodByLabel(label);
    if (food != null) return food.icon;
    for (final i in NextBite.pool) {
      if (label == i.label || label.startsWith('${i.name},')) return i.icon;
    }
    for (final f in tracker.myFoods) {
      if (label == f.name ||
          label.startsWith('${f.name},') ||
          label.startsWith('${f.name} ×')) {
        return f.icon;
      }
    }
    return Img3d.bowl;
  }

  static Color tintFor(String icon) => switch (icon) {
    Img3d.milk ||
    Img3d.whey ||
    Img3d.fish ||
    Img3d.canned ||
    Img3d.shrimp ||
    Img3d.droplet => AppColors.aquaSoft,
    Img3d.chicken ||
    Img3d.meat ||
    Img3d.beans ||
    Img3d.pot ||
    Img3d.bowl => AppColors.tangerineSoft,
    Img3d.peanuts ||
    Img3d.salad ||
    Img3d.bread ||
    Img3d.seedling => AppColors.limeSoft,
    _ => AppColors.amberSoft,
  };

  /// "23 g over your goal · 6 foods" / "31 g short of your goal · 2 foods".
  String get proteinLine {
    final total = log.proteinG;
    final n = proteinList.length;
    final foods = n == 0 ? '' : ' · $n ${n == 1 ? 'food' : 'foods'}';
    if (total == proteinGoal) return 'Right on your goal$foods';
    if (total > proteinGoal)
      return '${total - proteinGoal} g over your goal$foods';
    return '${proteinGoal - total} g short of your goal$foods';
  }

  /// Protein by part of the day: before 12, 12–5 PM, after 5 PM.
  List<(String, int)> get proteinByPart {
    var morning = 0, afternoon = 0, evening = 0;
    for (final e in entries('protein')) {
      final h = e.at.hour;
      if (h < 12) {
        morning += e.amount;
      } else if (h < 17) {
        afternoon += e.amount;
      } else {
        evening += e.amount;
      }
    }
    return [
      ('Morning', morning),
      ('Afternoon', afternoon),
      ('Evening', evening),
    ];
  }

  // ----------------------------------------------------------- water detail

  /// 250 ml, or 8 fl oz for people who see water in ounces.
  int get glassMl => Water.glassMl;

  int get glassesGoal => (waterGoal / glassMl).ceil().clamp(1, 12);
  int get glassesDone => (log.waterMl / glassMl).floor().clamp(0, glassesGoal);

  String get waterLine {
    final left = waterGoal - log.waterMl;
    if (left <= 0) return 'Goal reached';
    final g = (left / glassMl).ceil();
    return '$glassesDone of $glassesGoal glasses · about $g more to go';
  }

  static const Set<String> _plainWater = {
    'Glass',
    'Bottle',
    'Large bottle',
    'Water',
  };

  String drinkName(String? label) =>
      label == null || label.isEmpty || _plainWater.contains(label)
      ? 'Water'
      : label;

  /// Same drink and amount back to back = one row. Newest first.
  List<DrinkGroup> get waterGroups {
    final out = <DrinkGroup>[];
    for (final e in entries('water').reversed) {
      final name = drinkName(e.label);
      final last = out.isEmpty ? null : out.last;
      if (last != null && last.name == name && last.each == e.amount) {
        last.entries.add(e);
      } else {
        out.add(
          DrinkGroup(
            name,
            name == 'Milk' ? Img3d.milk : Img3d.droplet,
            e.amount,
          )..entries.add(e),
        );
      }
    }
    return out;
  }

  // ---------------------------------------------------------------- weight

  WeightEntry? get weighIn {
    for (final w in tracker.weights) {
      if (Dates.sameDay(w.date, day.value)) return w;
    }
    return null;
  }

  bool get useKg => tracker.profile.value?.useKg ?? true;

  String weightLabel(double kg) => useKg
      ? '${kg.toStringAsFixed(1)} kg'
      : '${(kg * 2.20462).toStringAsFixed(1)} lb';

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
    if (log.foodNoise != null)
      'Food noise${_word(log.foodNoise, const ['quiet', 'some', 'loud'])}',
    if (log.appetite != null)
      'Appetite${_word(log.appetite, const ['low', 'normal', 'high'])}',
  ];

  String _word(int? v, List<String> names) =>
      v == null || v < 0 || v >= names.length ? '' : ' · ${names[v]}';

  void openCheckIn() {
    Haptics.instance.selectionClick();
    Get.toNamed<void>(Routes.checkIn);
  }
}
