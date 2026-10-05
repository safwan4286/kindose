import 'package:get/get.dart';

import '../../resources/routes.dart';
import '../../services/app_status/app_status_service.dart';
import '../../services/backend/backend_service.dart';
import '../../services/tracker_service.dart';

/// Decides where the app goes after the splash animation.
///
/// * No plan yet → Welcome.
/// * A plan but no account (from before sign-in was required) → Save your
///   data, once, until they sign in.
/// * Otherwise → Home.
class SplashController extends GetxController {
  final TrackerService _tracker = Get.find<TrackerService>();
  bool _left = false;

  /// Called by the screen when the animation ends (or right away when the
  /// user has "reduce motion" on). Safe to call more than once.
  void goNext() {
    if (_left) return;
    _left = true;
    // Too old for the server (cached from the last config): update first.
    if (Get.isRegistered<AppStatusService>() &&
        Get.find<AppStatusService>().mustUpdate.value) {
      Get.offAllNamed<void>(Routes.update);
      return;
    }
    if (!_tracker.hasProfile) {
      Get.offAllNamed<void>(Routes.welcome);
      return;
    }
    final backend = Get.isRegistered<BackendService>()
        ? Get.find<BackendService>()
        : null;
    // Without a backend (keys missing) the app still works on the phone.
    final needsAccount = backend != null && backend.ready && !backend.signedIn;
    Get.offAllNamed<void>(needsAccount ? Routes.saveData : Routes.home);
  }
}
