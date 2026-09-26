import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

enum OnboardingStep { welcome, stage, medicine, dose, frequency, schedule, treatmentStart, sex, birth, height, weight, baseline, protein, focus, plan }

/// Holds the answers while the user moves through onboarding, then saves
/// them as one [UserProfile]. In edit mode only the medicine, dose, frequency and schedule steps
/// are shown and the rest of the profile is kept.
class OnboardingController extends GetxController {
  OnboardingController({this.editMode = false});

  final bool editMode;
  final TrackerService _tracker = Get.find<TrackerService>();
  final PageController pageController = PageController();

  /// Steps for this run. Welcome is its own route now, and "Treatment
  /// start" is skipped for people who haven't started yet (their first
  /// dose date already says it). Reads [stage], so Obx callers rebuild when
  /// the first answer changes the flow.
  List<OnboardingStep> get steps {
    if (editMode) {
      return const [OnboardingStep.medicine, OnboardingStep.dose, OnboardingStep.frequency, OnboardingStep.schedule];
    }
    final starting = stage.value == 'starting';
    return [
      for (final s in OnboardingStep.values)
        if (s != OnboardingStep.welcome &&
            // Replaced by the height / weight / goal questions.
            s != OnboardingStep.baseline &&
            !(starting && s == OnboardingStep.treatmentStart))
          s,
    ];
  }

  final RxInt page = 0.obs;
  final RxBool saving = false.obs;

  // Answers, with the defaults shown in the design.

  /// 'taking', 'starting' or 'restart'. Empty until the user picks one,
  /// so nothing looks pre-selected on the first question.
  final RxString stage = ''.obs;
  /// Empty until picked, so no medicine looks pre-selected.
  final RxString medicineId = ''.obs;

  /// Name typed for "Something else".
  final RxString customMedicine = ''.obs;
  final TextEditingController customMedicineField = TextEditingController();
  final RxString form = 'pen'.obs;
  final RxDouble strength = 2.5.obs;

  /// How the dose was answered: '' (not yet), 'label' (a tile), 'custom'
  /// (typed mg) or 'unsure' (saved as 0 mg, "dose not set").
  final RxString doseMode = ''.obs;
  final RxString customDose = ''.obs;
  final TextEditingController customDoseField = TextEditingController();

  /// 'weekly', '2w', 'daily', 'custom' or 'unsure'. Pre-filled from the
  /// medicine; [frequencyAnswered] says whether the user has picked it.
  final RxString frequency = 'weekly'.obs;
  final RxBool frequencyAnswered = false.obs;
  final RxInt customDays = 3.obs;
  final RxInt shotWeekday = DateTime.sunday.obs;
  final RxInt shotMinutes = morningMinutes.obs;

  /// Roughly when treatment began: the 15th of the picked month (or today
  /// if sooner). [treatmentStartMode] is '' (not yet), 'month', 'older'
  /// (picked from the calendar) or 'skip' (rather not say).
  final Rxn<DateTime> treatmentStart = Rxn<DateTime>();
  final RxString treatmentStartMode = ''.obs;

  /// 'female', 'male', 'other', 'none' (prefer not to say), or '' until
  /// answered.
  final RxString sex = ''.obs;

  /// Date of birth wheels. Starts about 30 years back on 1 January.
  final RxInt birthYear = (DateTime.now().year - 30).obs;
  final RxInt birthMonth = 1.obs;
  final RxInt birthDay = 1.obs;

  /// Last dose (already taking) or first dose (starting / restarting).
  /// Null until picked.
  final Rxn<DateTime> doseDate = Rxn<DateTime>();

  final RxBool useKg = true.obs;
  final RxDouble weightKg = 72.0.obs;

  /// False until the user moves the weight, so the default can follow the
  /// sex answer.
  final RxBool weightTouched = false.obs;
  final RxnDouble goalKg = RxnDouble();
  final RxnDouble heightCm = RxnDouble();
  final RxBool heightInCm = true.obs;

  final RxInt proteinGoal = 100.obs;
  final RxBool proteinTouched = false.obs;
  final RxBool veg = false.obs;
  final RxSet<String> plateOff = <String>{}.obs;

  final RxSet<String> focus = <String>{'muscle', 'nausea'}.obs;

  OnboardingStep get current => steps[page.value];
  Medicine get medicine => Catalog.medicine(medicineId.value);

  /// Question steps shown in the header (the plan reveal has no header).
  int get stepCount =>
      editMode ? steps.length : steps.where((s) => s != OnboardingStep.plan).length;

  int get stepNumber => (page.value + 1).clamp(1, stepCount);

  /// 0–1 fill for the header progress bar.
  double get progress => stepNumber / stepCount;

  int get everyDays {
    switch (frequency.value) {
      case '2w':
        return 14;
      case 'daily':
        return 1;
      case 'custom':
        return customDays.value;
      case 'unsure':
        return medicine.everyDays;
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
    customMedicineField.dispose();
    customDoseField.dispose();
    super.onClose();
  }

  void _loadFrom(UserProfile p) {
    stage.value = p.stage;
    medicineId.value = p.medicineId;
    customMedicine.value = p.customMedicine ?? '';
    customMedicineField.text = customMedicine.value;
    form.value = p.form;
    strength.value = p.strengthMg;
    if (p.strengthMg <= 0) {
      doseMode.value = 'unsure';
    } else if (Catalog.medicine(p.medicineId).strengths.contains(p.strengthMg)) {
      doseMode.value = 'label';
    } else {
      doseMode.value = 'custom';
      customDose.value = Catalog.mg(p.strengthMg);
      customDoseField.text = customDose.value;
    }
    frequency.value = switch (p.everyDays) {
      7 => 'weekly',
      14 => '2w',
      1 => 'daily',
      _ => 'custom',
    };
    customDays.value = p.everyDays;
    if (p.frequencyUnsure) frequency.value = 'unsure';
    frequencyAnswered.value = true;
    shotWeekday.value = p.shotWeekday;
    shotMinutes.value = p.shotMinutes;
    treatmentStart.value = p.treatmentStartedAt;
    sex.value = p.sex ?? '';
    final born = p.birthDate;
    if (born != null) {
      birthYear.value = born.year;
      birthMonth.value = born.month;
      birthDay.value = born.day;
    }
    treatmentStartMode.value = p.treatmentStartedAt == null ? '' : 'month';
    final last = _tracker.lastDose;
    if (p.plannedFirstDose != null && last == null) {
      doseDate.value = Dates.dateOnly(p.plannedFirstDose!);
    } else if (last != null) {
      doseDate.value = Dates.dateOnly(last.takenAt);
    }
    useKg.value = p.useKg;
    weightKg.value = p.startWeightKg;
    weightTouched.value = true;
    goalKg.value = p.goalWeightKg;
    heightCm.value = p.heightCm;
    heightInCm.value = p.heightInCm;
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
    Haptics.instance.selectionClick();
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

  bool _advancing = false;

  /// Single-choice questions: show the selection and a haptic tick, pause
  /// briefly so the user sees what they picked, then move on. Taps during
  /// the pause or the page slide are ignored, so a double tap can't skip
  /// a question.
  Future<void> _pickThenNext(OnboardingStep from, void Function() apply) async {
    if (_advancing || current != from) return;
    _advancing = true;
    apply();
    Haptics.instance.selectionClick();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!isClosed && current == from) next();
    } finally {
      _advancing = false;
    }
  }

  void pickStage(String id) => _pickThenNext(OnboardingStep.stage, () => stage.value = id);

  /// Tapping a medicine selects it and moves on, except "Something else",
  /// which waits for a typed name (see [confirmCustomMedicine]).
  void pickMedicine(String id) {
    if (id == Catalog.other) {
      if (medicineId.value != id) Haptics.instance.selectionClick();
      _applyMedicine(id);
      return;
    }
    _pickThenNext(OnboardingStep.medicine, () => _applyMedicine(id));
  }

  /// Takes the medicine's usual form and schedule as a starting point. The
  /// dose and how-often questions that follow let the user change both.
  void _applyMedicine(String id) {
    final changed = medicineId.value != id;
    medicineId.value = id;
    final m = medicine;
    if (m.strengths.isNotEmpty && !m.strengths.contains(strength.value)) {
      strength.value = m.strengths.first;
    }
    // A dose picked for another medicine shouldn't look answered.
    if (changed && doseMode.value == 'label') doseMode.value = '';
    form.value = m.form;
    frequency.value = m.everyDays == 1 ? 'daily' : 'weekly';
    if (changed) frequencyAnswered.value = false;
  }

  static const int customMedicineMaxLength = 40;

  bool get customMedicineValid => customMedicine.value.trim().isNotEmpty;

  void setCustomMedicine(String v) => customMedicine.value = v;

  void confirmCustomMedicine() {
    if (!customMedicineValid || current != OnboardingStep.medicine) return;
    customMedicine.value = customMedicine.value.trim();
    FocusManager.instance.primaryFocus?.unfocus();
    Haptics.instance.lightImpact();
    next();
  }

  /// Called from KSegmented, which already gives the haptic tick.
  void pickForm(String id) {
    form.value = id;
    if (id == 'tablet') frequency.value = 'daily';
  }

  // ------------------------------------------------------------- frequency

  static const int minCustomDays = 2;
  static const int maxCustomDays = 30;

  /// Daily, weekly, every 2 weeks and "I don't know yet" answer and move
  /// on. "Another schedule" opens the every-N-days stepper instead.
  void pickFrequency(String id) {
    if (id == 'custom') {
      if (!(frequencyAnswered.value && frequency.value == 'custom')) Haptics.instance.selectionClick();
      frequency.value = 'custom';
      frequencyAnswered.value = true;
      return;
    }
    _pickThenNext(OnboardingStep.frequency, () {
      frequency.value = id;
      frequencyAnswered.value = true;
    });
  }

  void stepCustomDays(int delta) {
    final v = (customDays.value + delta).clamp(minCustomDays, maxCustomDays);
    if (v == customDays.value) return;
    customDays.value = v;
    Haptics.instance.selectionClick();
  }

  void confirmCustomFrequency() {
    if (frequency.value != 'custom' || current != OnboardingStep.frequency) return;
    Haptics.instance.lightImpact();
    next();
  }

  // ---------------------------------------------------------- day & time

  static const int morningMinutes = 8 * 60;
  static const int afternoonMinutes = 13 * 60;
  static const int eveningMinutes = 20 * 60;
  static const List<int> timePresets = [morningMinutes, afternoonMinutes, eveningMinutes];

  /// Already taking: we ask for the last dose. Starting or restarting: the
  /// first dose.
  bool get asksLastDose => stage.value.isEmpty || stage.value == 'taking';

  /// Daily medicine and already taking: only the time matters.
  bool get needsDoseDate => !(asksLastDose && everyDays == 1);

  bool get scheduleReady => !needsDoseDate || doseDate.value != null;

  void pickDoseDate(DateTime day) {
    final d = Dates.dateOnly(day);
    if (doseDate.value != d) Haptics.instance.selectionClick();
    doseDate.value = d;
    shotWeekday.value = d.weekday;
  }

  void pickDoseTime(int minutes) {
    if (shotMinutes.value != minutes) Haptics.instance.selectionClick();
    shotMinutes.value = minutes.clamp(0, 1439);
  }

  /// Preview for the "Next dose" card, or null until there's enough to say.
  DateTime? get nextDosePreview {
    final today = Dates.dateOnly(DateTime.now());
    final every = everyDays;
    DateTime day;
    if (!needsDoseDate) {
      final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
      day = nowMinutes < shotMinutes.value ? today : today.add(const Duration(days: 1));
    } else {
      final picked = doseDate.value;
      if (picked == null) return null;
      if (asksLastDose) {
        day = picked.add(Duration(days: every));
        // Last dose long ago: the next one is due today, not in the past.
        if (day.isBefore(today)) day = today;
      } else {
        day = picked;
      }
    }
    return day.add(Duration(minutes: shotMinutes.value));
  }

  void confirmSchedule() {
    if (!scheduleReady || current != OnboardingStep.schedule) return;
    Haptics.instance.lightImpact();
    next();
  }

  // ------------------------------------------------------- treatment start

  /// Middle of [month], or today if that is still ahead.
  static DateTime approxStart(DateTime month) {
    final today = Dates.dateOnly(DateTime.now());
    final mid = DateTime(month.year, month.month, 15);
    return mid.isAfter(today) ? today : mid;
  }

  /// "Week 16" style count: week 1 is the first seven days.
  static int weekNumber(DateTime start, [DateTime? now]) {
    final days = Dates.daysBetween(start, now ?? DateTime.now());
    return days < 0 ? 1 : days ~/ 7 + 1;
  }

  void pickStartMonth(DateTime month) => _pickThenNext(OnboardingStep.treatmentStart, () {
        treatmentStart.value = approxStart(month);
        treatmentStartMode.value = 'month';
      });

  void pickStartOlder(DateTime month) => _pickThenNext(OnboardingStep.treatmentStart, () {
        treatmentStart.value = approxStart(month);
        treatmentStartMode.value = 'older';
      });

  void skipStart() => _pickThenNext(OnboardingStep.treatmentStart, () {
        treatmentStart.value = null;
        treatmentStartMode.value = 'skip';
      });

  // ------------------------------------------------------------------- sex

  void pickSex(String id) => _pickThenNext(OnboardingStep.sex, () {
        sex.value = id;
        _defaultWeightFromSex();
      });

  // ---------------------------------------------------------- date of birth

  static const int adultAge = 18;
  static const int oldestYears = 100;

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime get birthDate => DateTime(birthYear.value, birthMonth.value, birthDay.value);

  int get age {
    final now = DateTime.now();
    var years = now.year - birthYear.value;
    final hadBirthday = now.month > birthMonth.value || (now.month == birthMonth.value && now.day >= birthDay.value);
    if (!hadBirthday) years--;
    return years;
  }

  bool get isAdult => age >= adultAge;

  /// Wheels call these while scrolling; each new value gets a light tick.
  /// The day is clamped so 31 → 30 when moving to a shorter month.
  void setBirthDay(int d) => _setBirth(day: d);
  void setBirthMonth(int m) => _setBirth(month: m);
  void setBirthYear(int y) => _setBirth(year: y);

  void _setBirth({int? day, int? month, int? year}) {
    final y = year ?? birthYear.value;
    final m = month ?? birthMonth.value;
    final d = (day ?? birthDay.value).clamp(1, daysInMonth(y, m));
    if (y == birthYear.value && m == birthMonth.value && d == birthDay.value) return;
    Haptics.instance.selectionClick();
    birthYear.value = y;
    birthMonth.value = m;
    birthDay.value = d;
  }

  void confirmBirth() {
    if (!isAdult || current != OnboardingStep.birth) return;
    Haptics.instance.lightImpact();
    next();
  }

  // ---------------------------------------------------------------- height

  static const double minHeightCm = 120;
  static const double maxHeightCm = 230;

  /// Starting point for the ruler before the user moves it.
  double get defaultHeightCm => switch (sex.value) {
        'female' => 162,
        'male' => 175,
        _ => 168,
      };

  double get heightShownCm => heightCm.value ?? defaultHeightCm;

  void setHeightCm(double cm) => heightCm.value = cm.clamp(minHeightCm, maxHeightCm);

  void confirmHeight() {
    if (current != OnboardingStep.height) return;
    heightCm.value ??= defaultHeightCm;
    Haptics.instance.lightImpact();
    next();
  }

  // ------------------------------------------------------------------ dose

  void pickDose(double mg) => _pickThenNext(OnboardingStep.dose, () {
        strength.value = mg;
        doseMode.value = 'label';
      });

  void pickDoseUnsure() => _pickThenNext(OnboardingStep.dose, () => doseMode.value = 'unsure');

  /// Opens the mg field; the user confirms with [confirmCustomDose].
  void pickCustomDose() {
    if (doseMode.value != 'custom') Haptics.instance.selectionClick();
    doseMode.value = 'custom';
  }

  void setCustomDose(String v) => customDose.value = v;

  /// Typed mg, accepting "3,75" as well as "3.75". Null when not a sensible
  /// amount (above 0 and at most 100 mg).
  double? get customDoseMg {
    final v = double.tryParse(customDose.value.trim().replaceAll(',', '.'));
    if (v == null || v <= 0 || v > 100) return null;
    return (v * 1000).round() / 1000;
  }

  void confirmCustomDose() {
    final mg = customDoseMg;
    if (mg == null || current != OnboardingStep.dose) return;
    strength.value = mg;
    FocusManager.instance.primaryFocus?.unfocus();
    Haptics.instance.lightImpact();
    next();
  }

  double get _savedStrength => doseMode.value == 'unsure' ? 0 : strength.value;

  static const double minWeightKg = 30;
  static const double maxWeightKg = 300;

  void stepWeight(double deltaKg) => setWeight(weightKg.value + deltaKg);

  void setWeight(double kg) {
    weightTouched.value = true;
    weightKg.value = (kg.clamp(minWeightKg, maxWeightKg) * 100).round() / 100;
  }

  /// Ruler start before the user touches it.
  void _defaultWeightFromSex() {
    if (weightTouched.value) return;
    weightKg.value = switch (sex.value) {
      'female' => 68,
      'male' => 80,
      _ => 72,
    };
  }

  void confirmWeight() {
    if (current != OnboardingStep.weight) return;
    weightTouched.value = true;
    Haptics.instance.lightImpact();
    next();
  }

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

  String? get _customMedicineOrNull =>
      medicineId.value == Catalog.other && customMedicineValid ? customMedicine.value.trim() : null;

  UserProfile _build({required bool remindersOn}) {
    final old = _tracker.profile.value;
    if (editMode && old != null) {
      return old.copyWith(
        medicineId: medicineId.value,
        customMedicine: _customMedicineOrNull,
        form: form.value,
        strengthMg: _savedStrength,
        everyDays: everyDays,
        frequencyUnsure: frequency.value == 'unsure',
        shotWeekday: shotWeekday.value,
        shotMinutes: shotMinutes.value,
      );
    }
    return UserProfile(
      stage: stage.value.isEmpty ? 'taking' : stage.value,
      medicineId: medicineId.value,
      customMedicine: _customMedicineOrNull,
      form: form.value,
      strengthMg: _savedStrength,
      everyDays: everyDays,
      frequencyUnsure: frequency.value == 'unsure',
      shotWeekday: shotWeekday.value,
      shotMinutes: shotMinutes.value,
      plannedFirstDose: asksLastDose ? null : doseDate.value,
      treatmentStartedAt: stage.value == 'starting' ? doseDate.value : treatmentStart.value,
      sex: sex.value.isEmpty ? null : sex.value,
      birthDate: birthDate,
      heightInCm: heightInCm.value,
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

  /// Already taking: the last dose they told us about becomes the first
  /// entry in their log, so "next dose" and week counts start from it.
  Future<void> _logLastDose() async {
    final day = doseDate.value;
    if (!asksLastDose || day == null) return;
    await _tracker.addDose(
      takenAt: day.add(Duration(minutes: shotMinutes.value)),
      site: '',
    );
  }

  Future<void> finish({bool remindersOn = false}) async {
    if (saving.value) return;
    saving.value = true;
    try {
      final profile = _build(remindersOn: remindersOn);
      await _tracker.saveProfile(profile);
      if (!editMode) {
        await _tracker.addWeight(profile.startWeightKg);
        await _logLastDose();
      }
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
