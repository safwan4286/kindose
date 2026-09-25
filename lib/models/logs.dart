

import '../resources/date_utils.dart';
import 'map_read.dart';

/// One dose the user took.
class DoseLog {
  const DoseLog({
    required this.id,
    required this.takenAt,
    required this.medicineId,
    required this.strengthMg,
    required this.site,
    required this.pain,
    this.note,
  });

  final String id;
  final DateTime takenAt;
  final String medicineId;
  final double strengthMg;

  /// Injection site id, or '' for tablets.
  final String site;

  /// 0–10
  final int pain;
  final String? note;

  Map<String, dynamic> toMap() => {
        'id': id,
        'takenAt': takenAt.millisecondsSinceEpoch,
        'medicineId': medicineId,
        'strengthMg': strengthMg,
        'site': site,
        'pain': pain,
        'note': note,
      };

  static DoseLog? fromMap(Map<dynamic, dynamic> m) {
    final at = m.date('takenAt');
    final id = m.str('id');
    if (at == null || id.isEmpty) return null;
    return DoseLog(
      id: id,
      takenAt: at,
      medicineId: m.str('medicineId'),
      strengthMg: m.dbl('strengthMg'),
      site: m.str('site'),
      pain: m.integer('pain').clamp(0, 10),
      note: m.strOrNull('note'),
    );
  }
}

/// Everything logged for one calendar day.
class DayLog {
  const DayLog({
    required this.key,
    this.proteinG = 0,
    this.waterMl = 0,
    this.mood,
    this.symptoms = const <String>[],
    this.nausea,
    this.foodNoise,
    this.appetite,
    this.note,
  });

  factory DayLog.empty(String key) => DayLog(key: key);

  /// yyyy-MM-dd
  final String key;
  final int proteinG;
  final int waterMl;

  /// Index into Catalog.moods (0 = Great … 4 = Rough).
  final int? mood;
  final List<String> symptoms;

  /// 0 = mild, 1 = moderate, 2 = severe
  final int? nausea;

  /// 0 = quiet, 1 = some, 2 = loud
  final int? foodNoise;

  /// 0 = low, 1 = normal, 2 = high
  final int? appetite;
  final String? note;

  DateTime get date => Dates.parseKey(key) ?? DateTime.now();

  bool get hasCheckIn =>
      mood != null || symptoms.isNotEmpty || nausea != null || note != null;

  DayLog copyWith({
    int? proteinG,
    int? waterMl,
    int? mood,
    List<String>? symptoms,
    int? nausea,
    int? foodNoise,
    int? appetite,
    String? note,
    bool clearNote = false,
  }) {
    return DayLog(
      key: key,
      proteinG: proteinG ?? this.proteinG,
      waterMl: waterMl ?? this.waterMl,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      nausea: nausea ?? this.nausea,
      foodNoise: foodNoise ?? this.foodNoise,
      appetite: appetite ?? this.appetite,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toMap() => {
        'key': key,
        'proteinG': proteinG,
        'waterMl': waterMl,
        'mood': mood,
        'symptoms': symptoms,
        'nausea': nausea,
        'foodNoise': foodNoise,
        'appetite': appetite,
        'note': note,
      };

  static DayLog? fromMap(Map<dynamic, dynamic> m) {
    final key = m.str('key');
    if (Dates.parseKey(key) == null) return null;
    return DayLog(
      key: key,
      proteinG: m.integer('proteinG').clamp(0, 1000),
      waterMl: m.integer('waterMl').clamp(0, 20000),
      mood: m.intOrNull('mood'),
      symptoms: m.strList('symptoms'),
      nausea: m.intOrNull('nausea'),
      foodNoise: m.intOrNull('foodNoise'),
      appetite: m.intOrNull('appetite'),
      note: m.strOrNull('note'),
    );
  }
}

/// One weigh-in. Stored in kg; shown in the user's unit.
class WeightEntry {
  const WeightEntry({required this.date, required this.kg});

  final DateTime date;
  final double kg;

  String get key => Dates.key(date);

  Map<String, dynamic> toMap() => {
        'date': Dates.dateOnly(date).millisecondsSinceEpoch,
        'kg': kg,
      };

  static WeightEntry? fromMap(Map<dynamic, dynamic> m) {
    final d = m.date('date');
    final kg = m.dblOrNull('kg');
    if (d == null || kg == null || kg <= 0) return null;
    return WeightEntry(date: d, kg: kg);
  }
}
