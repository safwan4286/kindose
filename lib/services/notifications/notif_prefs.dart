import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Per-reminder choices from Me → Notifications. Saved in the settings box
/// (so cloud backup includes them).
///
/// Three switches live where they always did and are not duplicated here:
/// dose reminders (`UserProfile.remindersOn`), doctor visit
/// (`TrackerService.visitReminderOn`) and refill
/// (`SupplyService.refillReminder`).
class NotifPrefs extends GetxService {
  static const String _key = 'notifPrefs';

  Box<dynamic> get _box => Hive.box<dynamic>('settings');

  final RxBool followUpOn = true.obs;
  final RxBool missedOn = true.obs;

  final RxBool waterOn = false.obs;

  /// Hours between water reminders: 2 or 3.
  final RxInt waterEvery = 2.obs;

  /// Minutes after midnight.
  final RxInt waterStart = (9 * 60).obs;
  final RxInt waterEnd = (20 * 60).obs;

  final RxBool proteinOn = false.obs;

  /// Days before a doctor visit: 1, 3 or 7.
  final RxInt visitDays = 3.obs;

  /// Free week ending and offers.
  final RxBool offersOn = true.obs;

  final RxBool quietOn = true.obs;
  final RxInt quietStart = (22 * 60).obs;
  final RxInt quietEnd = (7 * 60).obs;

  /// Bumps on every change, so reminders re-plan with one watcher.
  final RxInt version = 0.obs;

  NotifPrefs init() {
    load();
    return this;
  }

  /// Reads the saved choices (also after a restore or Delete all).
  void load() {
    final raw = _box.get(_key);
    final m = raw is Map ? raw : const {};
    bool b(String k, bool d) => m[k] is bool ? m[k] as bool : d;
    int i(String k, int d, int min, int max) {
      final v = m[k];
      return v is int && v >= min && v <= max ? v : d;
    }

    followUpOn.value = b('followUp', true);
    missedOn.value = b('missed', true);
    waterOn.value = b('water', false);
    waterEvery.value = i('waterEvery', 2, 2, 3);
    waterStart.value = i('waterStart', 9 * 60, 0, 1439);
    waterEnd.value = i('waterEnd', 20 * 60, 0, 1439);
    proteinOn.value = b('protein', false);
    final vd = i('visitDays', 3, 1, 7);
    visitDays.value = const [1, 3, 7].contains(vd) ? vd : 3;
    offersOn.value = b('offers', true);
    quietOn.value = b('quiet', true);
    quietStart.value = i('quietStart', 22 * 60, 0, 1439);
    quietEnd.value = i('quietEnd', 7 * 60, 0, 1439);
    version.value++;
  }

  Future<void> save() async {
    version.value++;
    await _box.put(_key, {
      'followUp': followUpOn.value,
      'missed': missedOn.value,
      'water': waterOn.value,
      'waterEvery': waterEvery.value,
      'waterStart': waterStart.value,
      'waterEnd': waterEnd.value,
      'protein': proteinOn.value,
      'visitDays': visitDays.value,
      'offers': offersOn.value,
      'quiet': quietOn.value,
      'quietStart': quietStart.value,
      'quietEnd': quietEnd.value,
    });
  }

  /// True when [minutes] (after midnight) falls in quiet hours. Handles
  /// windows that cross midnight (10 PM – 7 AM).
  bool isQuiet(int minutes) {
    if (!quietOn.value) return false;
    final s = quietStart.value;
    final e = quietEnd.value;
    if (s == e) return false;
    return s < e ? minutes >= s && minutes < e : minutes >= s || minutes < e;
  }

  /// [when] moved to the end of quiet hours when it falls inside them.
  DateTime outsideQuiet(DateTime when) {
    final m = when.hour * 60 + when.minute;
    if (!isQuiet(m)) return when;
    final day = DateTime(when.year, when.month, when.day);
    var end = day.add(Duration(minutes: quietEnd.value));
    if (!end.isAfter(when)) end = end.add(const Duration(days: 1));
    return end;
  }
}
