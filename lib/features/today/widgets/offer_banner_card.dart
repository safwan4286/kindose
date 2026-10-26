import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../resources/routes.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/offers/offer_service.dart';
import '../../../services/plus/plus_access.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';
import '../../offer/offer_controller.dart';
import '../../offer/offer_countdown.dart';

/// While a timed offer is open: "30% off Kindose Plus · Ends in 18h 20m"
/// at the top of Today, leading back to the offer. Gone when the window
/// ends, when they get Plus, or after its ×.
class OfferBannerCard extends StatelessWidget {
  const OfferBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final offers = Get.find<OfferService>();
    return Obx(() {
      offers.config.value;
      offers.startedAt.value;
      offers.bannerHidden.value;
      PlusAccess.active.value;
      final end = offers.endsAt;
      final show = offers.bannerVisible && end != null;
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: !show
            ? const SizedBox(width: double.infinity)
            : OfferTicker(
                endsAt: end,
                period: const Duration(seconds: 30),
                builder: (context, left) => left == Duration.zero
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.only(top: 14.sp),
                        child: _Card(
                          percent: offers.config.value.discountPercent,
                          left: left,
                          onClose: offers.hideBanner,
                        ),
                      ),
              ),
      );
    });
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.percent,
    required this.left,
    required this.onClose,
  });

  final int percent;
  final Duration left;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final ends = offerLeftShort(left);
    return PressScale(
      semanticLabel:
          '$percent percent off Kindose Plus. Ends in $ends. Opens the offer',
      onTap: () {
        Haptics.instance.selectionClick();
        Get.toNamed<void>(
          Routes.offer,
          arguments: const OfferArgs(fromOnboarding: false),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(12.sp, 12.sp, 6.sp, 12.sp),
        decoration: BoxDecoration(
          color: AppColors.hero,
          borderRadius: BorderRadius.circular(20.sp),
          border: dark ? Border.all(color: k.border) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46.sp,
              height: 46.sp,
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(14.sp),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.sp),
                  child: Text(
                    '$percent%',
                    style: AppText.title.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$percent% off Kindose Plus',
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsBold.timer,
                          size: 13.sp,
                          color: AppColors.lime,
                        ),
                        SizedBox(width: 4.sp),
                        Text(
                          'Ends in $ends',
                          style: AppText.small.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.heroMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              PhosphorIconsBold.caretRight,
              size: 16.sp,
              color: AppColors.lime,
            ),
            CircleIconButton(
              icon: PhosphorIconsBold.x,
              label: 'Hide offer banner',
              size: 36.sp,
              background: Colors.transparent,
              foreground: AppColors.heroMuted,
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
