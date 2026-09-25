import 'dart:async';

import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';
import '../home/weight_sheet.dart';

class ChecklistItem {
  const ChecklistItem(this.label, this.icon, this.done, this.onTap);

  final String label;
  final String icon;
  final bool done;
  final void Function()? onTap;
}

class TodayTip {
  const TodayTip(this.title, this.text, this.icon);

  final String title;
  final String text;
  final String icon;
}

/// Everything on the Today tab. Values are getters over [TrackerService],
/// so reading them inside `Obx` keeps the screen live.
class TodayController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();

  /// Ticks every 30 s so the countdown and greeting stay current.
  final Rx<DateTime> now = DateTime.now().obs;
  final RxBool busy = false.obs;
  Timer? _ticker;

  static const int glassMl = 250;

  @override
  void onInit() {
    super.onInit();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => now.value = DateTime.now());
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  UserProfile? get profile => tracker.profile.value;
  DayLog get day => tracker.dayLog(now.value);

  String get medicineLabel {
    final p = profile;
    if (p == null) return '';
    return '${Catalog.medicine(p.medicineId).name} ${Catalog.mg(p.strengthMg)} mg';
  }

  bool get isTablet => profile?.form == 'tablet';

  // ------------------------------------------------------------------ dose

  DateTime? get nextDoseAt => tracker.nextDoseAt(now.value);
  bool get isDoseDay => tracker.isDoseDay(now.value);
  DoseLog? get doseToday => tracker.doseOn(now.value);
  bool get isOverdue {
    final next = nextDoseAt;
    return next != null && Dates.dateOnly(next).isBefore(Dates.dateOnly(now.value));
  }

  String get countdown {
    final next = nextDoseAt;
    if (next == null) return '—';
    return Dates.countdown(next.difference(now.value));
  }

  String get nextDoseLine {
    final next = nextDoseAt;
    final p = profile;
    if (next == null || p == null) return '';
    final day = Dates.relativeDay(next, now.value);
    final site = isTablet ? 'tablet' : Catalog.siteName(tracker.nextSiteId).toLowerCase();
    return '$day · ${Dates.timeOfDay(p.shotMinutes)} · $site';
  }

  String get nextSiteName => Catalog.siteName(tracker.nextSiteId);

  String siteNameOf(String id) => Catalog.siteName(id);

  String get streakLabel {
    final n = tracker.onTimeStreak;
    final p = profile;
    if (n == 0 || p == null) return '';
    final unit = p.everyDays == 7 ? 'week' : p.everyDays == 1 ? 'day' : 'dose';
    return '$n ${n == 1 ? unit : '${unit}s'} on time';
  }

  Future<void> markDoseDone() async {
    if (busy.value) return;
    busy.value = true;
    try {
      await tracker.addDose(
        takenAt: DateTime.now(),
        site: isTablet ? '' : tracker.nextSiteId,
      );
    } finally {
      busy.value = false;
    }
  }

  Future<void> undoDoseToday() async {
    final d = doseToday;
    if (d == null) return;
    await tracker.removeDose(d.id);
    showToast('Dose removed');
  }

  String get nextAfterToday {
    final next = tracker.nextDoseAt(now.value);
    if (next == null) return '';
    return Dates.shortWithDay(next);
  }

  // --------------------------------------------------------- protein/water

  int get proteinGoal => profile?.proteinGoalG ?? 100;
  int get waterGoal => profile?.waterGoalMl ?? 2500;
  int get glassCount => (waterGoal / glassMl).round().clamp(4, 12);
  int get glassesFull => (day.waterMl / glassMl).floor();

  String get litres {
    final l = day.waterMl / 1000;
    return l == l.roundToDouble() ? l.toStringAsFixed(0) : l.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');
  }

  String get waterGoalLabel {
    final l = waterGoal / 1000;
    return '${l == l.roundToDouble() ? l.toStringAsFixed(0) : l.toStringAsFixed(1)} L';
  }

  void tapGlass(int i) {
    final full = glassesFull;
    final ml = (i < full && i == full - 1) ? i * glassMl : (i + 1) * glassMl;
    tracker.setWater(ml);
  }

  void setMood(int m) => tracker.setMood(m);

  // ------------------------------------------------------------- checklist

  List<ChecklistItem> get checklist => [
        const ChecklistItem('Set up your plan', Img3d.calendar, true, null),
        ChecklistItem(
          isTablet ? 'Log your first tablet' : 'Log your first dose',
          isTablet ? Img3d.pill : Img3d.syringe,
          tracker.doses.isNotEmpty,
          () => Get.toNamed<void>(Routes.logDose),
        ),
        ChecklistItem(
          'Add your first protein',
          Img3d.egg,
          tracker.days.values.any((d) => d.proteinG > 0),
          () => Get.toNamed<void>(Routes.addIntake, arguments: 'protein'),
        ),
        ChecklistItem(
          'Log a weigh-in',
          Img3d.chartDown,
          tracker.weights.length > 1,
          showWeightSheet,
        ),
      ];

  bool get showChecklist => checklist.any((c) => !c.done);

  // ------------------------------------------------------------------- tip

  TodayTip get tip {
    if (isDoseDay || doseToday != null) {
      return const TodayTip(
        'Dose-day tip',
        'Smaller, protein-first meals are often easier today. Go light on fried food.',
        Img3d.seedling,
      );
    }
    final left = proteinGoal - day.proteinG;
    if (left <= 0) {
      return const TodayTip('Muscle tip', 'Protein goal hit. Nice work protecting your muscle.', Img3d.biceps);
    }
    final food = left >= 20 ? 'A whey shake gets you 24 g' : 'A cup of Greek yogurt gets you 17 g';
    return TodayTip('Muscle tip', '$left g to go. $food closer.', Img3d.biceps);
  }
}
