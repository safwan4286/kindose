import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/plus_access.dart';
import '../../services/supply/supply_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

/// Route argument for the "Dose logged" screen.
class DoseDoneArgs {
  const DoseDoneArgs({required this.dose, this.profileBefore});

  final DoseLog dose;

  /// Profile before this log changed it (new dose day or usual dose), so
  /// Undo can put it back. Null when the profile was not touched.
  final UserProfile? profileBefore;
}

class DoseDoneController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();

  DoseDoneArgs? _args;
  DoseLog? get dose => _args?.dose;
  final RxBool busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    final a = Get.arguments;
    if (a is DoseDoneArgs) _args = a;
  }

  @override
  void onReady() {
    super.onReady();
    // Nothing to show (e.g. opened by a deep link): just go back.
    if (_args == null) popRoute();
  }

  UserProfile? get profile => tracker.profile.value;
  bool get isTablet => (dose?.site ?? '').isEmpty;

  String get title {
    final d = dose;
    if (d == null) return 'Logged';
    if (isTablet) return 'Marked as taken';
    return 'Dose ${tracker.doseNumberOf(d.id)} logged';
  }

  /// "Mounjaro® 5 mg · right thigh · 8:04 AM"
  String get summary {
    final d = dose;
    if (d == null) return '';
    final name = Catalog.medicineName(d.medicineId, profile?.customMedicine);
    final mark = Catalog.medicine(d.medicineId).mark ?? '';
    final parts = <String>[
      '$name$mark ${Catalog.mgLabel(d.strengthMg)}',
      if (d.site.isNotEmpty) Catalog.siteName(d.site).toLowerCase(),
      Dates.time(d.takenAt),
    ];
    return parts.join(' · ');
  }

  String get nextDate {
    final next = tracker.nextDoseAt();
    if (next == null) return '—';
    return Dates.relativeDay(next, DateTime.now()) == 'Tomorrow'
        ? 'Tomorrow'
        : Dates.shortWithDay(next);
  }

  String get nextSub => isTablet
      ? Dates.time(tracker.nextDoseAt() ?? DateTime.now())
      : '${Catalog.siteName(tracker.nextSiteId)} next';

  int get streak => tracker.onTimeStreak;

  String get streakValue {
    final n = streak;
    final unit = switch (profile?.everyDays ?? 7) {
      1 => n == 1 ? 'day' : 'days',
      7 => n == 1 ? 'week' : 'weeks',
      _ => n == 1 ? 'dose' : 'doses',
    };
    return '$n $unit';
  }

  String get streakSub => streak <= 1 ? 'streak started' : 'in a row';

  /// "Thu 8:00 AM", or null when reminders are off.
  String? get reminderLine {
    final p = profile;
    final next = tracker.nextDoseAt();
    if (p == null || !p.remindersOn || next == null) return null;
    return '${Dates.weekdayShort(next.weekday)} ${Dates.time(next)}';
  }

  // ------------------------------------------------------------ pen line

  SupplyService get supply => Get.find<SupplyService>();

  /// Shown once Pens & cost (Plus) is set up.
  bool get showPen => (PlusAccess.active.value || kDebugMode) && supply.isSetUp;

  String get _pack => switch (profile?.form) {
    'vial' => 'vial',
    'tablet' => 'pack',
    _ => 'pen',
  };

  bool get penEmpty => supply.leftInPack == 0;

  /// "2 doses left in this pen" / "That was the last dose in this pen."
  String get penLine {
    final left = supply.leftInPack;
    final word = isTablet ? 'tablet' : 'dose';
    if (left > 0)
      return '$left ${left == 1 ? word : '${word}s'} left in this $_pack';
    final spare = supply.spare.value;
    return spare == 0
        ? 'That was the last $word in this $_pack. No spare ${_pack}s at home.'
        : 'That was the last $word in this $_pack.';
  }

  String get newPackLabel => 'Start a new $_pack';

  Future<void> startNewPack() async {
    Haptics.instance.mediumImpact();
    await supply.startNewPack();
    showToast('New $_pack started');
  }

  void openPens() {
    Haptics.instance.selectionClick();
    Get.offNamed<void>(Routes.pens);
  }

  void done() {
    Haptics.instance.selectionClick();
    popRoute();
  }

  void feeling() {
    Haptics.instance.selectionClick();
    Get.offNamed<void>(Routes.checkIn);
  }

  Future<void> undo() async {
    final d = dose;
    if (d == null || busy.value) return;
    busy.value = true;
    try {
      Haptics.instance.mediumImpact();
      await tracker.removeDose(d.id);
      final before = _args?.profileBefore;
      if (before != null) await tracker.saveProfile(before);
      popRoute();
      showToast('Dose removed');
    } finally {
      busy.value = false;
    }
  }
}
