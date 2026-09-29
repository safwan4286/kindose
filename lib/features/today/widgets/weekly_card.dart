import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_widgets.dart';
import '../today_controller.dart';
import '../weekly_summary.dart';

/// "Your week" card at the top of Today, once a week until dismissed.
class WeeklyCard extends GetView<TodayController> {
  const WeeklyCard({super.key, required this.summary});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final s = summary;
    final rows = <List<WeeklyTile>>[
      for (var i = 0; i < s.tiles.length; i += 2)
        s.tiles.sublist(i, i + 2 > s.tiles.length ? s.tiles.length : i + 2),
    ];
    return Semantics(
      container: true,
      label: 'Your week, ${s.range}. ${s.headline}',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(color: dark ? AppColors.lime : AppColors.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.sp, vertical: 4.sp),
                  decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(9.sp)),
                  child: Text(
                    'YOUR WEEK',
                    style: AppText.caps.copyWith(fontSize: 11.sp, letterSpacing: 1, color: AppColors.ink),
                  ),
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: Text(
                    s.week == null ? s.range : '${s.range} · week ${s.week}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: k.muted),
                  ),
                ),
                CircleIconButton(
                  icon: PhosphorIconsBold.x,
                  label: 'Hide until next week',
                  onTap: controller.dismissWeekly,
                  size: 32.sp,
                  background: k.cardAlt,
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            Text(
              s.headline,
              style: AppText.h2.copyWith(fontSize: 22.sp, height: 1.12, color: k.text),
            ),
            SizedBox(height: 14.sp),
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) SizedBox(height: 8.sp),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _Tile(tile: row[0])),
                    SizedBox(width: 8.sp),
                    Expanded(
                      child: row.length > 1 ? _Tile(tile: row[1]) : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
            if (s.waterLine != null) ...[
              SizedBox(height: 10.sp),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
                decoration: BoxDecoration(
                  color: dark ? AppColors.lime.withValues(alpha: 0.14) : AppColors.limeSoft,
                  borderRadius: BorderRadius.circular(14.sp),
                ),
                child: Text(
                  s.waterLine!,
                  style: AppText.small.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: dark ? AppColors.lime : AppColors.limeText,
                  ),
                ),
              ),
            ],
            SizedBox(height: 12.sp),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: 'See my progress',
                    onPressed: controller.openProgressFromWeekly,
                    background: dark ? AppColors.lime : AppColors.ink,
                    foreground: dark ? AppColors.ink : AppColors.white,
                    height: 46,
                  ),
                ),
                SizedBox(width: 8.sp),
                SoftButton(
                  label: 'Got it',
                  onPressed: controller.dismissWeekly,
                  background: k.cardAlt,
                  height: 46,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile});

  final WeeklyTile tile;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final strip = tile.strip;
    return Semantics(
      label: '${tile.caps.toLowerCase()}: ${tile.value}${tile.sub == null ? '' : ', ${tile.sub}'}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(16.sp)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tile.caps, style: AppText.caps.copyWith(fontSize: 11.sp, letterSpacing: 1, color: k.faint)),
            SizedBox(height: 4.sp),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(tile.value, style: AppText.h2.copyWith(fontSize: 20.sp, color: k.text)),
            ),
            if (tile.sub != null)
              Text(
                tile.sub!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.small.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700, color: k.muted),
              ),
            if (strip != null) ...[
              SizedBox(height: 8.sp),
              Row(
                children: [
                  for (final (i, hit) in strip.indexed) ...[
                    if (i > 0) SizedBox(width: 4.sp),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 300 + i * 60),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Opacity(
                          opacity: v,
                          child: Container(
                            height: 8.sp,
                            decoration: BoxDecoration(
                              color: hit ? (dark ? AppColors.lime : AppColors.ink) : k.border,
                              borderRadius: BorderRadius.circular(4.sp),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
