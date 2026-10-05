import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/plus_access.dart';
import '../common/day_nav.dart';
import '../today/next_bite.dart';
import '../today/today_controller.dart';
import '../../resources/images.dart';
import '../../resources/water_units.dart';
import 'widgets/protein_sheets.dart';
import '../../services/tracker_service.dart';
import '../../widgets/ask_number.dart';
import '../../widgets/toast.dart';

/// A serving size on the portion chips.
class Portion {
  const Portion(this.label, this.times);

  final String label;
  final double times;
}

/// Protein or water for one day (today by default). Open with 'protein'
/// or 'water' as the route argument. Every add is one tap and can be
/// undone. Past days: the last 4 weeks free, older with Plus.
class IntakeController extends GetxController with DayNav {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController searchCtrl = TextEditingController();

  static const List<Portion> portions = [
    Portion('½', 0.5),
    Portion('1', 1),
    Portion('1½', 1.5),
    Portion('2', 2),
    Portion('3', 3),
  ];

  /// Route argument: 'protein' / 'water', or {'kind': ..., 'day': DateTime}.
  static String _kindOf(Object? a) =>
      (a is Map ? a['kind'] : a) == 'water' ? 'water' : 'protein';

  late final RxString tab = _kindOf(Get.arguments).obs;
  final RxString query = ''.obs;
  final RxString category = 'all'.obs;

  /// Servings chosen in the portion sheet.
  final RxDouble portion = 1.0.obs;
  final RxInt customGrams = 20.obs;

  /// Protein screen section: 'sug' (Next bite + usual), 'mine', 'all'.
  final RxString section = 'sug'.obs;

  /// Today's protein list open inside the top card.
  final RxBool logOpen = false.obs;

  // Custom sheet: optional name and portion, save to My foods.
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController portionCtrl = TextEditingController();
  final RxBool saveCustom = true.obs;

  /// Id of the saved food open in the custom sheet, '' when adding new.
  final RxString editingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final a = Get.arguments;
    if (a is Map) initDay(a['day']);
    if (!isToday) section.value = 'all';
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    nameCtrl.dispose();
    portionCtrl.dispose();
    super.onClose();
  }

  UserProfile? get profile => tracker.profile.value;
  bool get isProtein => tab.value == 'protein';

  void setTab(String t) => tab.value = t;

  /// Reads every Rx the screen depends on (call at the top of an Obx).
  void watch() {
    tracker.days.length;
    tracker.today;
    day.value;
    PlusAccess.unlocked;
    tab.value;
    query.value;
    category.value;
    portion.value;
    customGrams.value;
    section.value;
    logOpen.value;
    saveCustom.value;
    editingId.value;
    tracker.myFoods.length;
    _today?.biteAdded.length;
  }

  // -------------------------------------------------------------------- day

  DayLog get dayLog => tracker.dayLog(day.value);

  @override
  void onDayChanged() {
    logOpen.value = false;
    if (!isToday && section.value == 'sug') section.value = 'all';
  }

  // ---------------------------------------------------------------- protein

  int get proteinGoal => profile?.proteinGoalG ?? 100;
  int get proteinToday => dayLog.proteinG;
  int get proteinLeft => (proteinGoal - proteinToday).clamp(0, 999);
  double get proteinProgress =>
      proteinGoal == 0 ? 0 : (proteinToday / proteinGoal).clamp(0.0, 1.0);

  String get proteinLine {
    final left = proteinLeft;
    if (left == 0)
      return isToday
          ? 'Goal reached today. Nice work.'
          : 'Goal reached that day.';
    if (!isToday) return '$left g short of the goal that day';
    final meals = (left / 25).ceil();
    return '$left g to go · about $meals protein-first ${meals == 1 ? 'meal' : 'meals'}';
  }

  String? get _diet => profile?.diet;

  /// "VEGETARIAN" etc. for the browse title, or null for everyone.
  String? get dietName => switch (_diet) {
    'veg' || 'egg' || 'jain' => 'Vegetarian',
    'pesc' => 'Pescatarian',
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

  // ------------------------------------------------------------- sections

  TodayController? get _today =>
      Get.isRegistered<TodayController>() ? Get.find<TodayController>() : null;

  /// Suggestions only make sense for today.
  bool get hasSuggested => isToday && _today != null;

  List<String> get sections => [if (hasSuggested) 'sug', 'mine', 'all'];

  /// The section on screen (falls back when Suggested is not offered).
  String get currentSection =>
      sections.contains(section.value) ? section.value : 'all';

  static String sectionName(String id) => switch (id) {
    'sug' => 'Suggested',
    'mine' => 'My foods',
    _ => 'All foods',
  };

  void pickSection(String id) => section.value = id;

  // ------------------------------------------------------------ next bite

  NextBite? get bite => hasSuggested ? _today?.nextBite : null;
  bool get biteUnlocked => _today?.biteUnlocked ?? false;

  /// 3 ideas with Plus, 1 without.
  List<BiteIdea> get biteIdeas =>
      (bite?.ideas ?? const <BiteIdea>[]).take(biteUnlocked ? 3 : 1).toList();

  Future<void> addIdea(BiteIdea idea) async => _today?.addBite(idea);

  void showBiteWhy() {
    final b = bite;
    if (b != null) _today?.showBiteWhy(b);
  }

  void openPlus() => _today?.openPlusFromBite();

  // ------------------------------------------------------------- browsing

  List<(String, String)> get categories => Catalog.foodCatsFor(_diet);

  /// Your saved foods first, then the library.
  List<Food> get searchResults {
    final q = query.value.trim().toLowerCase();
    bool hit(Food f) =>
        f.name.toLowerCase().contains(q) || f.portion.toLowerCase().contains(q);
    return [
      ...tracker.myFoods.where(hit),
      ...Catalog.foodsFor(_diet).where(hit),
    ];
  }

  /// All foods: one group per category, or just the chosen one.
  List<(String, List<Food>)> get foodGroups {
    final list = Catalog.foodsFor(_diet);
    final c = category.value;
    return [
      for (final (id, label) in categories)
        if (id != 'all' && (c == 'all' || c == id))
          (label, list.where((f) => f.cat == id).toList()),
    ].where((g) => g.$2.isNotEmpty).toList();
  }

  void pickCategory(String id) {
    if (category.value == id) return;
    Haptics.instance.selectionClick();
    category.value = id;
  }

  // -------------------------------------------------------- adding foods

  int gramsFor(Food f, double times) => (f.grams * times).round();

  String _portionLabel(double times) => portions
      .firstWhere(
        (p) => p.times == times,
        orElse: () => Portion(times.toString(), times),
      )
      .label;

  /// Log label for [times] servings of [f].
  String labelFor(Food f, double times) {
    if (times == 1) return f.label;
    final p = _portionLabel(times);
    return f.portion.isEmpty
        ? '${f.name} × $p'
        : '${f.name}, $p × ${f.portion}';
  }

  Future<void> addFood(Food f, [double times = 1]) async {
    final grams = gramsFor(f, times);
    await _add(
      'protein',
      grams,
      labelFor(f, times),
      'Added ${f.name} · $grams g',
    );
  }

  /// Tap on a food row: choose ½ to 3 servings.
  void openPortion(Food f) {
    Haptics.instance.selectionClick();
    portion.value = 1;
    showPortionSheet(f);
  }

  void pickPortion(double times) {
    Haptics.instance.selectionClick();
    portion.value = times;
  }

  // ---------------------------------------------------- removing entries

  List<LogEntry> get proteinEntries => entriesFor('protein');

  /// Newest protein entry of the day, shown with Undo in the top card.
  LogEntry? get lastProtein {
    final list = proteinEntries;
    return list.isEmpty ? null : list.first;
  }

  void toggleLog() {
    Haptics.instance.selectionClick();
    logOpen.toggle();
  }

  bool _isOf(LogEntry e, Food f) {
    final l = e.label;
    if (!e.isProtein || l == null) return false;
    if (l == f.label) return true;
    return f.portion.isEmpty
        ? l.startsWith('${f.name} × ')
        : l.startsWith('${f.name}, ') && l.endsWith('× ${f.portion}');
  }

  /// How many times [f] was logged on this day (any serving size).
  int countOf(Food f) => proteinEntries.where((e) => _isOf(e, f)).length;

  /// The "−" on a food row: removes its newest entry.
  Future<void> removeOneOf(Food f) async {
    final e = proteinEntries.firstWhereOrNull((e) => _isOf(e, f));
    if (e != null) await removeWithUndo(e);
  }

  /// Removes [e] and offers Undo, which puts it back at the same time.
  Future<void> removeWithUndo(LogEntry e) async {
    await removeEntry(e);
    if (isToday) _today?.forgetBite(e.label);
    final title = entryTitle(e);
    showUndoToast('Removed $title', () async {
      Haptics.instance.selectionClick();
      if (e.isProtein) {
        await tracker.addProtein(e.amount, e.at, e.label);
      } else {
        await tracker.addWater(e.amount, e.at, e.label);
      }
    });
  }

  // --------------------------------------------------------- custom food

  bool get editing => editingId.value.isNotEmpty;

  /// "+ Custom", or "Add it as your own" with the search text as the name.
  void openCustom({String name = ''}) {
    Haptics.instance.selectionClick();
    editingId.value = '';
    nameCtrl.text = name;
    portionCtrl.clear();
    customGrams.value = 20;
    saveCustom.value = true;
    showCustomFoodSheet();
  }

  /// Long-press on a saved food.
  void editMyFood(Food f) {
    Haptics.instance.mediumImpact();
    editingId.value = f.id;
    nameCtrl.text = f.name;
    portionCtrl.text = f.portion;
    customGrams.value = f.grams;
    showCustomFoodSheet();
  }

  void setCustom(int grams) {
    Haptics.instance.selectionClick();
    customGrams.value = grams.clamp(1, 200);
  }

  void stepCustom(int by) => setCustom(customGrams.value + by);

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

  void toggleSaveCustom() {
    Haptics.instance.selectionClick();
    saveCustom.toggle();
  }

  /// Why the sheet can't be submitted yet, or null.
  String? get customProblem => editing && nameCtrl.text.trim().isEmpty
      ? 'Give it a name to save it'
      : null;

  /// Adds the custom amount (and saves it when asked), or saves an edit.
  /// The sheet closes itself first, so a double tap can't add twice.
  Future<void> submitCustom() async {
    final name = nameCtrl.text.trim();
    final portionText = portionCtrl.text.trim();
    final grams = customGrams.value;
    if (editing) {
      await tracker.saveMyFood(
        Food(
          editingId.value,
          name,
          grams,
          Img3d.bowl,
          portion: portionText,
          cat: 'mine',
        ),
      );
      Haptics.instance.lightImpact();
      showToast('Saved $name');
      return;
    }
    if (name.isNotEmpty && saveCustom.value) {
      final id = 'my${DateTime.now().microsecondsSinceEpoch}';
      await tracker.saveMyFood(
        Food(id, name, grams, Img3d.bowl, portion: portionText, cat: 'mine'),
      );
    }
    final label = name.isEmpty
        ? null
        : (portionText.isEmpty ? name : '$name, $portionText');
    await _add(
      'protein',
      grams,
      label,
      name.isEmpty ? 'Added $grams g protein' : 'Added $name · $grams g',
    );
  }

  /// "Delete" in the edit sheet. Undo saves it back.
  Future<void> deleteEditing() async {
    final f = tracker.myFoods.firstWhereOrNull((x) => x.id == editingId.value);
    if (f == null) return;
    await tracker.removeMyFood(f.id);
    Haptics.instance.lightImpact();
    showUndoToast('Deleted ${f.name}', () async {
      Haptics.instance.selectionClick();
      await tracker.saveMyFood(f);
    });
  }

  // ------------------------------------------------------------------ water

  int get waterGoal => profile?.waterGoalMl ?? 2500;
  int get waterToday => dayLog.waterMl;
  double get waterProgress =>
      waterGoal == 0 ? 0 : (waterToday / waterGoal).clamp(0.0, 1.0);

  /// Number only ("1.25" or "42"); the unit is [Water.unit].
  String litres(int ml) => Water.total(ml);

  String get waterLine {
    final left = waterGoal - waterToday;
    if (left <= 0)
      return isToday ? 'Goal reached today.' : 'Goal reached that day.';
    if (!isToday) return '${Water.amount(left)} short of the goal that day';
    final glasses = (left / Water.glassMl).ceil();
    return 'About $glasses more ${glasses == 1 ? 'glass' : 'glasses'} to go';
  }

  List<Drink> get otherDrinks {
    final noDairy = _diet == 'vegan';
    return Catalog.otherDrinks.where((d) => !(noDairy && d.dairy)).toList();
  }

  Future<void> addDrink(Drink d) {
    final ml = d.mlFor(Water.oz);
    return _add(
      'water',
      ml,
      d.label,
      'Added ${d.label.toLowerCase()} · ${Water.amount(ml)}',
    );
  }

  Future<void> addCustomWater(BuildContext context) async {
    final oz = Water.oz;
    final v = await askNumber(
      context,
      title: 'How much?',
      unit: oz ? 'fl oz' : 'ml',
      initial: oz ? 12 : 330,
      min: oz ? 2 : 50,
      max: oz ? 68 : 2000,
      decimals: 0,
    );
    if (v == null || v.isNaN) return;
    final ml = oz ? Water.fromOz(v) : v.round();
    await _add('water', ml, null, 'Added ${Water.amount(ml)}');
  }

  // ---------------------------------------------------------------- entries

  List<LogEntry> entriesFor(String kind) =>
      dayLog.entries.where((e) => e.kind == kind).toList().reversed.toList();

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
    // Past days get the entry at the current time of day on that date.
    final clock = DateTime.now();
    final d = day.value;
    final at = isToday
        ? clock
        : DateTime(d.year, d.month, d.day, clock.hour, clock.minute);
    final id = kind == 'protein'
        ? await tracker.addProtein(amount, at, label)
        : await tracker.addWater(amount, at, label);
    final text = isToday ? message : '$message · ${Dates.short(d)}';
    showUndoToast(text, () async {
      Haptics.instance.selectionClick();
      await tracker.removeEntry(Dates.key(at), id);
    });
  }
}
