import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kindose/widgets/safe_bottom.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import 'offer_controller.dart';

/// One-time discount after closing the paywall (canvas E2). Close and
/// "No thanks" are always visible; no fake timers.
class OfferScreen extends GetView<OfferController> {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final c = controller.config;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.close();
      },
      child: Scaffold(
        backgroundColor: k.bg,
        body: KSafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: CircleIconButton(
                    icon: PhosphorIconsBold.x,
                    label: 'Close',
                    size: 40.sp,
                    background: k.card,
                    onTap: controller.close,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 16.sp),
                  children: [
                    Center(child: _Badge(percent: c.discountPercent, motion: motion)),
                    SizedBox(height: 22.sp),
                    Semantics(
                      header: true,
                      child: Text(
                        c.title,
                        textAlign: TextAlign.center,
                        style: AppText.h1.copyWith(fontSize: 30.sp, height: 1.08, letterSpacing: -1, color: k.text),
                      ),
                    ).enter(motion, delay: 120),
                    SizedBox(height: 8.sp),
                    Text(
                      controller.subtitle,
                      textAlign: TextAlign.center,
                      style: AppText.bodyStrong.copyWith(fontSize: 14.5.sp, fontWeight: FontWeight.w600, color: k.muted),
                    ).enter(motion, delay: 160),
                    SizedBox(height: 20.sp),
                    _PriceCard(controller: controller).enter(motion, delay: 200),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 8.sp),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => PillButton(label: c.cta, busy: controller.busy.value, onPressed: controller.claim)),
                    SizedBox(height: 8.sp),
                    KBottomPadding(
                      child: Text(
                        c.finePrint,
                        textAlign: TextAlign.center,
                        style: AppText.small.copyWith(fontSize: 12.5.sp, height: 1.4, color: k.muted),
                      ),
                    ),
                    // LinkButton(label: 'No thanks', onTap: controller.close, color: k.muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tilted lime tile with the discount; pops in once.
class _Badge extends StatelessWidget {
  const _Badge({required this.percent, required this.motion});

  final int percent;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final tile = Semantics(
      label: '$percent percent off',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: -0.07,
        child: Container(
          width: 132.sp,
          height: 132.sp,
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(36.sp),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.14), blurRadius: 30.sp, offset: Offset(0, 16.sp)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                child: Text(
                  '$percent%',
                  style: AppText.h1.copyWith(fontSize: 46.sp, height: 1, letterSpacing: -2, color: AppColors.ink),
                ),
              ),
              Text('OFF', style: AppText.small.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
    if (!motion) return tile;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
      ),
      child: tile,
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.controller});

  final OfferController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller.config;
    return Container(
      padding: EdgeInsets.all(18.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
        border: Border.all(color: k.selectedBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  c.offerPrice,
                  style: AppText.h1.copyWith(fontSize: 34.sp, height: 1.1, letterSpacing: -1, color: k.text),
                ),
              ),
              SizedBox(width: 10.sp),
              Text(
                c.regularPrice,
                semanticsLabel: 'was ${c.regularPrice}',
                style: AppText.bodyStrong.copyWith(
                  fontSize: 16.sp,
                  color: k.faint,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: k.faint,
                ),
              ),
              const Spacer(),
              if (c.perMonth.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
                  decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(8.sp)),
                  child: Text(
                    c.perMonth.toUpperCase(),
                    style: AppText.tiny.copyWith(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.sp),
          Text(
            c.priceNote,
            style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: k.muted),
          ),
          if (c.perks.isNotEmpty) ...[
            SizedBox(height: 12.sp),
            Divider(height: 1, color: k.border),
            SizedBox(height: 12.sp),
            for (final perk in c.perks)
              Padding(
                padding: EdgeInsets.only(bottom: 8.sp),
                child: Row(
                  children: [
                    Icon(PhosphorIconsBold.check, size: 17.sp, color: k.selectedBorder == AppColors.lime ? AppColors.lime : AppColors.limeText),
                    SizedBox(width: 10.sp),
                    Expanded(
                      child: Text(perk, style: AppText.bodyStrong.copyWith(fontSize: 14.sp, color: k.text)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
