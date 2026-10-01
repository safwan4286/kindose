import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../plus/plus_access.dart';
import 'offer_config.dart';

/// Decides if the discount offer shows when someone closes the paywall,
/// and remembers how often it was shown (on this phone).
///
/// The rules come from [config]. Call [applyRemote] with the backend JSON
/// once Remote Config is set up; until then the defaults are used.
class OfferService extends GetxService {
  static const String _box = 'settings';
  static const String _showsKey = 'offerShows';
  static const String _lastShownKey = 'offerLastShown';
  static const String _closesKey = 'paywallCloses';

  final Rx<OfferConfig> config = OfferConfig.defaults.obs;

  Box<dynamic> get _settings => Hive.box<dynamic>(_box);

  int get _shows => (_settings.get(_showsKey) as int?) ?? 0;

  DateTime? get _lastShown {
    final v = _settings.get(_lastShownKey);
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
  }

  /// TODO(remote-config): call with the `paywall_offer` value after fetch.
  /// Accepts a JSON string or an already-decoded map. Bad data is ignored.
  void applyRemote(Object? raw) {
    try {
      final map = raw is String ? jsonDecode(raw) : raw;
      if (map is Map<String, dynamic>) config.value = OfferConfig.fromJson(map);
    } catch (_) {
      // Keep the current config.
    }
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
    if (c.maxShows > 0 && _shows >= c.maxShows) return false;
    final last = _lastShown;
    if (last != null && DateTime.now().difference(last).inDays < c.cooldownDays)
      return false;

    await _settings.put(_showsKey, _shows + 1);
    await _settings.put(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    return true;
  }
}
