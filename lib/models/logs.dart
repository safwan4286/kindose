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
    this.pain,
    this.note,
  });

  final String id;
  final DateTime takenAt;
  final String medicineId;
  final double strengthMg;

  /// Injection site id, or '' for tablets.
  final String site;

  /// How it felt: 0 none, 1 a little, 2 sore, 3 painful (see
  /// Catalog.painLabels). Null when the user skipped the question.
  final int? pain;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'takenAt': takenAt.millisecondsSinceEpoch,
    'medicineId': medicineId,
    'strengthMg': strengthMg,
    'site': site,
    'pain': pain,
    'painScale': 4,
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
      pain: _readPain(m),
      note: m.strOrNull('note'),
    );
  }

  /// New logs store 0–3. Early builds stored 0–10, so map those down.
  static int? _readPain(Map<dynamic, dynamic> m) {
    final raw = m['pain'];
    if (raw is! num) return null;
    final v = raw.toInt();
    if (m['painScale'] == 4) return v.clamp(0, 3);
    if (v <= 0) return 0;
    if (v <= 3) return 1;
    if (v <= 6) return 2;
    return 3;
  }

  DoseLog copyWith({
    DateTime? takenAt,
    String? medicineId,
    double? strengthMg,
    String? site,
    int? Function()? pain,
    String? Function()? note,
  }) {
    return DoseLog(
      id: id,
      takenAt: takenAt ?? this.takenAt,
      medicineId: medicineId ?? this.medicineId,
      strengthMg: strengthMg ?? this.strengthMg,
      site: site ?? this.site,
      pain: pain == null ? this.pain : pain(),
      note: note == null ? this.note : note(),
    );
  }
}

/// One protein or water entry, so Today can show a timeline and undo.
class LogEntry {
  const LogEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.amount,
    this.label,
  });

  final String id;
  final DateTime at;

  /// 'protein' (grams) or 'water' (ml).
  final String kind;
  final int amount;

  /// Food name for protein ("Paneer, 100 g"); null for quick amounts.
  final String? label;

  bool get isProtein => kind == 'protein';

  Map<String, dynamic> toMap() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'kind': kind,
    'amount': amount,
    'label': label,
  };

  static LogEntry? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final at = raw.date('at');
    final id = raw.str('id');
    final kind = raw.str('kind');
    if (at == null || id.isEmpty || (kind != 'protein' && kind != 'water'))
      return null;
    return LogEntry(
      id: id,
      at: at,
      kind: kind,
      amount: raw.integer('amount'),
      label: raw.strOrNull('label'),
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
    this.symptomLevels = const <String, int>{},
    this.nausea,
    this.foodNoise,
    this.appetite,
    this.note,
    this.entries = const <LogEntry>[],
  });

  factory DayLog.empty(String key) => DayLog(key: key);

  /// yyyy-MM-dd
  final String key;
  final int proteinG;
  final int waterMl;

  /// Index into Catalog.moods (0 = Great … 4 = Rough).
  final int? mood;
  final List<String> symptoms;

  /// Side-effect strength: 1 mild, 2 moderate, 3 severe. Check-ins saved
  /// before levels existed only have [symptoms]; [levelOf] reads those as mild.
  final Map<String, int> symptomLevels;

  /// 0 = mild, 1 = moderate, 2 = severe (with 'nausea' in [symptoms]);
  /// -1 = "None" was picked; null = not answered.
  final int? nausea;

  /// Nausea was logged at any level (not "None", not unanswered).
  bool get hasNausea => symptoms.contains('nausea') || (nausea ?? -1) >= 0;

  /// 0 = quiet, 1 = some, 2 = loud
  final int? foodNoise;

  /// 0 = low, 1 = normal, 2 = high
  final int? appetite;
  final String? note;

  /// Protein and water entries in the order they were added (older days
  /// saved before entries existed only have the totals).
  final List<LogEntry> entries;

  DateTime get date => Dates.parseKey(key) ?? DateTime.now();

  bool get hasCheckIn =>
      mood != null ||
      symptoms.isNotEmpty ||
      nausea != null ||
      foodNoise != null ||
      appetite != null ||
      note != null;

  /// 0 (not felt) to 3 (severe) for a side effect id.
  int levelOf(String id) =>
      symptomLevels[id] ?? (symptoms.contains(id) ? 1 : 0);

  DayLog copyWith({
    int? proteinG,
    int? waterMl,
    int? mood,
    List<String>? symptoms,
    Map<String, int>? symptomLevels,
    int? nausea,
    int? foodNoise,
    int? appetite,
    String? note,
    bool clearNote = false,
    List<LogEntry>? entries,
  }) {
    return DayLog(
      key: key,
      proteinG: proteinG ?? this.proteinG,
      waterMl: waterMl ?? this.waterMl,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      symptomLevels: symptomLevels ?? this.symptomLevels,
      nausea: nausea ?? this.nausea,
      foodNoise: foodNoise ?? this.foodNoise,
      appetite: appetite ?? this.appetite,
      note: clearNote ? null : (note ?? this.note),
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'proteinG': proteinG,
    'waterMl': waterMl,
    'mood': mood,
    'symptoms': symptoms,
    'symptomLevels': symptomLevels,
    'nausea': nausea,
    'foodNoise': foodNoise,
    'appetite': appetite,
    'note': note,
    'entries': entries.map((e) => e.toMap()).toList(),
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
      symptomLevels: _readLevels(m['symptomLevels']),
      nausea: m.intOrNull('nausea'),
      foodNoise: m.intOrNull('foodNoise'),
      appetite: m.intOrNull('appetite'),
      note: m.strOrNull('note'),
      entries: (m['entries'] is List ? m['entries'] as List : const <dynamic>[])
          .map(LogEntry.fromMap)
          .whereType<LogEntry>()
          .toList(),
    );
  }

  static Map<String, int> _readLevels(dynamic raw) {
    if (raw is! Map) return const <String, int>{};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is num)
          e.key as String: (e.value as num).toInt().clamp(1, 3),
    };
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
