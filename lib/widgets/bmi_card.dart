import 'package:flutter/material.dart';

import '../resources/bmi.dart';
import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// White card with the BMI number, a calm range tag and a four-band bar
/// with a sliding marker. Neutral colours on purpose: no red for weight.
class BmiCard extends StatelessWidget {
  const BmiCard({super.key, required this.bmi, this.showNote = true});

  final double bmi;
  final bool showNote;

  static const _bands = [
    (18.5, Color(0xFFCFE6F3)),
    (25.0, AppColors.lime),
    (30.0, Color(0xFFF7D9A8)),
    (Bmi.scaleMax, Color(0xFFF4C3AE)),
  ];

  (Color, Color) _tagColors(BmiRange r, bool dark) {
    final (bg, fg) = switch (r) {
      BmiRange.below => (AppColors.aquaSoft, AppColors.aquaText),
      BmiRange.healthy => (const Color(0xFFF1F7D6), AppColors.limeText),
      BmiRange.above => (const Color(0xFFFBEFD9), const Color(0xFF7A4E0B)),
      BmiRange.obesity => (AppColors.tangerineSoft, AppColors.tangerineText),
    };
    return dark ? (fg.withValues(alpha: 0.3), bg) : (bg, fg);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final range = Bmi.range(bmi);
    final (tagBg, tagFg) = _tagColors(range, dark);
    final label = Bmi.label(range);
    final pos = (bmi / Bmi.scaleMax).clamp(0.02, 0.98);

    return Semantics(
      liveRegion: true,
      label: 'BMI ${bmi.toStringAsFixed(1)}, $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.sp, 16.sp, 18.sp, 16.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(22.sp),
          boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 2.sp, offset: Offset(0, 1.sp))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BMI', style: AppText.caps.copyWith(fontSize: 12.sp, letterSpacing: 1, color: k.faint)),
                      SizedBox(height: 2.sp),
                      Text(bmi.toStringAsFixed(1), style: AppText.h1.copyWith(fontSize: 30.sp, height: 1, color: k.text)),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                  decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(12.sp)),
                  child: Text(label, style: AppText.title.copyWith(fontSize: 13.5.sp, color: tagFg)),
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final knob = 18.sp;
                return SizedBox(
                  height: knob,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.sp),
                        child: SizedBox(
                          height: 8.sp,
                          child: Row(
                            // Stretch so the empty colour boxes fill the 8px height.
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < _bands.length; i++)
                                Expanded(
                                  flex: ((_bands[i].$1 - (i == 0 ? 0 : _bands[i - 1].$1)) * 10).round(),
                                  child: ColoredBox(color: _bands[i].$2),
                                ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: w * pos - knob / 2,
                        child: Container(
                          width: knob,
                          height: knob,
                          decoration: BoxDecoration(
                            color: k.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: k.text, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 8.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in const ['Under', 'Healthy', 'Over', 'Obesity'])
                  Text(t, style: AppText.small.copyWith(fontSize: 11.5.sp, color: k.faint)),
              ],
            ),
            if (showNote) ...[
              SizedBox(height: 10.sp),
              Text(
                'BMI is a rough guide, not a diagnosis. Your doctor knows your full picture.',
                style: AppText.small.copyWith(fontSize: 12.sp, height: 1.4, fontWeight: FontWeight.w500, color: k.faint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
