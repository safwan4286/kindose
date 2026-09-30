import 'package:get/get.dart';

import '../../resources/routes.dart';
import '../../services/backend/backend_service.dart';
import '../../services/haptics/haptics.dart';
import '../../widgets/toast.dart';
import '../legal/legal_sheet.dart';

/// First screen for new users: start onboarding or sign in.
class WelcomeController extends GetxController {
  bool _navigating = false;

  void getStarted() {
    if (_navigating) return;
    _navigating = true;
    Haptics.instance.mediumImpact();
    Get.toNamed<void>(
      Routes.onboarding,
    )?.whenComplete(() => _navigating = false);
  }

  /// "I already have an account": sign in with Google and bring the
  /// cloud backup to this phone. No backup yet → normal set-up.
  Future<void> signIn() async {
    if (_navigating) return;
    Haptics.instance.lightImpact();
    final backend = Get.find<BackendService>();
    _navigating = true;
    backend.autoPaused = true;
    try {
      final r = await backend.signInWithGoogle();
      switch (r) {
        case BackendResult.ok:
          break;
        case BackendResult.cancelled:
          return;
        case BackendResult.offline:
          showToast('You seem to be offline. Try again when connected.');
          return;
        case BackendResult.notReady:
          showToast('Sign-in is being set up. Tap Get started for now.');
          return;
        case BackendResult.failed:
          showToast('Sign-in didn’t work this time. Please try again.');
          return;
      }
      CloudBackup? cloud;
      try {
        cloud = await backend.fetchBackup();
      } catch (_) {}
      if (cloud == null) {
        showToast('No backup yet for this account. Let’s set things up.');
        Get.toNamed<void>(Routes.onboarding);
        return;
      }
      if (await backend.restore(cloud) == BackendResult.ok) {
        Haptics.instance.mediumImpact();
        Get.offAllNamed<void>(Routes.home);
        showToast('Welcome back. Your data is restored.');
      } else {
        showToast('Couldn’t restore the backup. Please try again.');
      }
    } finally {
      backend.autoPaused = false;
      _navigating = false;
    }
  }

  void openLegal() {
    Haptics.instance.selectionClick();
    showLegalSheet();
  }
}
