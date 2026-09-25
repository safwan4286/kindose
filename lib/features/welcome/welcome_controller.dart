import 'package:get/get.dart';

import '../../resources/routes.dart';
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
    Get.toNamed<void>(Routes.onboarding)?.whenComplete(() => _navigating = false);
  }

  /// Google / Apple sign-in arrives with the account step (Firebase Auth).
  /// Until then, say so clearly instead of opening an empty screen.
  void signIn() {
    Haptics.instance.lightImpact();
    showToast('Sign in with Google or Apple is coming in the next update.');
  }

  void openLegal() {
    Haptics.instance.selectionClick();
    showLegalSheet();
  }
}
