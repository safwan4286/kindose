import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/routes.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

enum OnboardingStep { welcome, stage, medicine, dose, baseline, protein, focus, plan }

/// Holds the answers while the user moves through onboarding, then saves
/// them as one [UserProfile]. In edit mode only the medicine and dose steps
/// are shown and the rest of the profile is kept.
class OnboardingController extends GetxController {
  OnboardingController({this.editMode = false});

  final bool editMode;
  final TrackerService _tracker = Get.find<TrackerService>();
  final PageController pageController = PageController();

  late final List<OnboardingStep> steps = editMode
      ? const [OnboardingStep.medicine, OnboardingStep.dose]
      // Welcome is now its own route (features/welcome), so onboarding
      // starts at the first question.
      : OnboardingStep.values.where((s) => s != OnboardingStep.welcome).toList();

  final RxInt page = 0.obs;
  final RxBool saving = false.obs;

  // Answers, with the defaults shown in the design.
  final RxString stage = 'taking'.obs;
  final RxString medicineId = 'mounjaro'.obs;
  final RxString form = 'pen'.obs;
  final RxDouble strength = 2.5.obs;

  /// 'weekly', '2w', 'daily' or 'custom'
  final RxString frequency = 'weekly'.obs;
  final RxInt customDays = 3.obs;
  final RxInt shotWeekday = DateTime.sunday.obs;
  final RxInt shotMinutes = 540.obs;

  final RxBool useKg = true.obs;
  final RxDouble weightKg = 85.0.obs;
  final RxnDouble goalKg = RxnDouble();
  final RxnDouble heightCm = RxnDouble();

  final RxInt proteinGoal = 100.obs;
  final RxBool proteinTouched = false.obs;
  final RxBool veg = false.obs;
  final RxSet<String> plateOff = <String>{}.obs;

  final RxSet<String> focus = <String>{'muscle', 'nausea'}.obs;

  OnboardingStep get current => steps[page.value];
  Medicine get medicine => Catalog.medicine(medicineId.value);

  /// Step number for the "n/6" header, or 0 when the header is hidden.
  int get stepNumber {
    if (editMode) return page.value + 1;
    const counted = [
      OnboardingStep.stage,
      OnboardingStep.medicine,
      OnboardingStep.dose,
      OnboardingStep.baseline,
      OnboardingStep.protein,
      OnboardingStep.focus,
    ];
    return counted.indexOf(current) + 1;
  }

  int get stepCount => editMode ? steps.length : 6;

  int get everyDays {
    switch (frequency.value) {
      case '2w':
        return 14;
      case 'daily':
        return 1;
      case 'custom':
        return customDays.value;
      default:
        return 7;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final p = _tracker.profile.value;
    if (p != null) _loadFrom(p);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void _loadFrom(UserProfile p) {
    stage.value = p.stage;
    medicineId.value = p.medicineId;
    form.value = p.form;
    strength.value = p.strengthMg;
    frequency.value = switch (p.everyDays) {
      7 => 'weekly',
      14 => '2w',
      1 => 'daily',
      _ => 'custom',
    };
    customDays.value = p.everyDays;
    shotWeekday.value = p.shotWeekday;
    shotMinutes.value = p.shotMinutes;
    useKg.value = p.useKg;
    weightKg.value = p.startWeightKg;
    goalKg.value = p.goalWeightKg;
    heightCm.value = p.heightCm;
    proteinGoal.value = p.proteinGoalG;
    proteinTouched.value = true;
    veg.value = p.vegDiet;
    focus.assignAll(p.focus);
  }

  // ------------------------------------------------------------ navigation

  void next() {
    if (page.value >= steps.length - 1) {
      finish();
      return;
    }
    if (steps[page.value + 1] == OnboardingStep.protein && !proteinTouched.value) {
      proteinGoal.value = suggestedProtein;
    }
    _go(page.value + 1);
  }

  void back() {
    if (page.value == 0) {
      popRoute();
      return;
    }
    _go(page.value - 1);
  }

  void _go(int index) {
    page.value = index;
    if (!pageController.hasClients) return;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // --------------------------------------------------------------- answers

  void pickMedicine(String id) {
    medicineId.value = id;
    final m = medicine;
    if (!m.strengths.contains(strength.value)) strength.value = m.strengths.first;
    if (m.isTablet) {
      form.value = 'tablet';
      frequency.value = 'daily';
    } else {
      if (form.value == 'tablet') form.value = 'pen';
      if (frequency.value == 'daily') frequency.value = 'weekly';
    }
  }

  void pickForm(String id) {
    form.value = id;
    if (id == 'tablet') frequency.value = 'daily';
  }

  void stepWeight(double deltaKg) {
    final v = (weightKg.value + deltaKg).clamp(30.0, 300.0);
    weightKg.value = (v * 100).round() / 100;
  }

  void setWeight(double kg) => weightKg.value = (kg.clamp(30.0, 300.0) * 100).round() / 100;

  /// 1.2 g per kg rounded to 5 g, a common general guideline shown as a
  /// starting point the user can change.
  int get suggestedProtein {
    final g = (weightKg.value * 1.2 / 5).round() * 5;
    return g.clamp(60, 180);
  }

  void setProteinGoal(double v) {
    proteinTouched.value = true;
    proteinGoal.value = (v / 5).round() * 5;
  }

  void setVeg(bool v) {
    veg.value = v;
    plateOff.clear();
  }

  void toggleFood(String id) {
    if (plateOff.contains(id)) {
      plateOff.remove(id);
    } else {
      plateOff.add(id);
    }
  }

  List<Food> get plateFoods => veg.value ? Catalog.vegFoods : Catalog.everydayFoods;

  int get plateTotal => plateFoods
      .where((f) => !plateOff.contains(f.id))
      .fold<int>(0, (sum, f) => sum + f.grams);

  void toggleFocus(String id) {
    if (focus.contains(id)) {
      focus.remove(id);
    } else {
      focus.add(id);
    }
  }

  double? get bmi {
    final h = heightCm.value;
    if (h == null || h <= 0) return null;
    final m = h / 100;
    return weightKg.value / (m * m);
  }

  // ------------------------------------------------------------------ save

  UserProfile _build({required bool remindersOn}) {
    final old = _tracker.profile.value;
    if (editMode && old != null) {
      return old.copyWith(
        medicineId: medicineId.value,
        form: form.value,
        strengthMg: strength.value,
        everyDays: everyDays,
        shotWeekday: shotWeekday.value,
        shotMinutes: shotMinutes.value,
      );
    }
    return UserProfile(
      stage: stage.value,
      medicineId: medicineId.value,
      form: form.value,
      strengthMg: strength.value,
      everyDays: everyDays,
      shotWeekday: shotWeekday.value,
      shotMinutes: shotMinutes.value,
      useKg: useKg.value,
      startWeightKg: weightKg.value,
      goalWeightKg: goalKg.value,
      heightCm: heightCm.value,
      proteinGoalG: proteinGoal.value,
      waterGoalMl: 2500,
      vegDiet: veg.value,
      focus: focus.toList(),
      remindersOn: remindersOn,
      startedAt: DateTime.now(),
    );
  }

  /// Plan preview for the last screen, built from current answers.
  UserProfile get draft => _build(remindersOn: false);

  Future<void> finish({bool remindersOn = false}) async {
    if (saving.value) return;
    saving.value = true;
    try {
      final profile = _build(remindersOn: remindersOn);
      await _tracker.saveProfile(profile);
      if (!editMode) await _tracker.addWeight(profile.startWeightKg);
      if (editMode) {
        popRoute();
      } else {
        Get.offAllNamed<void>(Routes.plus, arguments: true);
      }
    } finally {
      saving.value = false;
    }
  }
}
