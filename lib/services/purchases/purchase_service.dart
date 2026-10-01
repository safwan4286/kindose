import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../resources/backend_keys.dart';
import '../backend/backend_service.dart';
import '../plus/plus_access.dart';

/// What happened when someone tried to buy.
enum PurchaseOutcome { success, cancelled, pending, failed, unavailable }

/// Kindose Plus purchases through RevenueCat.
///
/// * The `kindose_plus` entitlement decides [PlusAccess.active]. RevenueCat
///   caches customer info, so Plus keeps working offline.
/// * Products come from offerings: `default` (monthly + yearly) and the
///   discount offering named in the offer config (`offer_30`). Prices on
///   screen always come from the store.
/// * Signed in with Google → RevenueCat uses the Supabase user id, so Plus
///   follows the account to a new phone. Signed out → anonymous.
/// * Debug builds use the Test Store key; release builds use the platform
///   keys. With no key purchases are simply unavailable (never a crash).
class PurchaseService extends GetxService {
  static const String entitlementId = 'kindose_plus';

  final Rxn<CustomerInfo> info = Rxn<CustomerInfo>();
  final Rxn<Offerings> offerings = Rxn<Offerings>();

  /// True while a purchase or restore runs (blocks double taps).
  final RxBool busy = false.obs;

  bool ready = false;
  Worker? _userWorker;

  static String get _apiKey {
    if (kDebugMode) return BackendKeys.revenueCatTestKey;
    if (Platform.isIOS) return BackendKeys.revenueCatAppleKey;
    if (Platform.isAndroid) return BackendKeys.revenueCatGoogleKey;
    return '';
  }

  Future<PurchaseService> init() async {
    final key = _apiKey;
    if (key.isEmpty) {
      _log('No RevenueCat key for this build, purchases off');
      return this;
    }
    try {
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(key));
      ready = true;
      Purchases.addCustomerInfoUpdateListener(_apply);
      unawaited(_refresh());
      if (Get.isRegistered<BackendService>()) {
        final backend = Get.find<BackendService>();
        _userWorker = ever(backend.user, (_) => _syncUser());
        unawaited(_syncUser());
      }
    } catch (e) {
      _log('Configure failed: $e');
    }
    return this;
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    if (ready) Purchases.removeCustomerInfoUpdateListener(_apply);
    super.onClose();
  }

  Future<void> _refresh() async {
    try {
      _apply(await Purchases.getCustomerInfo());
    } catch (e) {
      _log('Customer info failed: $e');
    }
    await loadOfferings();
  }

  void _apply(CustomerInfo i) {
    info.value = i;
    PlusAccess.active.value = i.entitlements.active.containsKey(entitlementId);
  }

  /// Links purchases to the signed-in account (Supabase user id).
  Future<void> _syncUser() async {
    if (!ready) return;
    final id = Get.find<BackendService>().user.value?.id;
    try {
      if (id != null) {
        final r = await Purchases.logIn(id);
        _apply(r.customerInfo);
      } else if (!await Purchases.isAnonymous) {
        _apply(await Purchases.logOut());
      }
    } catch (e) {
      _log('User sync failed: $e');
    }
  }

  // ------------------------------------------------------------- reading

  EntitlementInfo? get plus => info.value?.entitlements.active[entitlementId];

  /// App Store / Google Play page to change or cancel, or null.
  String? get managementUrl => info.value?.managementURL;

  Future<void> loadOfferings() async {
    if (!ready) return;
    try {
      offerings.value = await Purchases.getOfferings();
    } catch (e) {
      _log('Offerings failed: $e');
    }
  }

  /// 'year' or 'month' from the current offering, or from [offeringId].
  Package? package(String plan, {String? offeringId}) {
    final all = offerings.value;
    final o = offeringId == null ? all?.current : all?.getOffering(offeringId);
    if (o == null) return null;
    return plan == 'year' ? (o.annual ?? _first(o, PackageType.annual)) : (o.monthly ?? _first(o, PackageType.monthly));
  }

  static Package? _first(Offering o, PackageType type) {
    for (final p in o.availablePackages) {
      if (p.packageType == type) return p;
    }
    return null;
  }

  // ------------------------------------------------------------- actions

  Future<PurchaseOutcome> buy(Package p) async {
    if (!ready) return PurchaseOutcome.unavailable;
    if (busy.value) return PurchaseOutcome.cancelled;
    busy.value = true;
    try {
      final r = await Purchases.purchase(PurchaseParams.package(p));
      _apply(r.customerInfo);
      return PlusAccess.active.value ? PurchaseOutcome.success : PurchaseOutcome.pending;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      _log('Purchase error: $code');
      return switch (code) {
        PurchasesErrorCode.purchaseCancelledError => PurchaseOutcome.cancelled,
        PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
        _ => PurchaseOutcome.failed,
      };
    } finally {
      busy.value = false;
    }
  }

  /// True when Plus came back.
  Future<bool?> restore() async {
    if (!ready || busy.value) return null;
    busy.value = true;
    try {
      _apply(await Purchases.restorePurchases());
      return PlusAccess.active.value;
    } on PlatformException catch (e) {
      _log('Restore error: ${PurchasesErrorHelper.getErrorCode(e)}');
      return null;
    } finally {
      busy.value = false;
    }
  }

  /// "$4.17" from a yearly price ("$49.99" / 12), keeping the store's
  /// currency sign and decimal mark.
  static String monthlyOf(String priceString, double yearly) {
    final m = RegExp(r'\d[\d.,]*').firstMatch(priceString);
    if (m == null) return '';
    final n = m.group(0)!;
    var v = (yearly / 12).toStringAsFixed(2);
    if (n.contains(',') && !n.contains('.')) v = v.replaceAll('.', ',');
    return priceString.replaceRange(m.start, m.end, v);
  }

  void _log(String m) {
    if (kDebugMode) debugPrint('[Purchases] $m');
  }
}
