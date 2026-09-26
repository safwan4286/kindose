
import 'map_read.dart';

/// Everything the user told us during onboarding. Stored as one record.
class UserProfile {
  const UserProfile({
    required this.stage,
    required this.medicineId,
    this.customMedicine,
    required this.form,
    required this.strengthMg,
    required this.everyDays,
    this.frequencyUnsure = false,
    required this.shotWeekday,
    required this.shotMinutes,
    this.plannedFirstDose,
    this.treatmentStartedAt,
    this.sex,
    this.birthDate,
    this.heightInCm = true,
    required this.useKg,
    required this.startWeightKg,
    required this.goalWeightKg,
    required this.heightCm,
    required this.proteinGoalG,
    required this.waterGoalMl,
    required this.vegDiet,
    required this.focus,
    required this.remindersOn,
    required this.startedAt,
  });

  /// 'taking', 'starting' or 'restart'
  final String stage;
  final String medicineId;

  /// Name the user typed when they picked "Something else".
  final String? customMedicine;

  /// 'pen', 'auto', 'vial' or 'tablet'
  final String form;
  final double strengthMg;

  /// 7 = weekly, 14 = every 2 weeks, 1 = daily, anything else = custom.
  final int everyDays;

  /// True when the user answered "I don't know yet" to how often. [everyDays]
  /// then holds the medicine's usual schedule until they confirm it.
  final bool frequencyUnsure;

  /// 1 (Mon) … 7 (Sun). Used when [everyDays] is 7 or 14.
  final int shotWeekday;

  /// Minutes after midnight, e.g. 540 = 9:00 AM.
  final int shotMinutes;

  /// Day of the first dose for people starting or restarting. Used for the
  /// first reminder until a dose is logged.
  final DateTime? plannedFirstDose;

  /// Roughly when treatment began, for "Week N". Null when not given.
  final DateTime? treatmentStartedAt;

  /// 'female', 'male', 'other' or 'none' (prefer not to say). Only used to
  /// estimate protein and water goals.
  final String? sex;

  /// For age-based goals. Kindose is 18+ only.
  final DateTime? birthDate;

  /// Show height in cm (true) or feet and inches (false). Separate from
  /// [useKg] because many people mix them, e.g. kg with feet and inches.
  final bool heightInCm;
  final bool useKg;
  final double startWeightKg;
  final double? goalWeightKg;
  final double? heightCm;
  final int proteinGoalG;
  final int waterGoalMl;
  final bool vegDiet;
  final List<String> focus;
  final bool remindersOn;
  final DateTime startedAt;

  bool get isDaily => everyDays == 1;

  UserProfile copyWith({
    String? medicineId,
    String? customMedicine,
    String? form,
    double? strengthMg,
    int? everyDays,
    bool? frequencyUnsure,
    int? shotWeekday,
    int? shotMinutes,
    DateTime? plannedFirstDose,
    DateTime? treatmentStartedAt,
    String? sex,
    DateTime? birthDate,
    bool? heightInCm,
    bool? useKg,
    int? proteinGoalG,
    int? waterGoalMl,
    bool? remindersOn,
  }) {
    return UserProfile(
      stage: stage,
      medicineId: medicineId ?? this.medicineId,
      customMedicine: customMedicine ?? this.customMedicine,
      form: form ?? this.form,
      strengthMg: strengthMg ?? this.strengthMg,
      everyDays: everyDays ?? this.everyDays,
      frequencyUnsure: frequencyUnsure ?? this.frequencyUnsure,
      shotWeekday: shotWeekday ?? this.shotWeekday,
      shotMinutes: shotMinutes ?? this.shotMinutes,
      plannedFirstDose: plannedFirstDose ?? this.plannedFirstDose,
      treatmentStartedAt: treatmentStartedAt ?? this.treatmentStartedAt,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      heightInCm: heightInCm ?? this.heightInCm,
      useKg: useKg ?? this.useKg,
      startWeightKg: startWeightKg,
      goalWeightKg: goalWeightKg,
      heightCm: heightCm,
      proteinGoalG: proteinGoalG ?? this.proteinGoalG,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      vegDiet: vegDiet,
      focus: focus,
      remindersOn: remindersOn ?? this.remindersOn,
      startedAt: startedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'stage': stage,
        'medicineId': medicineId,
        'customMedicine': customMedicine,
        'form': form,
        'strengthMg': strengthMg,
        'everyDays': everyDays,
        'frequencyUnsure': frequencyUnsure,
        'shotWeekday': shotWeekday,
        'shotMinutes': shotMinutes,
        'plannedFirstDose': plannedFirstDose?.millisecondsSinceEpoch,
        'treatmentStartedAt': treatmentStartedAt?.millisecondsSinceEpoch,
        'sex': sex,
        'birthDate': birthDate?.millisecondsSinceEpoch,
        'heightInCm': heightInCm,
        'useKg': useKg,
        'startWeightKg': startWeightKg,
        'goalWeightKg': goalWeightKg,
        'heightCm': heightCm,
        'proteinGoalG': proteinGoalG,
        'waterGoalMl': waterGoalMl,
        'vegDiet': vegDiet,
        'focus': focus,
        'remindersOn': remindersOn,
        'startedAt': startedAt.millisecondsSinceEpoch,
      };

  static UserProfile? fromMap(Map<dynamic, dynamic>? m) {
    if (m == null || m.str('medicineId').isEmpty) return null;
    return UserProfile(
      stage: m.str('stage', 'taking'),
      medicineId: m.str('medicineId'),
      customMedicine: m.str('customMedicine').isEmpty ? null : m.str('customMedicine'),
      form: m.str('form', 'pen'),
      strengthMg: m.dbl('strengthMg', 2.5),
      everyDays: m.integer('everyDays', 7).clamp(1, 60),
      frequencyUnsure: m.boolean('frequencyUnsure'),
      shotWeekday: m.integer('shotWeekday', 7).clamp(1, 7),
      shotMinutes: m.integer('shotMinutes', 540).clamp(0, 1439),
      plannedFirstDose: m.date('plannedFirstDose'),
      treatmentStartedAt: m.date('treatmentStartedAt'),
      sex: m.str('sex').isEmpty ? null : m.str('sex'),
      birthDate: m.date('birthDate'),
      heightInCm: m.boolean('heightInCm', true),
      useKg: m.boolean('useKg', true),
      startWeightKg: m.dbl('startWeightKg', 80),
      goalWeightKg: m.dblOrNull('goalWeightKg'),
      heightCm: m.dblOrNull('heightCm'),
      proteinGoalG: m.integer('proteinGoalG', 100),
      waterGoalMl: m.integer('waterGoalMl', 2500),
      vegDiet: m.boolean('vegDiet'),
      focus: m.strList('focus'),
      remindersOn: m.boolean('remindersOn'),
      startedAt: m.date('startedAt') ?? DateTime.now(),
    );
  }
}
