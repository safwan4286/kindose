import 'package:get/get.dart';

import '../../resources/routes.dart';
import '../../services/tracker_service.dart';

/// Decides where the app goes after the splash animation.
class SplashController extends GetxController {
  final TrackerService _tracker = Get.find<TrackerService>();
  bool _left = false;

  /// Called by the screen when the animation ends (or right away when the
  /// user has "reduce motion" on). Safe to call more than once.
  void goNext() {
    if (_left) return;
    _left = true;
    Get.offAllNamed<void>(_tracker.hasProfile ? Routes.home : Routes.welcome);
  }
}
