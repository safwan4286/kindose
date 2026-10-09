import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash reports (Firebase Crashlytics), release builds only.
///
/// Health app rule: no personal or health data in reports. Only the app
/// version (automatic), the current screen and whether Plus is on — never
/// an email, medicine, dose, weight or note.
///
/// Needs the Firebase config files (`flutterfire configure`). Without them
/// the app runs normally and simply sends nothing.
class CrashReporting {
  CrashReporting._();

  static bool _on = false;

  /// True once reports are being sent.
  static bool get enabled => _on;

  static Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final c = FirebaseCrashlytics.instance;
      // Debug builds print errors to the console instead.
      await c.setCrashlyticsCollectionEnabled(!kDebugMode);
      if (kDebugMode) return;
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        previous?.call(details);
        c.recordFlutterFatalError(details);
      };
      // Errors outside Flutter's own callbacks (async gaps, isolates).
      PlatformDispatcher.instance.onError = (error, stack) {
        c.recordError(error, stack, fatal: true);
        return true;
      };
      _on = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Crash] not set up: $e');
    }
  }

  /// Route name only ("/log-dose"), never arguments.
  static void setScreen(String? route) {
    if (!_on || route == null || route.isEmpty) return;
    FirebaseCrashlytics.instance.setCustomKey('screen', route).ignore();
  }

  static void setPlus(bool plus) {
    if (!_on) return;
    FirebaseCrashlytics.instance.setCustomKey('plus', plus).ignore();
  }

  /// A caught error worth knowing about (not a crash). [reason] must not
  /// contain personal or health data.
  static void record(Object error, StackTrace? stack, {String? reason}) {
    if (!_on) return;
    FirebaseCrashlytics.instance
        .recordError(error, stack, reason: reason)
        .ignore();
  }
}
