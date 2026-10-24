import 'package:get/get.dart';

import '../../resources/routes.dart';
import '../../widgets/no_internet_sheet.dart';
import '../../widgets/sign_in_sheet.dart';
import '../../services/backend/backend_service.dart';
import '../../services/haptics/haptics.dart';
import '../../widgets/toast.dart';
import '../../resources/app_links.dart';

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

  /// "I already have an account": sign in (Apple or Google) and bring the
  /// cloud backup to this phone. No backup yet → normal set-up.
  Future<void> signIn() async {
    if (_navigating) return;
    Haptics.instance.lightImpact();
    final provider = await chooseSignIn(
      title: 'Welcome back',
      sub: 'Sign in with the account you backed up to.',
    );
    if (provider == null) return;
    final backend = Get.find<BackendService>();
    _navigating = true;
    backend.autoPaused = true;
    try {
      final r = await backend.signIn(provider);
      switch (r) {
        case BackendResult.ok:
          break;
        case BackendResult.cancelled:
          return;
        case BackendResult.offline:
          await showNoInternetSheet(what: 'Signing in');
          return;
        case BackendResult.notReady:
          showToast('Sign-in is being set up. Tap Get started for now.');
          return;
        case BackendResult.failed:
          showToast('Sign-in didn’t work this time. Please try again.');
          return;
      }
      final check = await backend.checkBackup();
      if (!check.ok) {
        // Couldn't look: don't start a new plan that could replace a backup.
        await backend.signOut();
        await showNoInternetSheet(what: 'Getting your backup');
        return;
      }
      final cloud = check.backup;
      if (cloud == null) {
        // New account: the plan they set up now is theirs.
        await backend.claimLocal();
        showToast('No backup yet for this account. Let’s set things up.');
        Get.toNamed<void>(Routes.onboarding);
        return;
      }
      if (await backend.restore(cloud) == BackendResult.ok) {
        Haptics.instance.mediumImpact();
        Get.offAllNamed<void>(Routes.home);
        showToast('Welcome back. Your data is restored.');
      } else {
        await backend.signOut();
        showToast('Couldn’t restore the backup. Please try again.');
      }
    } finally {
      backend.autoPaused = false;
      _navigating = false;
    }
  }

  void openTerms() {
    Haptics.instance.selectionClick();
    AppLinks.open(AppLinks.termsUrl);
  }

  void openPrivacy() {
    Haptics.instance.selectionClick();
    AppLinks.open(AppLinks.privacyUrl);
  }
}
