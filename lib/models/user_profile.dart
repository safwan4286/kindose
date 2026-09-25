
import 'map_read.dart';

/// Everything the user told us during onboarding. Stored as one record.
class UserProfile {
  const UserProfile({
    required this.stage,
    required this.medicineId,
    required this.form,
    required this.strengthMg,
    required this.everyDays,
    required this.shotWeekday,
    required this.shotMinutes,
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

  /// 'taking' or 'starting'
  final String stage;
  final String medicineId;

  /// 'pen', 'auto', 'vial' or 'tablet'
  final String form;
  final double strengthMg;

  /// 7 = weekly, 14 = every 2 weeks, 1 = daily, anything else = custom.
  final int everyDays;

  /// 1 (Mon) … 7 (Sun). Used when [everyDays] is 7 or 14.
  final int shotWeekday;

  /// Minutes after midnight, e.g. 540 = 9:00 AM.
  final int shotMinutes;
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
    String? form,
    double? strengthMg,
    int? everyDays,
    int? shotWeekday,
    int? shotMinutes,
    bool? useKg,
    int? proteinGoalG,
    int? waterGoalMl,
    bool? remindersOn,
  }) {
    return UserProfile(
      stage: stage,
      medicineId: medicineId ?? this.medicineId,
      form: form ?? this.form,
      strengthMg: strengthMg ?? this.strengthMg,
      everyDays: everyDays ?? this.everyDays,
      shotWeekday: shotWeekday ?? this.shotWeekday,
      shotMinutes: shotMinutes ?? this.shotMinutes,
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
        'form': form,
        'strengthMg': strengthMg,
        'everyDays': everyDays,
        'shotWeekday': shotWeekday,
        'shotMinutes': shotMinutes,
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
      form: m.str('form', 'pen'),
      strengthMg: m.dbl('strengthMg', 2.5),
      everyDays: m.integer('everyDays', 7).clamp(1, 60),
      shotWeekday: m.integer('shotWeekday', 7).clamp(1, 7),
      shotMinutes: m.integer('shotMinutes', 540).clamp(0, 1439),
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
