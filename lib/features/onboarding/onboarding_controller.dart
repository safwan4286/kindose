import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/social_button.dart';
import '../../widgets/toast.dart';

enum OnboardingStep {
  welcome,
  stage,
  medicine,
  dose,
  frequency,
  schedule,
  treatmentStart,
  sex,
  birth,
  height,
  weight,
  goal,
  activity,
  diet,
  baseline,
  protein,
  focus,
  reminders,
  building,
  plan,
  save,
}

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
      return const [
        OnboardingStep.medicine,
        OnboardingStep.dose,
        OnboardingStep.frequency,
        OnboardingStep.schedule,
      ];
    }
    final starting = stage.value == 'starting';
    return [
      for (final s in OnboardingStep.values)
        if (s != OnboardingStep.welcome &&
            // Replaced by the height / weight / goal questions.
            s != OnboardingStep.baseline &&
            // The protein goal is now worked out and shown on the plan.
            s != OnboardingStep.protein &&
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

  /// Ruler value on the goal question. Starts at about 90% of today's
  /// weight; saved to [goalKg] only on Continue (Skip leaves it null).
  final RxDouble goalDraftKg = 65.0.obs;
  final RxBool goalTouched = false.obs;

  /// 'sed', 'light', 'mod', 'active', 'athlete', or '' until answered.
  final RxString activity = ''.obs;
  final RxnDouble heightCm = RxnDouble();
  final RxBool heightInCm = true.obs;

  final RxInt proteinGoal = 100.obs;
  final RxBool proteinTouched = false.obs;

  /// Daily water in ml once the user edits it on the plan; until then the
  /// suggestion from weight and activity is used.
  final RxInt waterGoal = 2500.obs;
  final RxBool waterTouched = false.obs;

  /// Set when "Edit" on the plan sends the user back to the dose questions,
  /// so the schedule screen returns straight to the plan.
  bool _returnToPlan = false;
  final RxBool veg = false.obs;

  /// 'veg', 'egg', 'nonveg', 'vegan', 'jain', or '' until answered.
  final RxString diet = ''.obs;

  /// Set on the reminders screen: true only when the system said yes.
  final RxBool remindersOn = false.obs;
  final RxBool askingReminders = false.obs;
  final RxSet<String> plateOff = <String>{}.obs;

  /// What the user wants help with. Empty until they pick (Continue needs one).
  final RxSet<String> focus = <String>{}.obs;

  OnboardingStep get current => steps[page.value];
  Medicine get medicine => Catalog.medicine(medicineId.value);

  /// Question steps shown in the header (the plan reveal has no header).
  int get stepCount =>
      editMode ? steps.length : steps.where((s) => !_wrapUp.contains(s)).length;

  /// Screens after the questions: no progress bar, just the back button.
  static const Set<OnboardingStep> _wrapUp = {
    OnboardingStep.reminders,
    OnboardingStep.building,
    OnboardingStep.plan,
    OnboardingStep.save,
  };

  bool get isWrapUp => _wrapUp.contains(current);

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
    } else if (Catalog.medicine(
      p.medicineId,
    ).strengths.contains(p.strengthMg)) {
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
    if (p.goalWeightKg != null) {
      goalDraftKg.value = p.goalWeightKg!;
      goalTouched.value = true;
    }
    heightCm.value = p.heightCm;
    heightInCm.value = p.heightInCm;
    activity.value = p.activity ?? '';
    proteinGoal.value = p.proteinGoalG;
    proteinTouched.value = true;
    waterGoal.value = p.waterGoalMl;
    waterTouched.value = true;
    veg.value = p.vegDiet;
    diet.value = p.diet ?? '';
    focus.assignAll(p.focus);
  }

  // ------------------------------------------------------------ navigation

  void next() {
    if (_returnToPlan && current == OnboardingStep.schedule) {
      _returnToPlan = false;
      _go(steps.indexOf(OnboardingStep.plan));
      return;
    }
    if (page.value >= steps.length - 1) {
      finish();
      return;
    }
    if (steps[page.value + 1] == OnboardingStep.protein &&
        !proteinTouched.value) {
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
    var to = page.value - 1;
    // The "building" moment plays once; going back from the plan skips it.
    if (to > 0 && steps[to] == OnboardingStep.building) to--;
    _go(to);
  }

  void _go(int index) {
    final from = page.value;
    page.value = index;
    if (!pageController.hasClients) return;
    // Long jumps (plan ⇄ dose edit) skip the pages in between, then slide
    // the last step so it still feels like normal navigation.
    if ((index - from).abs() > 1) {
      pageController.jumpToPage(index > from ? index - 1 : index + 1);
    }
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

  void pickStage(String id) =>
      _pickThenNext(OnboardingStep.stage, () => stage.value = id);

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
      if (!(frequencyAnswered.value && frequency.value == 'custom'))
        Haptics.instance.selectionClick();
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
    if (frequency.value != 'custom' || current != OnboardingStep.frequency)
      return;
    Haptics.instance.lightImpact();
    next();
  }

  // ---------------------------------------------------------- day & time

  static const int morningMinutes = 8 * 60;
  static const int afternoonMinutes = 13 * 60;
  static const int eveningMinutes = 20 * 60;
  static const List<int> timePresets = [
    morningMinutes,
    afternoonMinutes,
    eveningMinutes,
  ];

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
      day = nowMinutes < shotMinutes.value
          ? today
          : today.add(const Duration(days: 1));
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

  void pickStartMonth(DateTime month) =>
      _pickThenNext(OnboardingStep.treatmentStart, () {
        treatmentStart.value = approxStart(month);
        treatmentStartMode.value = 'month';
      });

  void pickStartOlder(DateTime month) =>
      _pickThenNext(OnboardingStep.treatmentStart, () {
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

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  DateTime get birthDate =>
      DateTime(birthYear.value, birthMonth.value, birthDay.value);

  int get age {
    final now = DateTime.now();
    var years = now.year - birthYear.value;
    final hadBirthday =
        now.month > birthMonth.value ||
        (now.month == birthMonth.value && now.day >= birthDay.value);
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
    if (y == birthYear.value && m == birthMonth.value && d == birthDay.value)
      return;
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

  void setHeightCm(double cm) =>
      heightCm.value = cm.clamp(minHeightCm, maxHeightCm);

  void confirmHeight() {
    if (current != OnboardingStep.height) return;
    heightCm.value ??= defaultHeightCm;
    Haptics.instance.lightImpact();
    next();
  }

  // -------------------------------------------------------------- activity

  void pickActivity(String id) =>
      _pickThenNext(OnboardingStep.activity, () => activity.value = id);

  // ------------------------------------------------------------------ diet

  /// Diets with no meat, fish or eggs use the vegetarian food lists.
  static const Set<String> _meatFree = {'veg', 'vegan', 'jain'};

  void pickDiet(String id) => _pickThenNext(OnboardingStep.diet, () {
    diet.value = id;
    veg.value = _meatFree.contains(id);
    plateOff.clear();
  });

  // ------------------------------------------------------------- reminders

  /// Shows the system prompt. Either answer moves on; a "no" just keeps
  /// reminders off and says where to turn them on later.
  Future<void> enableReminders() async {
    if (askingReminders.value || current != OnboardingStep.reminders) return;
    askingReminders.value = true;
    Haptics.instance.mediumImpact();
    try {
      final granted = await NotificationService.instance.requestPermission();
      remindersOn.value = granted;
      if (granted) {
        Haptics.instance.lightImpact();
      } else {
        showToast('No problem. You can turn reminders on later in Me.');
      }
      if (!isClosed && current == OnboardingStep.reminders) next();
    } finally {
      askingReminders.value = false;
    }
  }

  void skipReminders() {
    if (askingReminders.value || current != OnboardingStep.reminders) return;
    remindersOn.value = false;
    Haptics.instance.selectionClick();
    next();
  }

  // ------------------------------------------------------------------ dose

  void pickDose(double mg) => _pickThenNext(OnboardingStep.dose, () {
    strength.value = mg;
    doseMode.value = 'label';
  });

  void pickDoseUnsure() =>
      _pickThenNext(OnboardingStep.dose, () => doseMode.value = 'unsure');

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
    if (!goalTouched.value) {
      goalDraftKg.value = ((weightKg.value * 0.9) * 2).round() / 2;
    }
    Haptics.instance.lightImpact();
    next();
  }

  // ------------------------------------------------------------ goal weight

  void setGoalDraft(double kg) {
    goalTouched.value = true;
    goalDraftKg.value =
        (kg.clamp(minWeightKg, maxWeightKg) * 100).round() / 100;
  }

  /// kg still to go: positive to lose, negative to gain.
  double get goalDiffKg => weightKg.value - goalDraftKg.value;

  double? get goalBmi => heightCm.value == null
      ? null
      : goalDraftKg.value / ((heightCm.value! / 100) * (heightCm.value! / 100));

  void confirmGoal() {
    if (current != OnboardingStep.goal) return;
    goalKg.value = (goalDraftKg.value * 10).round() / 10;
    Haptics.instance.lightImpact();
    next();
  }

  void skipGoal() {
    if (current != OnboardingStep.goal) return;
    goalKg.value = null;
    Haptics.instance.selectionClick();
    next();
  }

  /// 1.2 g per kg rounded to 5 g, a common general guideline shown as a
  /// starting point the user can change.
  int get suggestedProtein {
    // A little more for people who train hard. General guidance only.
    final perKg = activity.value == 'active' || activity.value == 'athlete'
        ? 1.4
        : 1.2;
    final g = (weightKg.value * perKg / 5).round() * 5;
    return g.clamp(60, 180);
  }

  /// About 35 ml per kg, plus some for activity, rounded to 250 ml and kept
  /// between 2 and 4 litres. General guidance only.
  int get suggestedWaterMl {
    final extra = switch (activity.value) {
      'mod' => 250,
      'active' => 500,
      'athlete' => 750,
      _ => 0,
    };
    final ml = weightKg.value * 35 + extra;
    return ((ml / 250).round() * 250).clamp(2000, 4000);
  }

  /// "every Thursday", "daily", "every other Monday", "every 3 days".
  String get rhythmLabel {
    final day = Dates.weekdayName(shotWeekday.value);
    return switch (everyDays) {
      1 => 'daily',
      7 => 'every $day',
      14 => 'every other $day',
      final n => 'every $n days',
    };
  }

  int get proteinShown =>
      proteinTouched.value ? proteinGoal.value : suggestedProtein;
  int get waterShownMl =>
      waterTouched.value ? waterGoal.value : suggestedWaterMl;

  void setWaterGoal(double litres) {
    waterTouched.value = true;
    waterGoal.value = ((litres * 1000 / 250).round() * 250).clamp(1000, 5000);
  }

  // ------------------------------------------------------------------ plan

  /// "Edit" on the plan's dose card: redo medicine → schedule, then come back.
  void editDoseFromPlan() {
    if (current != OnboardingStep.plan) return;
    Haptics.instance.selectionClick();
    _returnToPlan = true;
    _go(steps.indexOf(OnboardingStep.medicine));
  }

  void confirmPlan() {
    if (current != OnboardingStep.plan || saving.value) return;
    Haptics.instance.mediumImpact();
    next();
  }

  // ------------------------------------------------------ save progress

  /// Which sign-in is running, for the button spinner. Null when idle.
  final Rxn<SocialProvider> signingIn = Rxn<SocialProvider>();

  /// Firebase Auth isn't set up yet, so sign-in just explains that for now.
  /// TODO(auth): call AuthService.signInWithApple/Google, then finish().
  void signInWith(SocialProvider provider) {
    if (signingIn.value != null || current != OnboardingStep.save) return;
    Haptics.instance.lightImpact();
    showToast('Sign-in is coming soon. Your data is safe on this phone.');
  }

  /// "Not now": keep everything on the phone and carry on to Plus.
  void skipSave() {
    if (signingIn.value != null || current != OnboardingStep.save) return;
    Haptics.instance.selectionClick();
    finish();
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

  List<Food> get plateFoods =>
      veg.value ? Catalog.vegFoods : Catalog.everydayFoods;

  int get plateTotal => plateFoods
      .where((f) => !plateOff.contains(f.id))
      .fold<int>(0, (sum, f) => sum + f.grams);

  void toggleFocus(String id) {
    Haptics.instance.selectionClick();
    if (focus.contains(id)) {
      focus.remove(id);
    } else {
      focus.add(id);
    }
  }

  void confirmFocus() {
    if (focus.isEmpty || current != OnboardingStep.focus) return;
    Haptics.instance.lightImpact();
    next();
  }

  double? get bmi {
    final h = heightCm.value;
    if (h == null || h <= 0) return null;
    final m = h / 100;
    return weightKg.value / (m * m);
  }

  // ------------------------------------------------------------------ save

  String? get _customMedicineOrNull =>
      medicineId.value == Catalog.other && customMedicineValid
      ? customMedicine.value.trim()
      : null;

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
      treatmentStartedAt: stage.value == 'starting'
          ? doseDate.value
          : treatmentStart.value,
      sex: sex.value.isEmpty ? null : sex.value,
      birthDate: birthDate,
      heightInCm: heightInCm.value,
      activity: activity.value.isEmpty ? null : activity.value,
      useKg: useKg.value,
      startWeightKg: weightKg.value,
      goalWeightKg: goalKg.value,
      heightCm: heightCm.value,
      proteinGoalG: proteinShown,
      waterGoalMl: waterShownMl,
      vegDiet: veg.value,
      diet: diet.value.isEmpty ? null : diet.value,
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

  /// [remindersOn] overrides the answer from the reminders screen (the old
  /// plan page still passes it).
  Future<void> finish({bool? remindersOn}) async {
    if (saving.value) return;
    saving.value = true;
    try {
      final profile = _build(
        remindersOn: remindersOn ?? this.remindersOn.value,
      );
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
