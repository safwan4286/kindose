import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/water_units.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../services/tracker_service.dart';
import '../../widgets/ask_number.dart';

/// Daily protein and water goals, editable from Me and from the Protein
/// and Water screens.
abstract final class GoalEdit {
  static TrackerService get _tracker => Get.find<TrackerService>();

  static Future<void> protein(BuildContext context) async {
    final p = _tracker.profile.value;
    if (p == null) return;
    Haptics.instance.selectionClick();
    final v = await askNumber(
      context,
      title: 'Daily protein goal',
      unit: 'g',
      initial: p.proteinGoalG.toDouble(),
      min: 30,
      max: 250,
      decimals: 0,
    );
    if (v == null || v.isNaN) return;
    await _tracker.saveProfile(p.copyWith(proteinGoalG: v.round()));
  }

  static Future<void> water(BuildContext context) async {
    final p = _tracker.profile.value;
    if (p == null) return;
    Haptics.instance.selectionClick();
    final oz = p.useOz;
    final v = await askNumber(
      context,
      title: 'Daily water goal',
      unit: oz ? 'fl oz' : 'L',
      initial: oz
          ? Water.toOz(p.waterGoalMl).roundToDouble()
          : p.waterGoalMl / 1000,
      min: oz ? 34 : 1,
      max: oz ? 203 : 6,
      decimals: oz ? 0 : 1,
    );
    if (v == null || v.isNaN) return;
    final ml = oz ? Water.fromOz(v) : (v * 1000).round();
    await _tracker.saveProfile(p.copyWith(waterGoalMl: ml));
  }
}

/// "of 95 g ✎" next to a big total: tap to change the goal.
class GoalLink extends StatelessWidget {
  const GoalLink({
    super.key,
    required this.text,
    required this.onTap,
    this.fontSize = 16,
  });

  final String text;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.sp),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AppText.title.copyWith(
                fontSize: fontSize.sp,
                color: k.muted,
              ),
            ),
            SizedBox(width: 5.sp),
            Icon(
              PhosphorIconsBold.pencilSimple,
              size: (fontSize - 3).sp,
              color: k.faint,
            ),
          ],
        ),
      ),
    );
  }
}
