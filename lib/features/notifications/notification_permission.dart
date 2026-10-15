import '../../services/notifications/notification_service.dart';
import '../../widgets/toast.dart';

/// Asks the phone before a reminder is turned on. When notifications are
/// blocked (the user said no before), shows a toast with a Settings button
/// that opens Kindose's notification settings. True when allowed.
Future<bool> askForNotifications() async {
  final notes = NotificationService.instance;
  if (await notes.requestPermission()) return true;
  showActionToast('Notifications are off for Kindose', 'Settings', () async {
    if (!await notes.openSettings()) {
      showToast('Open Settings › Kindose › Notifications and turn them on.');
    }
  });
  return false;
}
