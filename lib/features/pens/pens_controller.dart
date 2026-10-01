import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/plus/plus_access.dart';
import '../../services/supply/supply_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/ask_number.dart';
import '../../widgets/toast.dart';
import 'widgets/pens_sheets.dart';

/// Pens & cost (Plus). The numbers live in [SupplyService]; this adds the
/// wording and opens the sheets.
class PensController extends GetxController {
  final SupplyService supply = Get.find<SupplyService>();
  final TrackerService tracker = Get.find<TrackerService>();

  /// Plus feature. Also open in debug builds, so it can be tested before
  /// RevenueCat is connected.
  bool get unlocked => PlusAccess.unlocked || kDebugMode;

  /// Read inside an Obx so every value the screen shows is watched.
  void watch() {
    supply.dosesPerPack.value;
    supply.packStartedAt.value;
    supply.usedOffset.value;
    supply.spare.value;
    supply.refillReminder.value;
    supply.currency.value;
    supply.purchases.length;
    tracker.doses.length;
    tracker.profile.value;
    tracker.nextDoseOverride.value;
    PlusAccess.unlocked;
  }

  @override
  void onReady() {
    super.onReady();
    // First visit: ask the three numbers straight away.
    if (unlocked && !supply.isSetUp) setUp();
  }

  // ---------------------------------------------------------------- words

  String get _form => tracker.profile.value?.form ?? 'pen';
  bool get isTablet => _form == 'tablet';

  /// "pen", "vial" or "pack".
  String get pack => switch (_form) {
    'vial' => 'vial',
    'tablet' => 'pack',
    _ => 'pen',
  };

  String get packs => '${pack}s';
  String get doseWord => isTablet ? 'tablet' : 'dose';
  String get dosesWord => '${doseWord}s';

  String get title => isTablet ? 'Tablets & cost' : '${_cap(packs)} & cost';

  /// "Mounjaro® · 5 mg" on the current pen card.
  String get medicineLine {
    final p = tracker.profile.value;
    if (p == null || p.medicineId == Catalog.undecided) return '';
    final name = Catalog.medicineName(p.medicineId, p.customMedicine);
    return p.strengthMg > 0 ? '$name · ${Catalog.mg(p.strengthMg)} mg' : name;
  }

  int get _defaultPerPack => isTablet ? 30 : 4;

  String get leftLine => '${supply.leftInPack} left';
  String get ofLine =>
      'of ${supply.dosesPerPack.value} $dosesWord in this $pack';

  /// Lime line on the current pen card.
  String get refillLine {
    final left = supply.leftInPack;
    final need = supply.nextPackNeededOn;
    if (left == 0) {
      return need == null
          ? 'This $pack is empty. Start a new one for your next $doseWord.'
          : 'This $pack is empty. Next $pack: ${Dates.shortWithDay(need)}';
    }
    if (left == 1) {
      return need == null
          ? 'Last $doseWord in this $pack'
          : 'Last $doseWord in this $pack. Next $pack: ${Dates.shortWithDay(need)}';
    }
    final until = supply.packLastsUntil;
    return until == null
        ? '$left $dosesWord left in this $pack'
        : '${_cap(pack)} lasts until about ${Dates.shortWithDay(until)}';
  }

  String get spareTitle {
    final n = supply.spare.value;
    return n == 0 ? 'No spare $packs' : '$n spare ${n == 1 ? pack : packs}';
  }

  String get spareSub {
    final until = supply.supplyLastsUntil;
    if (until == null) return 'Add one when you pick up more.';
    return supply.spare.value == 0
        ? 'Your supply lasts until about ${Dates.shortWithDay(until)}'
        : 'With your current $pack, lasts until about ${Dates.shortWithDay(until)}';
  }

  String get refillSub {
    final n = supply.lowAt;
    return n == 1
        ? 'When 1 $doseWord is left and no spare $pack'
        : 'When $n $dosesWord are left in total';
  }

  // -------------------------------------------------------------- actions

  Future<void> setUp() async {
    final r = await showPackSetupSheet(
      pack: pack,
      dosesWord: dosesWord,
      perPack: supply.isSetUp ? supply.dosesPerPack.value : _defaultPerPack,
      left: supply.isSetUp ? supply.leftInPack : null,
      spare: supply.spare.value,
    );
    if (r == null) return;
    Haptics.instance.mediumImpact();
    await supply.setUp(
      dosesPerPack: r.perPack,
      usedAlready: r.perPack - r.left,
      spare: r.spare,
    );
    showToast('Saved. It counts down each time you log.');
  }

  Future<void> startNewPack() async {
    Haptics.instance.mediumImpact();
    final hadSpare = supply.spare.value > 0;
    await supply.startNewPack();
    showToast(
      hadSpare ? 'New $pack started · 1 spare used' : 'New $pack started',
    );
  }

  Future<void> fixCount(BuildContext context) async {
    final v = await askNumber(
      context,
      title: '${_cap(dosesWord)} left in this $pack',
      unit: dosesWord,
      initial: supply.leftInPack.toDouble(),
      min: 0,
      max: supply.dosesPerPack.value.toDouble(),
      decimals: 0,
    );
    if (v == null || v.isNaN) return;
    Haptics.instance.selectionClick();
    await supply.setLeftInPack(v.round());
  }

  void changeSpare(int by) {
    final next = supply.spare.value + by;
    if (next < 0 || next > 99) return;
    Haptics.instance.selectionClick();
    supply.setSpare(next);
  }

  Future<void> setRefillReminder(bool on) async {
    if (on && !await NotificationService.instance.requestPermission()) {
      showToast('Allow notifications for Kindose in your phone settings.');
      return;
    }
    Haptics.instance.selectionClick();
    await supply.setRefillReminder(on);
  }

  Future<void> addPurchase() async {
    final p = await showPurchaseSheet(
      pack: pack,
      currency: supply.currency.value,
      strengthMg: tracker.profile.value?.strengthMg,
    );
    if (p == null) return;
    Haptics.instance.mediumImpact();
    await supply.addPurchase(p);
    showToast(
      'Added · ${p.packs} spare ${p.packs == 1 ? pack : packs} at home',
    );
  }

  Future<void> removePurchase(Purchase p) async {
    Haptics.instance.mediumImpact();
    await supply.removePurchase(p.id);
    showUndoToast(
      'Purchase removed',
      () => supply.addPurchase(p, addToSpare: false),
    );
  }

  Future<void> openSettings() async {
    final r = await showPackSettingsSheet(
      pack: pack,
      dosesWord: dosesWord,
      perPack: supply.dosesPerPack.value,
      currency: supply.currency.value,
    );
    if (r == null) return;
    Haptics.instance.selectionClick();
    await supply.setDosesPerPack(r.perPack);
    await supply.setCurrency(r.currency);
  }

  void openPlus() {
    Haptics.instance.lightImpact();
    Get.toNamed<void>(Routes.plus);
  }

  // ---------------------------------------------------------------- spend

  String get monthName => Dates.months[DateTime.now().month - 1];

  String get thisMonth {
    final now = DateTime.now();
    return supply.money(supply.spendIn(now.year, now.month));
  }

  String get spendSub {
    final per = supply.perDose;
    final first = supply.firstPurchase;
    final parts = <String>[
      if (per != null) 'About ${supply.money(per.roundToDouble())} a $doseWord',
      if (first != null)
        '${supply.money(supply.totalSpend)} since ${Dates.monthShort(first.month)}',
    ];
    return parts.isEmpty
        ? 'Add a purchase to see what you spend.'
        : parts.join(' · ');
  }

  /// Last 4 months, oldest first: (label, total, isThisMonth).
  List<(String, double, bool)> get months {
    final now = DateTime.now();
    return [
      for (var i = 3; i >= 0; i--)
        _month(DateTime(now.year, now.month - i), i == 0),
    ];
  }

  (String, double, bool) _month(DateTime d, bool current) =>
      (Dates.monthShort(d.month), supply.spendIn(d.year, d.month), current);

  /// "2 pens · 5 mg".
  String purchaseTitle(Purchase p) {
    final what = '${p.packs} ${p.packs == 1 ? pack : packs}';
    final mg = p.strengthMg;
    return mg == null || mg <= 0 ? what : '$what · ${Catalog.mg(mg)} mg';
  }

  /// "Tue, 22 Sep · pharmacy".
  String purchaseSub(Purchase p) {
    final note = p.note;
    final day = Dates.shortWithDay(p.date);
    return note == null ? day : '$day · $note';
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
