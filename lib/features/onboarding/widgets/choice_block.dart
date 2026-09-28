import 'package:flutter/material.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/press_scale.dart';

/// Square answer tile with a big value and a small line under it
/// ("2.5 / mg", "Jun / ≈ Week 16"). Selected turns ink (lime in dark mode).
/// Use inside [ChoiceBlockGrid].
class ChoiceBlock extends StatelessWidget {
  const ChoiceBlock({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.sub,
    this.tag,
    this.semanticLabel,
  });

  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;

  /// Lime pill on the top edge, e.g. "START".
  final String? tag;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final onLime = k.selectedBorder == AppColors.lime;
    final fg = selected ? (onLime ? AppColors.ink : AppColors.white) : k.text;
    final subColor = selected
        ? (onLime ? AppColors.ink.withValues(alpha: 0.7) : AppColors.lime)
        : k.muted;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticLabel ?? [label, if (sub != null) sub!].join(' '),
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 0.97 : 1,
          duration: const Duration(milliseconds: 160),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 6.sp),
                decoration: BoxDecoration(
                  color: selected ? k.selectedBorder : k.card,
                  borderRadius: BorderRadius.circular(22.sp),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.05),
                      blurRadius: 2.sp,
                      offset: Offset(0, 1.sp),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppText.h1.copyWith(
                          fontSize: 26.sp,
                          height: 1,
                          letterSpacing: -0.8,
                          color: fg,
                        ),
                      ),
                    ),
                    if (sub != null) ...[
                      SizedBox(height: 4.sp),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          sub!,
                          style: AppText.small.copyWith(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: subColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tag != null)
                Positioned(
                  top: -8.sp,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.sp,
                      vertical: 2.sp,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Text(
                      tag!,
                      style: AppText.small.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-column grid of [ChoiceBlock]s with a staggered entrance.
class ChoiceBlockGrid extends StatelessWidget {
  const ChoiceBlockGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 88,
    this.columns = 3,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Tile height before `.sp` scaling.
  final double height;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(top: 8.sp),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12.sp,
        crossAxisSpacing: 10.sp,
        mainAxisExtent: height.sp,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) => itemBuilder(
        context,
        i,
      ).enter(motion, delay: 140 + i.clamp(0, 8) * 40, dy: 0.12),
    );
  }
}
