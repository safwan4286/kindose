import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../analytics/analytics.dart';
import '../plus/plus_access.dart';
import 'offer_config.dart';
import '../purchases/purchase_service.dart';

/// Decides if the discount offer shows when someone closes the paywall,
/// and remembers how often it was shown (on this phone).
///
/// The rules come from [config] (`app_config` → `paywall_offer`); see
/// [OfferMode] for the three ways it can run.
class OfferService extends GetxService {
  static const String _box = 'settings';
  static const String _showsKey = 'offerShows';
  static const String _lastShownKey = 'offerLastShown';
  static const String _closesKey = 'paywallCloses';
  static const String _startedKey = 'offerStartedAt';
  static const String _expiredLoggedKey = 'offerExpiredLogged';
  static const String _bannerHiddenKey = 'offerBannerHidden';

  final Rx<OfferConfig> config = OfferConfig.defaults.obs;

  /// When the [OfferMode.timer] window opened on this phone.
  final Rx<DateTime?> startedAt = Rx<DateTime?>(null);

  /// The Today banner was closed for this window.
  final RxBool bannerHidden = false.obs;

  Box<dynamic> get _settings => Hive.box<dynamic>(_box);

  int get _shows => (_settings.get(_showsKey) as int?) ?? 0;

  DateTime? get _lastShown {
    final v = _settings.get(_lastShownKey);
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
  }

  @override
  void onInit() {
    super.onInit();
    final v = _settings.get(_startedKey);
    startedAt.value = v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    bannerHidden.value = _settings.get(_bannerHiddenKey) == true;
  }

  /// Accepts a JSON string or an already-decoded map. Bad data is ignored.
  void applyRemote(Object? raw) {
    try {
      final map = raw is String ? jsonDecode(raw) : raw;
      if (map is Map<String, dynamic>) config.value = OfferConfig.fromJson(map);
    } catch (_) {
      // Keep the current config.
    }
  }

  /// End of the timer window, or null outside [OfferMode.timer] or
  /// before it opened.
  DateTime? get endsAt {
    final start = startedAt.value;
    final c = config.value;
    if (c.mode != OfferMode.timer || start == null) return null;
    return start.add(Duration(hours: c.timerHours));
  }

  bool get _windowOpen {
    final end = endsAt;
    return end != null && DateTime.now().isBefore(end);
  }

  /// The Today banner: only while a timer window is open, for someone
  /// without Plus who can really buy the offer.
  bool get bannerVisible {
    final c = config.value;
    return c.enabled &&
        c.showInApp &&
        c.showBanner &&
        c.mode == OfferMode.timer &&
        !bannerHidden.value &&
        !PlusAccess.active.value &&
        _windowOpen &&
        _discountReady(c.offeringId);
  }

  Future<void> hideBanner() async {
    bannerHidden.value = true;
    await _settings.put(_bannerHiddenKey, true);
  }

  /// Call when the user closes the paywall. Returns true when the offer
  /// should show now (and counts it as shown).
  Future<bool> onPaywallClosed({required bool fromOnboarding}) async {
    final closes = ((_settings.get(_closesKey) as int?) ?? 0) + 1;
    await _settings.put(_closesKey, closes);

    final c = config.value;
    if (!c.enabled || PlusAccess.active.value) return false;
    if (fromOnboarding ? !c.showInOnboarding : !c.showInApp) return false;
    if (closes < c.minPaywallCloses) return false;
    // Only when the store really has the discount (an intro price below
    // the regular one). Otherwise the screen would say "30% off" for a
    // full-price plan; skip it and keep the show for later.
    if (!_discountReady(c.offeringId)) return false;

    switch (c.mode) {
      case OfferMode.once:
        if (c.maxShows > 0 && _shows >= c.maxShows) return false;
        final last = _lastShown;
        if (last != null &&
            DateTime.now().difference(last).inDays < c.cooldownDays) {
          return false;
        }
      case OfferMode.timer:
        if (startedAt.value == null) {
          await _start();
        } else if (!_windowOpen) {
          await _logExpired();
          return false;
        }
      case OfferMode.untilClaimed:
        break;
    }

    await _settings.put(_showsKey, _shows + 1);
    await _settings.put(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    return true;
  }

  Future<void> _start() async {
    final now = DateTime.now();
    startedAt.value = now;
    bannerHidden.value = false;
    await _settings.put(_startedKey, now.millisecondsSinceEpoch);
    await _settings.delete(_bannerHiddenKey);
  }

  /// Logged once, the first time an ended window is noticed.
  Future<void> _logExpired() async {
    if (_settings.get(_expiredLoggedKey) == true) return;
    await _settings.put(_expiredLoggedKey, true);
    Analytics.offerExpired();
  }

  /// Debug: forget the timer window, so the next paywall close opens a
  /// new one.
  Future<void> debugResetTimer() async {
    if (!kDebugMode) return;
    startedAt.value = null;
    bannerHidden.value = false;
    await _settings.delete(_startedKey);
    await _settings.delete(_expiredLoggedKey);
    await _settings.delete(_bannerHiddenKey);
  }

  static bool _discountReady(String offeringId) {
    // Debug builds use RevenueCat's Test Store, which has no intro
    // price; let them through so the offer can be checked end to end.
    if (kDebugMode) return true;
    if (!Get.isRegistered<PurchaseService>()) return false;
    final product = Get.find<PurchaseService>()
        .package('year', offeringId: offeringId)
        ?.storeProduct;
    final intro = product?.introductoryPrice;
    return product != null && intro != null && intro.price < product.price;
  }
}
