import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/app_status/app_status_service.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';

/// Shown instead of everything else when this version is below the
/// backend's `min_version`. No way back: the old version may not work
/// with the server any more. Data on the phone is untouched.
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  Future<void> _openStore() async {
    Haptics.instance.lightImpact();
    final url = AppStatusService.storeUrl;
    if (url == null) {
      showToast('Open the App Store to update Kindose.');
      return;
    }
    try {
      if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))
        return;
    } catch (_) {}
    showToast('Open your app store to update Kindose.');
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final s = Get.find<AppStatusService>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: k.bg,
        body: KSafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.sp, 24.sp, 24.sp, 12.sp),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96.sp,
                  height: 96.sp,
                  decoration: const BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ThreeD(Img3d.sparkles, size: 52.sp),
                ).enter(motion, dy: 0.1),
                SizedBox(height: 24.sp),
                Obx(
                  () => Semantics(
                    header: true,
                    child: Text(
                      s.updateTitle.value,
                      textAlign: TextAlign.center,
                      style: AppText.h1.copyWith(
                        fontSize: 30.sp,
                        color: k.text,
                      ),
                    ),
                  ),
                ).enter(motion, delay: 80, dy: 0.12),
                SizedBox(height: 10.sp),
                Obx(
                  () => Text(
                    s.updateMessage.value,
                    textAlign: TextAlign.center,
                    style: AppText.bodyText.copyWith(
                      fontSize: 15.sp,
                      height: 1.45,
                      color: k.muted,
                    ),
                  ),
                ).enter(motion, delay: 130, dy: 0.12),
                const Spacer(),
                KBottomPadding(
                  child: PillButton(
                    label: 'Update Kindose',
                    ink: true,
                    onPressed: _openStore,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
