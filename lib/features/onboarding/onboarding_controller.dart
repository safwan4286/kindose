import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../resources/water_units.dart';
import '../../widgets/k_ruler.dart';
import '../../widgets/no_internet_sheet.dart';
import '../../services/backend/backend_service.dart';
import '../../services/haptics/haptics.dart';
import '../../services/region/region.dart';
import '../../services/notifications/notif_prefs.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/tracker_service.dart';
import '../../services/supply/supply_service.dart';
import '../../widgets/social_button.dart';
import '../../widgets/toast.dart';
import '../me/widgets/me_sheets.dart';

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
  focus,
  reminders,
  building,
  plan,
  save,
}

/// Holds the answers while the user moves through onboarding, then saves
/// them as one [UserProfile]. In edit mode (opened from Me) only
/// [editSteps] are shown, only their answers are saved and the rest of the
/// profile is kept.
class OnboardingController extends GetxController {
  OnboardingController({this.editMode = false, List<OnboardingStep>? editSteps})
    : editSteps = editSteps ?? planSteps;

  final bool editMode;

  /// Steps shown in edit mode.
  final List<OnboardingStep> editSteps;

  /// Medicine & dose, then schedule: the original "Edit plan" flow.
  static const List<OnboardingStep> planSteps = [
    OnboardingStep.medicine,
    OnboardingStep.dose,
    OnboardingStep.frequency,
    OnboardingStep.schedule,
  ];

  bool _edits(OnboardingStep s) => editMode && editSteps.contains(s);

  /// Last step of an edit saves, so its button says so.
  String get continueLabel =>
      editMode && page.value == steps.length - 1 ? 'Save changes' : 'Continue';
  final TrackerService _tracker = Get.find<TrackerService>();
  final PageController pageController = PageController();

  /// Steps for this run. Welcome is its own route now, and "Treatment
  /// start" is skipped for people who haven't started yet (their first
  /// dose date already says it). Reads [stage], so Obx callers rebuild when
  /// the first answer changes the flow.
  List<OnboardingStep> get steps {
    if (editMode) {
      // A different medicine brings its usual schedule, so let the user
      // check how often and when before saving.
      final medicineChanged =
          editSteps.contains(OnboardingStep.medicine) &&
          !editSteps.contains(OnboardingStep.frequency) &&
          _loadedMedicineId != null &&
          medicineId.value != _loadedMedicineId;
      return [
        ...editSteps,
        if (medicineChanged) ...[
          OnboardingStep.frequency,
          OnboardingStep.schedule,
        ],
      ];
    }
    final starting = stage.value == 'starting';
    return [
      for (final s in OnboardingStep.values)
        if (s != OnboardingStep.welcome &&
            !(starting && s == OnboardingStep.treatmentStart) &&
            !(s == OnboardingStep.reminders && _notifAllowed.value))
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

  /// Pounds by default in the US and UK (from the phone's region).
  final RxBool useKg = (!Region.prefersPounds).obs;

  /// Kept from the saved plan when editing; Region default for new plans.
  final RxBool useOz = Region.prefersOunces.obs;
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
  final RxBool heightInCm = (!Region.prefersFeet).obs;

  /// True once the weight unit was picked by hand; until then it follows
  /// the height unit (ft · in → lb, cm → kg).
  bool _weightUnitPicked = false;

  void setHeightInCm(bool cm) {
    heightInCm.value = cm;
    if (!_weightUnitPicked && useKg.value != cm) {
      useKg.value = cm;
      _defaultWeightFromSex();
    }
  }

  void setUseKg(bool kg) {
    _weightUnitPicked = true;
    useKg.value = kg;
  }

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

  /// 'nonveg', 'pesc', 'veg' or 'vegan', or '' until answered.
  final RxString diet = ''.obs;

  /// Set on the reminders screen: true only when the system said yes.
  final RxBool remindersOn = false.obs;
  final RxBool askingReminders = false.obs;

  /// The phone already lets Kindose notify (asked before, or Android 12
  /// and older where it's on by default). Then the reminders screen has
  /// nothing to ask: it's left out and reminders start on.
  final RxBool _notifAllowed = false.obs;

  /// Extra nudges picked on the reminders page (off by default). Saved to
  /// [NotifPrefs] only when notifications are allowed.
  final RxBool wantWater = false.obs;
  final RxBool wantProtein = false.obs;
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
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    if (editMode) return;
    final allowed = await NotificationService.instance.areEnabled() == true;
    if (!allowed || isClosed) return;
    // Only before the user gets there, so no page they've passed moves.
    if (page.value >= steps.indexOf(OnboardingStep.reminders)) return;
    remindersOn.value = true;
    _notifAllowed.value = true;
  }

  @override
  void onClose() {
    pageController.dispose();
    customMedicineField.dispose();
    customDoseField.dispose();
    super.onClose();
  }

  /// Medicine saved before this edit, to spot a change.
  String? _loadedMedicineId;

  void _loadFrom(UserProfile p) {
    _loadedMedicineId = p.medicineId;
    stage.value = p.stage;
    medicineId.value = p.medicineId;
    customMedicine.value = p.customMedicine ?? '';
    customMedicineField.text = customMedicine.value;
    form.value = p.form;
    strength.value = p.strengthMg;
    if (p.strengthMg <= 0) {
      doseMode.value = 'unsure';
    } else if (Catalog.medicine(p.medicineId).strengths
        .contains(p.strengthMg)) {
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
    _weightUnitPicked = true;
    useOz.value = p.useOz;
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

  /// Steps redone by "Edit" on the plan card; leaving them returns to the plan.
  static const Set<OnboardingStep> _planEditSteps = {
    OnboardingStep.medicine,
    OnboardingStep.dose,
    OnboardingStep.frequency,
    OnboardingStep.schedule,
  };

  /// While editing from the plan, a move that would leave the edit steps
  /// (forward past the schedule, or back past the medicine) goes straight
  /// back to the plan instead.
  bool _leaveEditToPlan(int to) {
    if (!_returnToPlan) return false;
    if (to >= 0 && to < steps.length && _planEditSteps.contains(steps[to]))
      return false;
    _returnToPlan = false;
    _go(steps.indexOf(OnboardingStep.plan));
    return true;
  }

  void next() {
    if (_leaveEditToPlan(page.value + 1)) return;
    if (page.value >= steps.length - 1) {
      finish();
      return;
    }
    _go(page.value + 1);
  }

  void back() {
    Haptics.instance.selectionClick();
    if (page.value == 0) {
      popRoute();
      return;
    }
    if (_leaveEditToPlan(page.value - 1)) return;
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
    // Re-picking the saved medicine keeps the user's form and schedule.
    if (editMode && !changed) return;
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
  /// Editing a plan that already has doses logged: always the last dose,
  /// even for people who started as "starting".
  bool get asksLastDose =>
      stage.value.isEmpty ||
      stage.value == 'taking' ||
      (editMode && _tracker.lastDose != null);

  /// Daily medicine and already taking: only the time matters.
  bool get needsDoseDate => !(asksLastDose && everyDays == 1);

  bool get scheduleReady => !needsDoseDate || doseDate.value != null;

  /// The date on the schedule step was changed in this run (edit mode
  /// only acts on a date the user actually changed).
  bool _doseDateTouched = false;

  void pickDoseDate(DateTime day) {
    _doseDateTouched = true;
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
      day = nowMinutes < shotMinutes.value ? today : Dates.addDays(today, 1);
    } else {
      final picked = doseDate.value;
      if (picked == null) return null;
      if (asksLastDose) {
        day = Dates.addDays(picked, every);
        // Last dose long ago: the next one is due today, not in the past.
        if (day.isBefore(today)) day = today;
      } else {
        day = picked;
      }
    }
    return Dates.atMinutes(day, shotMinutes.value);
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

  void pickDiet(String id) => _pickThenNext(OnboardingStep.diet, () {
    diet.value = id;
    // Diets without meat or fish use the vegetarian food lists.
    veg.value = Catalog.isMeatFree(id);
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
        await _saveExtraNudges();
      } else {
        showToast('No problem. You can turn reminders on later in Me.');
      }
      if (!isClosed && current == OnboardingStep.reminders) next();
    } finally {
      askingReminders.value = false;
    }
  }

  void toggleWater() {
    Haptics.instance.selectionClick();
    wantWater.toggle();
  }

  void toggleProtein() {
    Haptics.instance.selectionClick();
    wantProtein.toggle();
  }

  Future<void> _saveExtraNudges() async {
    if (!Get.isRegistered<NotifPrefs>()) return;
    // Only turns nudges on: editing a plan never switches off ones the
    // person already chose in Me › Notifications.
    if (!wantWater.value && !wantProtein.value) return;
    final prefs = Get.find<NotifPrefs>();
    if (wantWater.value) prefs.waterOn.value = true;
    if (wantProtein.value) prefs.proteinOn.value = true;
    await prefs.save();
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

  /// Shown under the field once something is typed that can't be saved.
  String? get customDoseError {
    final t = customDose.value.trim();
    if (t.isEmpty || t == '.' || t == ',' || customDoseMg != null) return null;
    final v = double.tryParse(t.replaceAll(',', '.'));
    if (v != null && v > 100) return 'Enter 100 mg or less';
    return 'Enter an amount above 0 mg';
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
    // A round number in the unit on screen, so the ruler starts on a tick.
    weightKg.value = useKg.value
        ? switch (sex.value) {
            'female' => 68,
            'male' => 80,
            _ => 72,
          }
        : switch (sex.value) {
                'female' => 150,
                'male' => 175,
                _ => 160,
              } /
              Imperial.lbPerKg;
  }

  void confirmWeight() {
    if (current != OnboardingStep.weight) return;
    weightTouched.value = true;
    if (!goalTouched.value) {
      // 10% below, rounded in the unit on screen (½ kg or whole lb).
      final goal = weightKg.value * 0.9;
      goalDraftKg.value = useKg.value
          ? (goal * 2).round() / 2
          : (goal * Imperial.lbPerKg).round() / Imperial.lbPerKg;
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
  int get suggestedProtein => suggestProtein(weightKg.value, activity.value);

  static int suggestProtein(double kg, String? activity) {
    // A little more for people who train hard. General guidance only.
    final perKg = activity == 'active' || activity == 'athlete' ? 1.4 : 1.2;
    final g = (kg * perKg / 5).round() * 5;
    return g.clamp(60, 180);
  }

  /// About 35 ml per kg, plus some for activity, rounded to 250 ml and kept
  /// between 2 and 4 litres. General guidance only.
  int get suggestedWaterMl =>
      suggestWaterMl(weightKg.value, activity.value, oz: useOz.value);

  static int suggestWaterMl(double kg, String? activity, {required bool oz}) {
    final extra = switch (activity) {
      'mod' => 250,
      'active' => 500,
      'athlete' => 750,
      _ => 0,
    };
    final ml = kg * 35 + extra;
    final rounded = ((ml / 250).round() * 250).clamp(2000, 4000);
    // Ounce people get whole glasses of 8 fl oz (64, 72, 80 … fl oz).
    if (!oz) return rounded;
    return Water.fromOz((Water.toOz(rounded) / 8).round() * 8.0);
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

  /// For people who see water in fluid ounces (whole ounces).
  void setWaterGoalOz(double oz) {
    waterTouched.value = true;
    waterGoal.value = Water.fromOz(oz.roundToDouble()).clamp(1000, 5000);
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

  /// Apple or Google sign-in (Supabase). If this account already has a
  /// backup (new phone), offer to restore it; otherwise finish and the
  /// first backup runs by itself.
  Future<void> signInWith(SocialProvider provider) async {
    if (signingIn.value != null || current != OnboardingStep.save) return;
    Haptics.instance.lightImpact();
    final backend = Get.find<BackendService>();
    signingIn.value = provider;
    backend.autoPaused = true;
    try {
      final r = await backend.signIn(provider);
      switch (r) {
        case BackendResult.ok:
          break;
        case BackendResult.cancelled:
          return;
        case BackendResult.offline:
          await showNoInternetSheet(what: 'Signing in');
          return;
        case BackendResult.notReady:
        case BackendResult.failed:
          showToast('Sign-in didn’t work this time. Please try again.');
          return;
      }
      final check = await backend.checkBackup();
      if (!check.ok) {
        await backend.signOut();
        await showNoInternetSheet(what: 'Checking for a backup');
        return;
      }
      final cloud = check.backup;
      if (cloud != null) {
        final restore = await showWelcomeBackSheet(
          backup: cloud,
          otherLabel: 'Start a new plan',
          otherNote: 'A new plan replaces your saved data.',
        );
        if (restore == null) {
          // Closed without choosing: stay here, signed out.
          await backend.signOut();
          return;
        }
        if (restore == true) {
          if (await backend.restore(cloud) == BackendResult.ok) {
            Haptics.instance.mediumImpact();
            Get.offAllNamed<void>(Routes.home);
            showToast('Welcome back. Your data is restored.');
          } else {
            await backend.signOut();
            showToast('Couldn’t restore the backup. Please try again.');
          }
          return;
        }
      }
      // New account, or "Start fresh": the plan made now is theirs.
      await backend.claimLocal();
    } finally {
      signingIn.value = null;
      backend.autoPaused = false;
    }
    await finish();
  }

  /// Already signed in (came from "I already have an account" with no
  /// backup yet): the plan is theirs, carry on.
  bool get alreadySignedIn =>
      Get.isRegistered<BackendService>() && Get.find<BackendService>().signedIn;

  String? get signedInEmail => Get.isRegistered<BackendService>()
      ? Get.find<BackendService>().email
      : null;

  Future<void> continueSignedIn() async {
    if (signingIn.value != null || current != OnboardingStep.save) return;
    Haptics.instance.lightImpact();
    await Get.find<BackendService>().claimLocal();
    await finish();
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
      // Only a date the user changed here, or daily → weekly (the old
      // weekday is just a default then). Otherwise a late dose kept on
      // "Keep Fridays" would quietly move the dose day.
      final changed =
          _doseDateTouched || (old.everyDays == 1 && everyDays != 1);
      final picked = needsDoseDate && changed ? doseDate.value : null;
      final plan = editSteps.any(planSteps.contains);
      final p = !plan
          ? old
          : old.copyWith(
              medicineId: medicineId.value,
              customMedicine: _customMedicineOrNull,
              form: form.value,
              strengthMg: _savedStrength,
              everyDays: everyDays,
              frequencyUnsure: frequency.value == 'unsure',
              // The dose day follows the date on the schedule step (e.g. daily →
              // weekly: the weekday of the last dose, not an old default).
              shotWeekday: picked?.weekday ?? shotWeekday.value,
              shotMinutes: shotMinutes.value,
              // No dose logged yet: the first-dose date picked here.
              plannedFirstDose: !asksLastDose && picked != null ? picked : null,
            );
      return p.copyWith(
        treatmentStartedAt: _edits(OnboardingStep.treatmentStart)
            ? treatmentStart.value
            : null,
        clearTreatmentStart:
            _edits(OnboardingStep.treatmentStart) &&
            treatmentStart.value == null,
        sex: _edits(OnboardingStep.sex) && sex.value.isNotEmpty
            ? sex.value
            : null,
        birthDate: _edits(OnboardingStep.birth) ? birthDate : null,
        heightCm: _edits(OnboardingStep.height) ? heightCm.value : null,
        heightInCm: _edits(OnboardingStep.height) ? heightInCm.value : null,
        activity: _edits(OnboardingStep.activity) && activity.value.isNotEmpty
            ? activity.value
            : null,
        focus: _edits(OnboardingStep.focus) ? focus.toList() : null,
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
      useOz: useOz.value,
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
      takenAt: Dates.atMinutes(day, shotMinutes.value),
      site: '',
    );
  }

  /// Edit plan, "When was your last dose?": a different day there means
  /// the logged last dose was on that day, so its date is corrected
  /// (time of day kept).
  Future<void> _fixLastDoseDate() async {
    final last = _tracker.lastDose;
    final picked = doseDate.value;
    if (!_doseDateTouched ||
        !asksLastDose ||
        !needsDoseDate ||
        last == null ||
        picked == null) {
      return;
    }
    if (Dates.sameDay(last.takenAt, picked)) return;
    final t = last.takenAt;
    await _tracker.updateDose(
      last.copyWith(
        takenAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          t.hour,
          t.minute,
        ),
      ),
    );
  }

  /// Pen/vial ↔ tablet in Edit plan: a pack of 4 pens isn't a pack of 30
  /// tablets, so Pens & cost starts from the new form's usual pack size
  /// (and says so) instead of counting tablets as pen doses.
  Future<void> _resetPackForNewForm(
    UserProfile? before,
    UserProfile now,
  ) async {
    if (before == null) return;
    final wasTablet = before.form == 'tablet';
    final isTablet = now.form == 'tablet';
    if (wasTablet == isTablet || !Get.isRegistered<SupplyService>()) return;
    final supply = Get.find<SupplyService>();
    if (!supply.isSetUp) return;
    await supply.setDosesPerPack(isTablet ? 30 : 4);
    showToast('Check your pack size in Pens & cost');
  }

  /// [remindersOn] overrides the answer from the reminders screen (the old
  /// plan page still passes it).
  Future<void> finish({bool? remindersOn}) async {
    if (saving.value) return;
    saving.value = true;
    try {
      final before = _tracker.profile.value;
      final profile = _build(
        remindersOn: remindersOn ?? this.remindersOn.value,
      );
      await _tracker.saveProfile(profile);
      if (!editMode) {
        await _tracker.addWeight(profile.startWeightKg);
        await _logLastDose();
        // Last dose long ago: the plan preview said "next dose today", so
        // Today shows it as due today, not as many days overdue.
        final next = _tracker.nextDoseAt();
        final today = Dates.dateOnly(DateTime.now());
        if (asksLastDose && next != null && next.isBefore(today)) {
          await _tracker.moveNextDose(today);
        }
      } else {
        await _fixLastDoseDate();
        await _resetPackForNewForm(before, profile);
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
