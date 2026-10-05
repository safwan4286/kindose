import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/routes.dart';
import '../../services/backend/backend_service.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/no_internet_sheet.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/social_button.dart';
import '../../widgets/toast.dart';
import '../me/widgets/me_sheets.dart';

/// Phones that already have data but no account (from before sign-in was
/// required). Shown once at start until they sign in; their data then
/// moves into the account. There is no way around it: every plan lives in
/// an account now.
class SaveDataBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<SaveDataController>(SaveDataController.new);
}

class SaveDataController extends GetxController {
  final BackendService backend = Get.find<BackendService>();

  /// Which sign-in is running, for the button spinner.
  final Rxn<SocialProvider> signingIn = Rxn<SocialProvider>();

  Future<void> signIn(SocialProvider provider) async {
    if (signingIn.value != null) return;
    Haptics.instance.lightImpact();
    if (provider == SocialProvider.apple) {
      showToast(
        'Sign in with Apple is coming soon. Please use Google for now.',
      );
      return;
    }
    signingIn.value = provider;
    backend.autoPaused = true;
    try {
      final r = await backend.signInWithGoogle();
      switch (r) {
        case BackendResult.ok:
          break;
        case BackendResult.cancelled:
          return;
        case BackendResult.offline:
          await showNoInternetSheet(what: 'Signing in');
          return;
        case BackendResult.notReady:
        case BackendResult.failed:
          showToast('Sign-in didn’t work this time. Please try again.');
          return;
      }
      final check = await backend.checkBackup();
      if (!check.ok) {
        await backend.signOut();
        await showNoInternetSheet(what: 'Checking your account');
        return;
      }
      final cloud = check.backup;
      if (cloud != null) {
        final useSaved = await showWelcomeBackSheet(
          backup: cloud,
          otherLabel: "Keep this phone's data",
          otherNote:
              "This phone's data replaces what is saved in your account.",
        );
        if (useSaved == null) {
          await backend.signOut();
          return;
        }
        if (useSaved) {
          if (await backend.restore(cloud) != BackendResult.ok) {
            await backend.signOut();
            showToast('Couldn’t load your saved data. Please try again.');
            return;
          }
          _done('Welcome back. Your data is ready.');
          return;
        }
      }
      // No saved data yet, or "Keep this phone's data".
      await backend.claimLocal();
    } finally {
      signingIn.value = null;
      backend.autoPaused = false;
    }
    await backend.backupNow();
    _done('Saved to your account.');
  }

  void _done(String message) {
    Haptics.instance.mediumImpact();
    Get.offAllNamed<void>(Routes.home);
    showToast(message);
  }
}

class SaveDataScreen extends GetView<SaveDataController> {
  const SaveDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: k.bg,
        body: KSafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(24.sp, 40.sp, 24.sp, 16.sp),
                  children: [
                    Center(
                      child: Container(
                        width: 92.sp,
                        height: 92.sp,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsBold.shieldCheck,
                          size: 44.sp,
                          color: AppColors.ink,
                        ),
                      ),
                    ).enter(motion, dy: 0.1),
                    SizedBox(height: 26.sp),
                    Semantics(
                      header: true,
                      child: Text(
                        'Save your data',
                        textAlign: TextAlign.center,
                        style: AppText.h1.copyWith(
                          fontSize: 30.sp,
                          color: k.text,
                        ),
                      ),
                    ).enter(motion, delay: 80, dy: 0.12),
                    SizedBox(height: 10.sp),
                    Text(
                      'Kindose now keeps every plan in your account, so it is safe on any phone. '
                      'Sign in once and the doses and weigh-ins on this phone move into it.',
                      textAlign: TextAlign.center,
                      style: AppText.bodyText.copyWith(
                        fontSize: 14.5.sp,
                        height: 1.45,
                        color: k.muted,
                      ),
                    ).enter(motion, delay: 130, dy: 0.12),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 8.sp),
                child: Obx(() {
                  final busy = controller.signingIn.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ios) ...[
                        SocialButton(
                          provider: SocialProvider.apple,
                          busy: busy == SocialProvider.apple,
                          onPressed: busy != null
                              ? null
                              : () => controller.signIn(SocialProvider.apple),
                        ),
                        SizedBox(height: 10.sp),
                      ],
                      SocialButton(
                        provider: SocialProvider.google,
                        busy: busy == SocialProvider.google,
                        onPressed: busy != null
                            ? null
                            : () => controller.signIn(SocialProvider.google),
                      ),
                      SizedBox(height: 12.sp),
                      KBottomPadding(
                        child: Text(
                          'Only your name and email are shared with Kindose.\nWe never sell your data.',
                          textAlign: TextAlign.center,
                          style: AppText.small.copyWith(
                            fontSize: 12.sp,
                            height: 1.45,
                            color: k.faint,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
