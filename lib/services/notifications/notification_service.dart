import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local reminders (dose day, protein, water). No server involved.
/// For now this only sets up the plugin and asks for permission;
/// scheduling comes with the reminders feature.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Don't ask at start-up; we ask on the reminders screen, after the why.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(settings: const InitializationSettings(android: android, iOS: darwin));
    _ready = true;
  }

  /// Shows the system prompt (Android 13+ and iOS). Returns true when
  /// notifications are allowed. Older Android versions allow by default.
  Future<bool> requestPermission() async {
    try {
      await _init();
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? true;
      }
      if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      return false;
    } catch (_) {
      // A plugin error must never block onboarding; reminders stay off.
      return false;
    }
  }
}
