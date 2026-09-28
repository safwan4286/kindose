import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../services/haptics/haptics.dart';
import '../../services/tracker_service.dart';
import '../../widgets/ask_number.dart';
import '../../widgets/toast.dart';

/// A serving size on the portion chips.
class Portion {
  const Portion(this.label, this.times);

  final String label;
  final double times;
}

/// Protein and water, two tabs on one screen. Open with 'protein' or
/// 'water' as the route argument. Every add is one tap and can be undone.
class IntakeController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController searchCtrl = TextEditingController();

  static const List<Portion> portions = [
    Portion('½', 0.5),
    Portion('1', 1),
    Portion('1½', 1.5),
    Portion('2', 2),
  ];

  late final RxString tab =
      (Get.arguments == 'water' ? 'water' : 'protein').obs;
  final RxString query = ''.obs;
  final RxString category = 'all'.obs;

  /// Food row showing its portion chips, or '' when none is open.
  final RxString openFood = ''.obs;
  final RxDouble portion = 1.0.obs;
  final RxInt customGrams = 20.obs;

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  UserProfile? get profile => tracker.profile.value;
  bool get isProtein => tab.value == 'protein';

  void setTab(String t) {
    tab.value = t;
    openFood.value = '';
  }

  /// Reads every Rx the screen depends on (call at the top of an Obx).
  void watch() {
    tracker.days.length;
    tracker.today;
    tab.value;
    query.value;
    category.value;
    openFood.value;
    portion.value;
    customGrams.value;
  }

  // ---------------------------------------------------------------- protein

  int get proteinGoal => profile?.proteinGoalG ?? 100;
  int get proteinToday => tracker.today.proteinG;
  int get proteinLeft => (proteinGoal - proteinToday).clamp(0, 999);
  double get proteinProgress =>
      proteinGoal == 0 ? 0 : (proteinToday / proteinGoal).clamp(0.0, 1.0);

  String get proteinLine {
    final left = proteinLeft;
    if (left == 0) return 'Goal reached today. Nice work.';
    final meals = (left / 25).ceil();
    return '$left g to go · about $meals protein-first ${meals == 1 ? 'meal' : 'meals'}';
  }

  String? get _diet => profile?.diet;

  /// "VEGETARIAN" etc. for the browse title, or null for everyone.
  String? get dietName => switch (_diet) {
    'veg' => 'Vegetarian',
    'jain' => 'Jain',
    'egg' => 'Eggetarian',
    'vegan' => 'Vegan',
    _ => null,
  };

  /// Most-logged foods first, topped up from the diet's everyday list.
  List<Food> get usualFoods {
    final allowed = Catalog.foodsFor(_diet).map((f) => f.id).toSet();
    final out = <Food>[];
    void addIfNew(Food? f) {
      if (f != null && allowed.contains(f.id) && out.every((o) => o.id != f.id))
        out.add(f);
    }

    for (final (label, _) in tracker.favouriteFoods(3)) {
      addIfNew(Catalog.foodByLabel(label));
    }
    for (final q in Catalog.quickFoods(_diet)) {
      if (out.length >= 3) break;
      addIfNew(Catalog.foodByLabel(q.name));
    }
    return out.take(3).toList();
  }

  List<(String, String)> get categories => Catalog.foodCatsFor(_diet);

  /// Search results, or the chosen category (without the usual foods).
  List<Food> get browseFoods {
    final list = Catalog.foodsFor(_diet);
    final q = query.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      return list
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                f.portion.toLowerCase().contains(q),
          )
          .toList();
    }
    final usual = usualFoods.map((f) => f.id).toSet();
    final c = category.value;
    return list
        .where((f) => !usual.contains(f.id) && (c == 'all' || f.cat == c))
        .toList();
  }

  void pickCategory(String id) {
    if (category.value == id) return;
    Haptics.instance.selectionClick();
    category.value = id;
  }

  void toggleFood(Food f) {
    Haptics.instance.selectionClick();
    portion.value = 1;
    openFood.value = openFood.value == f.id ? '' : f.id;
  }

  void pickPortion(double times) {
    Haptics.instance.selectionClick();
    portion.value = times;
  }

  int gramsFor(Food f, double times) => (f.grams * times).round();

  Future<void> addFood(Food f, [double times = 1]) async {
    final grams = gramsFor(f, times);
    final label = times == 1
        ? f.label
        : '${f.name}, ${_portionLabel(times)} × ${f.portion}';
    openFood.value = '';
    await _add('protein', grams, label, 'Added ${f.name} · $grams g');
  }

  String _portionLabel(double times) => portions
      .firstWhere(
        (p) => p.times == times,
        orElse: () => Portion(times.toString(), times),
      )
      .label;

  void stepCustom(int by) {
    Haptics.instance.selectionClick();
    customGrams.value = (customGrams.value + by).clamp(1, 200);
  }

  Future<void> typeCustom(BuildContext context) async {
    final v = await askNumber(
      context,
      title: 'Protein in grams',
      unit: 'g',
      initial: customGrams.value.toDouble(),
      min: 1,
      max: 200,
      decimals: 0,
    );
    if (v != null && !v.isNaN) customGrams.value = v.round();
  }

  Future<void> addCustomProtein() => _add(
    'protein',
    customGrams.value,
    null,
    'Added ${customGrams.value} g protein',
  );

  // ------------------------------------------------------------------ water

  int get waterGoal => profile?.waterGoalMl ?? 2500;
  int get waterToday => tracker.today.waterMl;
  double get waterProgress =>
      waterGoal == 0 ? 0 : (waterToday / waterGoal).clamp(0.0, 1.0);

  String litres(int ml) {
    final l = ml / 1000;
    final s = l.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }

  String get waterLine {
    final left = waterGoal - waterToday;
    if (left <= 0) return 'Goal reached today.';
    final glasses = (left / 250).ceil();
    return 'About $glasses more ${glasses == 1 ? 'glass' : 'glasses'} to go';
  }

  List<Drink> get otherDrinks {
    final noDairy = _diet == 'vegan';
    return Catalog.otherDrinks.where((d) => !(noDairy && d.dairy)).toList();
  }

  Future<void> addDrink(Drink d) => _add(
    'water',
    d.ml,
    d.label,
    'Added ${d.label.toLowerCase()} · ${d.ml} ml',
  );

  Future<void> addCustomWater(BuildContext context) async {
    final v = await askNumber(
      context,
      title: 'How much?',
      unit: 'ml',
      initial: 330,
      min: 50,
      max: 2000,
      decimals: 0,
    );
    if (v == null || v.isNaN) return;
    final ml = v.round();
    await _add('water', ml, null, 'Added $ml ml');
  }

  // ---------------------------------------------------------------- entries

  List<LogEntry> entriesFor(String kind) => tracker.today.entries
      .where((e) => e.kind == kind)
      .toList()
      .reversed
      .toList();

  String entryTitle(LogEntry e) {
    final l = e.label;
    if (l != null && l.isNotEmpty) return l;
    return e.isProtein ? 'Protein' : 'Water';
  }

  String timeOf(DateTime d) => Dates.time(d);

  Future<void> removeEntry(LogEntry e) async {
    Haptics.instance.lightImpact();
    await tracker.removeEntry(Dates.key(e.at), e.id);
  }

  Future<void> undoLast(String kind) async {
    final list = entriesFor(kind);
    if (list.isEmpty) return;
    await removeEntry(list.first);
    showToast('Removed');
  }

  Future<void> _add(
    String kind,
    int amount,
    String? label,
    String message,
  ) async {
    Haptics.instance.lightImpact();
    final now = DateTime.now();
    final id = kind == 'protein'
        ? await tracker.addProtein(amount, now, label)
        : await tracker.addWater(amount, now, label);
    showUndoToast(message, () async {
      Haptics.instance.selectionClick();
      await tracker.removeEntry(Dates.key(now), id);
    });
  }
}
