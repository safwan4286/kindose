import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Product analytics (Firebase Analytics), release builds only.
///
/// Health app rule: events say what was done, never the data. No email,
/// medicine, dose, weight, food or note goes into an event or parameter.
class Analytics {
  Analytics._();

  static FirebaseAnalytics? get _fa {
    if (kDebugMode) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  /// Route name only ("/log-dose"), never arguments.
  static void screen(String? route) {
    if (route == null || route.isEmpty) return;
    final name = route.startsWith('/') ? route.substring(1) : route;
    _fa?.logScreenView(screenName: name, screenClass: name).ignore();
  }

  /// 'apple' or 'google'.
  static void signIn(String method) =>
      _fa?.logLogin(loginMethod: method).ignore();

  /// Set-up finished. [signedIn] false = "Not now" (phone only).
  static void onboardingDone({required bool signedIn}) =>
      _log('onboarding_complete', {'signed_in': signedIn ? 'yes' : 'no'});

  static void paywallView({required bool fromOnboarding}) =>
      _log('paywall_view', {'from': fromOnboarding ? 'onboarding' : 'app'});

  static void offerView() => _log('offer_view');

  /// A timed offer's window ended without a purchase (logged once).
  static void offerExpired() => _log('offer_expired');

  /// [plan] is the RevenueCat package ('\$rc_annual'), [offering] its
  /// offering ('default' or 'offer_30'). No price: the stores report revenue.
  static void plusPurchase({required String plan, required String offering}) =>
      _log('plus_purchase', {'plan': plan, 'offering': offering});

  static void plusRestore() => _log('plus_restore');

  static void _log(String name, [Map<String, Object>? params]) =>
      _fa?.logEvent(name: name, parameters: params).ignore();
}
