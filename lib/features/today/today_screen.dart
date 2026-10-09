import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/press_scale.dart';
import '../home/home_screen.dart';
import 'today_controller.dart';
import 'widgets/dose_card.dart';
import 'widgets/app_banner_card.dart';
import 'widgets/edit_today_sheet.dart';
// Hidden for now (6 Oct): FreeWeekStrip, WeekEndedCard, LockedCard.
// import 'widgets/free_week.dart';
import 'widgets/next_bite_card.dart';
import 'widgets/today_cards.dart';
import 'widgets/weekly_card.dart';

/// Today tab: header, optional set-up list, the dose card, then the cards
/// in the user's own order (Edit Today).
class TodayScreen extends GetView<TodayController> {
  const TodayScreen({super.key});

  static Widget _card(String id) => switch (id) {
    'bite' => const NextBiteCard(),
    'protein' => const ProteinCard(),
    'water' => const WaterCard(),
    'weight' => const WeightCard(),
    'feel' => const FeelCard(),
    'tip' => const TipCard(),
    'log' => const TodayLogCard(),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      bottom: false,
      child: Obx(() {
        controller.watch();
        if (controller.profile == null) return const SizedBox.shrink();
        final cards = controller.visibleCards;
        // Soft paywall (6 Oct): after the free week everything stays
        // visible; actions open Plus (AccessService.allow).
        final weekly = controller.weekly;
        var delay = 120;
        return ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, kNavClearance),
          children: [
            const TodayHeader().enter(motion, dy: 0.1),
            const AppBannerCard(),
            // Free week strip hidden for now (6 Oct). Bring back with:
            // if (controller.showFreeStrip) ...[
            //   SizedBox(height: 14.sp),
            //   const FreeWeekStrip().enter(motion, delay: 30, dy: 0.1),
            // ],
            if (controller.showSetup) ...[
              SizedBox(height: 18.sp),
              const SetupCard().enter(motion, delay: 40, dy: 0.1),
            ],
            // Once a week until "Got it"; shrinks away when hidden.
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: weekly == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(
                        top: controller.showSetup ? 12.sp : 18.sp,
                      ),
                      child: WeeklyCard(
                        key: ValueKey(weekly.key),
                        summary: weekly,
                      ).enter(motion, delay: 40, dy: 0.1),
                    ),
            ),
            SizedBox(
              height: controller.showSetup || weekly != null ? 12.sp : 18.sp,
            ),
            const DoseCard().enter(motion, delay: 80, dy: 0.1),
            // "Free week has ended" card hidden for now (6 Oct):
            // if (controller.locked) ...[
            //   SizedBox(height: 12.sp),
            //   const WeekEndedCard().enter(motion, delay: 120, dy: 0.1),
            // ],
            for (final id in cards) ...[
              SizedBox(height: id == 'log' ? 20.sp : 12.sp),
              KeyedSubtree(
                key: ValueKey(id),
                child: _card(id),
              ).enter(motion, delay: delay += 60, dy: 0.1),
            ],
            SizedBox(height: 16.sp),
            Center(
                child: Semantics(
                  button: true,
                  label: 'Edit Today',
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: showEditTodaySheet,
                    child: Container(
                      height: 44.sp,
                      padding: EdgeInsets.symmetric(horizontal: 18.sp),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.sp),
                        border: Border.all(color: k.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsBold.arrowsDownUp,
                            size: 18.sp,
                            color: k.text,
                          ),
                          SizedBox(width: 8.sp),
                          Text(
                            'Edit Today',
                            style: AppText.bodyStrong.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: k.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
