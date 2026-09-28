import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local reminders (dose day, daily tablet). No server involved.
///
/// Times are scheduled as exact instants in UTC, so no time-zone database
/// is needed. Each reminder is one-shot; [ReminderService] re-plans them
/// whenever the user logs, moves a dose or changes the schedule.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Called when the user taps a notification while the app is open.
  void Function(String payload)? onOpen;

  /// Payload of the notification that cold-started the app, until
  /// [takeLaunchPayload] reads it.
  String? _launchPayload;

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'dose_reminders',
    'Dose reminders',
    channelDescription: 'Your dose day and daily tablet reminders',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _android,
    iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      // Don't ask at start-up; we ask on the reminders screen, after the why.
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
        onDidReceiveNotificationResponse: (r) {
          final p = r.payload;
          if (p != null && p.isNotEmpty) onOpen?.call(p);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        _launchPayload = launch.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Returns the cold-start payload once, then null.
  String? takeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
  }

  /// Shows the system prompt (Android 13+ and iOS). Returns true when
  /// notifications are allowed. Older Android versions allow by default.
  Future<bool> requestPermission() async {
    try {
      await init();
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

  /// One-shot reminder at [when] (device local time). Past times are skipped.
  ///
  /// Uses inexact delivery on Android (may arrive a few minutes late) so the
  /// app does not need the exact-alarm permission.
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    try {
      await init();
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(when.toUtc(), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Could not schedule reminder $id: $e');
    }
  }

  Future<void> cancelIds(Iterable<int> ids) async {
    try {
      await init();
      for (final id in ids) {
        await _plugin.cancel(id: id);
      }
    } catch (e) {
      debugPrint('Could not cancel reminders: $e');
    }
  }
}
