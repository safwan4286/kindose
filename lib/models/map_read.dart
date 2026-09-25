/// Safe readers for maps coming out of Hive. Hive returns
/// `Map<dynamic, dynamic>`, and old or damaged records may miss fields,
/// so every read falls back to a default instead of throwing.
extension MapRead on Map<dynamic, dynamic> {
  String str(String key, [String fallback = '']) {
    final v = this[key];
    return v is String ? v : fallback;
  }

  String? strOrNull(String key) {
    final v = this[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  int integer(String key, [int fallback = 0]) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.round();
    return fallback;
  }

  int? intOrNull(String key) {
    final v = this[key];
    return v is num ? v.round() : null;
  }

  double dbl(String key, [double fallback = 0]) {
    final v = this[key];
    return v is num ? v.toDouble() : fallback;
  }

  double? dblOrNull(String key) {
    final v = this[key];
    return v is num ? v.toDouble() : null;
  }

  bool boolean(String key, [bool fallback = false]) {
    final v = this[key];
    return v is bool ? v : fallback;
  }

  List<String> strList(String key) {
    final v = this[key];
    if (v is List) return v.whereType<String>().toList();
    return <String>[];
  }

  DateTime? date(String key) {
    final v = this[key];
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
