import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/logs.dart';
import '../../models/map_read.dart';
import '../../resources/date_utils.dart';
import '../region/region.dart';
import '../tracker_service.dart';

/// One purchase of pens / vials / tablet packs, for the user's own records.
class Purchase {
  const Purchase({
    required this.id,
    required this.date,
    required this.packs,
    required this.price,
    this.strengthMg,
    this.note,
  });

  final String id;
  final DateTime date;

  /// Pens (or vials / packs) bought.
  final int packs;

  /// Total paid, in the user's currency.
  final double price;
  final double? strengthMg;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'packs': packs,
    'price': price,
    'strengthMg': strengthMg,
    'note': note,
  };

  static Purchase? fromMap(Map<dynamic, dynamic> m) {
    final id = m.str('id');
    final date = m.date('date');
    if (id.isEmpty || date == null) return null;
    return Purchase(
      id: id,
      date: date,
      packs: m.integer('packs', 1).clamp(1, 99),
      price: m.dbl('price', 0),
      strengthMg: m.dblOrNull('strengthMg'),
      note: m.str('note').isEmpty ? null : m.str('note'),
    );
  }
}

/// Pens & cost (Plus). Counts doses in the current pen from the dose log,
/// so logging, editing or undoing a dose keeps the count right by itself.
///
/// Counting rules (see test/supply_service_test.dart):
/// - A dose counts when it was *logged* after the pen was started, even if
///   its time was set earlier ("took it this morning"). Doses back-logged
///   for days long before the pen started don't count.
/// - When the current pen is used up and more doses are logged, spare pens
///   are opened by themselves, so the supply keeps counting down even if
///   nobody taps "Start a new pen". Nothing is saved for this until the
///   user changes something (see [_settle]), so undoing a dose undoes it.
///
/// Stored in the settings box, so "Delete all my data" clears it too.
class SupplyService extends GetxService {
  static const String _box = 'settings';

  final TrackerService tracker = Get.find<TrackerService>();

  /// Doses in one pen / vial / pack.
  final RxInt dosesPerPack = 4.obs;

  /// When the current pen was started. Null = not set up yet.
  final Rxn<DateTime> packStartedAt = Rxn<DateTime>();

  /// Manual correction from "Fix count" (added to the logged count).
  final RxInt usedOffset = 0.obs;
  final RxInt spare = 0.obs;
  final RxBool refillReminder = true.obs;
  final RxString currency = r'$'.obs;
  final RxList<Purchase> purchases = <Purchase>[].obs;

  Box<dynamic> get _s => Hive.box<dynamic>(_box);

  @override
  void onInit() {
    super.onInit();
    load();
    // "Delete all my data" clears the box; reload when the profile goes.
    ever(tracker.profile, (p) {
      if (p == null) load();
    });
  }

  void load() {
    dosesPerPack.value = (_s.get('supplyDosesPerPack') as int?) ?? 4;
    final start = _s.get('supplyStartedAt');
    packStartedAt.value = start is int
        ? DateTime.fromMillisecondsSinceEpoch(start)
        : null;
    usedOffset.value = (_s.get('supplyOffset') as int?) ?? 0;
    spare.value = (_s.get('supplySpare') as int?) ?? 0;
    refillReminder.value = _s.get('supplyRefillReminder') != false;
    currency.value =
        (_s.get('supplyCurrency') as String?) ?? Region.currencySymbol;
    final raw = _s.get('supplyPurchases');
    purchases.assignAll(
      [
        if (raw is List)
          for (final m in raw.whereType<Map<dynamic, dynamic>>())
            ?Purchase.fromMap(m),
      ]..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  bool get isSetUp => packStartedAt.value != null;

  // ------------------------------------------------------------ counting

  /// When a dose was logged. Dose ids are the creation time in
  /// microseconds; anything else falls back to the dose time.
  static DateTime loggedAt(DoseLog d) {
    final us = int.tryParse(d.id);
    return us == null ? d.takenAt : DateTime.fromMicrosecondsSinceEpoch(us);
  }

  /// Doses that count against pens started at [start].
  int _loggedSince(DateTime start) {
    final earliest = start.subtract(const Duration(days: 2));
    return tracker.doses
        .where(
          (d) => !loggedAt(d).isBefore(start) && !d.takenAt.isBefore(earliest),
        )
        .length;
  }

  /// Doses used since the current pen started (may run past one pen).
  int get _used {
    final start = packStartedAt.value;
    if (start == null) return 0;
    final n = _loggedSince(start) + usedOffset.value;
    return n < 0 ? 0 : n;
  }

  /// Left in the pen in use and spare pens still closed, after opening
  /// spares for doses past the end of the current pen.
  ({int left, int spare}) get _state {
    final per = dosesPerPack.value;
    final used = _used;
    if (used <= per) return (left: per - used, spare: spare.value);
    final extra = used - per;
    final opened = (extra + per - 1) ~/ per;
    if (opened > spare.value) return (left: 0, spare: 0);
    return (left: opened * per - extra, spare: spare.value - opened);
  }

  int get leftInPack => _state.left;

  /// Doses taken from the pen in use, 0 … [dosesPerPack].
  int get usedInPack => dosesPerPack.value - leftInPack;

  /// Spare pens still closed (spares opened by the count are taken off).
  int get spareLeft => _state.spare;

  /// Doses left in the current pen plus all spare pens.
  int get dosesLeft => leftInPack + spareLeft * dosesPerPack.value;

  /// Date of the dose that will need the next pen (null when unknown).
  DateTime? get nextPackNeededOn => _doseDateAfter(leftInPack);

  /// Date of the last dose in the current pen (null when it is empty).
  DateTime? get packLastsUntil =>
      leftInPack == 0 ? null : _doseDateAfter(leftInPack - 1);

  /// Date of the last dose the whole supply covers.
  DateTime? get supplyLastsUntil =>
      dosesLeft == 0 ? null : _doseDateAfter(dosesLeft - 1);

  /// The date of the dose [n] doses after the next one (0 = next dose).
  DateTime? _doseDateAfter(int n) {
    final p = tracker.profile.value;
    final next = tracker.nextDoseAt(DateTime.now());
    if (p == null || next == null) return null;
    return Dates.dateOnly(next).add(Duration(days: p.everyDays * n));
  }

  /// Doses left at which the refill reminder fires: 1 for weekly pens,
  /// a week's worth for daily tablets.
  int get lowAt {
    final every = tracker.profile.value?.everyDays ?? 7;
    return every <= 1 ? 7 : 1;
  }

  bool get runningLow => isSetUp && dosesLeft <= lowAt;

  // -------------------------------------------------------------- actions

  /// Saves spares the count opened by itself, so manual changes start from
  /// what the screen shows.
  void _settle() {
    final start = packStartedAt.value;
    if (start == null || _used <= dosesPerPack.value) return;
    final s = _state;
    spare.value = s.spare;
    usedOffset.value = (dosesPerPack.value - s.left) - _loggedSince(start);
  }

  /// Everything a pen change touches, for Undo.
  ({DateTime? start, int offset, int spare}) snapshot() => (
    start: packStartedAt.value,
    offset: usedOffset.value,
    spare: spare.value,
  );

  Future<void> restore(({DateTime? start, int offset, int spare}) s) async {
    packStartedAt.value = s.start;
    usedOffset.value = s.offset;
    spare.value = s.spare;
    await _save();
  }

  Future<void> setUp({
    required int dosesPerPack,
    required int usedAlready,
    required int spare,
  }) async {
    this.dosesPerPack.value = dosesPerPack.clamp(1, 60);
    packStartedAt.value = DateTime.now();
    usedOffset.value = usedAlready.clamp(0, dosesPerPack);
    this.spare.value = spare.clamp(0, 99);
    await _save();
  }

  /// A fresh pen: counting restarts, one spare is used if there is one.
  Future<void> startNewPack() async {
    _settle();
    packStartedAt.value = DateTime.now();
    usedOffset.value = 0;
    if (spare.value > 0) spare.value--;
    await _save();
  }

  /// "Fix count": set how many doses are left in the current pen.
  Future<void> setLeftInPack(int left) async {
    _settle();
    final start = packStartedAt.value ?? DateTime.now();
    packStartedAt.value = start;
    final logged = _loggedSince(start);
    final wantUsed = (dosesPerPack.value - left).clamp(0, dosesPerPack.value);
    usedOffset.value = wantUsed - logged;
    await _save();
  }

  Future<void> setDosesPerPack(int n) async {
    _settle();
    dosesPerPack.value = n.clamp(1, 60);
    await _save();
  }

  Future<void> setSpare(int n) async {
    _settle();
    spare.value = n.clamp(0, 99);
    await _save();
  }

  Future<void> setRefillReminder(bool on) async {
    refillReminder.value = on;
    await _save();
  }

  Future<void> setCurrency(String symbol) async {
    currency.value = symbol;
    await _save();
  }

  /// Adds a purchase. The pens bought go to the spare count.
  Future<void> addPurchase(Purchase p, {bool addToSpare = true}) async {
    _settle();
    purchases.add(p);
    purchases.sort((a, b) => b.date.compareTo(a.date));
    if (addToSpare) spare.value = (spare.value + p.packs).clamp(0, 99);
    await _save();
  }

  /// Removes a purchase and takes its pens off the spare count (as many as
  /// are still there). Returns how many were taken off.
  Future<int> removePurchase(String id) async {
    final i = purchases.indexWhere((p) => p.id == id);
    if (i == -1) return 0;
    _settle();
    final p = purchases.removeAt(i);
    final taken = p.packs < spare.value ? p.packs : spare.value;
    spare.value -= taken;
    await _save();
    return taken;
  }

  Future<void> _save() async {
    await _s.putAll({
      'supplyDosesPerPack': dosesPerPack.value,
      'supplyStartedAt': packStartedAt.value?.millisecondsSinceEpoch,
      'supplyOffset': usedOffset.value,
      'supplySpare': spare.value,
      'supplyRefillReminder': refillReminder.value,
      'supplyCurrency': currency.value,
      'supplyPurchases': purchases.map((p) => p.toMap()).toList(),
    });
  }

  // ---------------------------------------------------------------- spend

  double spendIn(int year, int month) => purchases
      .where((p) => p.date.year == year && p.date.month == month)
      .fold(0.0, (a, p) => a + p.price);

  double get totalSpend => purchases.fold(0.0, (a, p) => a + p.price);

  /// Average price of one dose across all purchases (null if unknown).
  double? get perDose {
    final doses = purchases.fold(0, (a, p) => a + p.packs) * dosesPerPack.value;
    if (doses == 0 || totalSpend == 0) return null;
    return totalSpend / doses;
  }

  DateTime? get firstPurchase => purchases.isEmpty ? null : purchases.last.date;

  /// "$1,079" / "£23.50".
  String money(double v) {
    final whole = v.truncate();
    final cents = ((v - whole) * 100).round();
    final digits = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '${currency.value}$buf${cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}'}';
  }
}
