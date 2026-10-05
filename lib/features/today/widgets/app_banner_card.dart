import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/app_links.dart';
import '../../../resources/colors.dart';
import '../../../services/app_status/app_status_service.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';

/// Backend announcement at the top of Today (`app_config` → `app.banner`).
/// Closing it hides that banner id for good.
class AppBannerCard extends StatelessWidget {
  const AppBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Get.find<AppStatusService>();
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Obx(() {
      s.dismissedBanner.value;
      final b = s.visibleBanner;
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: b == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: EdgeInsets.only(top: 14.sp),
                child: _Card(banner: b, dark: dark, onClose: s.dismissBanner),
              ),
      );
    });
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.banner,
    required this.dark,
    required this.onClose,
  });

  final AppBanner banner;
  final bool dark;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final warn = banner.level == 'warning';
    final bg = dark
        ? k.cardAlt
        : (warn ? AppColors.amberSoft : AppColors.limeSoft);
    final fg = dark
        ? k.text
        : (warn ? AppColors.amberText : AppColors.limeText);
    final url = banner.url;
    return Semantics(
      container: true,
      label: banner.text,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.sp, 12.sp, 6.sp, 12.sp),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18.sp),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.sp),
              child: Icon(
                warn ? PhosphorIconsBold.info : PhosphorIconsBold.bell,
                size: 18.sp,
                color: fg,
              ),
            ),
            SizedBox(width: 10.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.text,
                    style: AppText.small.copyWith(
                      fontSize: 13.5.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  if (url != null) ...[
                    SizedBox(height: 6.sp),
                    PressScale(
                      semanticLabel: 'Learn more',
                      onTap: () {
                        Haptics.instance.selectionClick();
                        AppLinks.open(url);
                      },
                      child: Text(
                        'Learn more ›',
                        style: AppText.title.copyWith(
                          fontSize: 13.sp,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CircleIconButton(
              icon: PhosphorIconsBold.x,
              label: 'Close message',
              size: 32.sp,
              background: Colors.transparent,
              foreground: fg,
              onTap: () {
                Haptics.instance.selectionClick();
                onClose();
              },
            ),
          ],
        ),
      ),
    );
  }
}
