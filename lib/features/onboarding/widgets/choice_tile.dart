import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';

/// One answer row in an onboarding question: optional icon tile, title,
/// optional subtitle and a radio (single choice) or checkbox (multi choice).
///
/// The tile only draws the state. The caller decides what a tap does
/// (select, haptic, advance), which keeps the logic in the controller.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.sub,
    this.leading,
    this.superscript,
    this.tag,
    this.multi = false,
  });

  final String title;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;

  /// Usually a [ChoiceIcon].
  final Widget? leading;

  /// Small raised mark after the title, e.g. "®" for brand names.
  final String? superscript;

  /// Small lime pill next to the title, e.g. "USUAL FOR MOUNJARO®".
  final String? tag;

  /// Checkbox instead of radio.
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: !multi,
      label: [
        title,
        if (tag != null) tag!.toLowerCase(),
        if (sub != null) sub!,
      ].join('. '),
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 0.985 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.fromLTRB(
              leading == null ? 18.sp : 14.sp,
              14.sp,
              16.sp,
              14.sp,
            ),
            decoration: BoxDecoration(
              color: k.card,
              borderRadius: BorderRadius.circular(24.sp),
              border: Border.all(
                color: selected ? k.selectedBorder : k.card,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  blurRadius: 2.sp,
                  offset: Offset(0, 1.sp),
                ),
              ],
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, SizedBox(width: 14.sp)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tag == null)
                        _Title(title: title, superscript: superscript)
                      else
                        Wrap(
                          spacing: 8.sp,
                          runSpacing: 4.sp,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Title(title: title, superscript: superscript),
                            _Tag(tag!),
                          ],
                        ),
                      if (sub != null) ...[
                        SizedBox(height: 2.sp),
                        Text(
                          sub!,
                          style: AppText.bodyText.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: k.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.sp),
                _Indicator(selected: selected, multi: multi),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = context.k.selectedBorder == AppColors.lime;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.lime.withValues(alpha: 0.16)
            : const Color(0xFFF1F7D6),
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Text(
        text,
        style: AppText.small.copyWith(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: dark ? AppColors.lime : AppColors.limeText,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.title, this.superscript});

  final String title;
  final String? superscript;

  @override
  Widget build(BuildContext context) {
    final style = AppText.title.copyWith(
      fontSize: 17.sp,
      height: 1.25,
      color: context.k.text,
    );
    if (superscript == null) return Text(title, style: style);
    return Text.rich(
      TextSpan(
        text: title,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: EdgeInsets.only(left: 1.sp),
              child: Text(
                superscript!,
                style: style.copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: context.k.muted,
                ),
              ),
            ),
          ),
        ],
      ),
      style: style,
    );
  }
}

/// Radio (circle) or checkbox (rounded square) that fills with the
/// selection colour and pops a check mark in.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.selected, required this.multi});

  final bool selected;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final size = 26.sp;
    // Ink fill with a lime check in light mode, lime fill with an ink check in dark.
    final checkColor = k.selectedBorder == AppColors.lime
        ? AppColors.ink
        : AppColors.lime;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? k.selectedBorder : Colors.transparent,
        borderRadius: BorderRadius.circular(multi ? 8.sp : size / 2),
        border: Border.all(
          color: selected ? k.selectedBorder : k.border,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: PhosphorIcon(
            PhosphorIconsBold.check,
            size: 14.sp,
            color: checkColor,
          ),
        ),
      ),
    );
  }
}

/// Tinted square with a 3D illustration, used as [ChoiceTile.leading].
class ChoiceIcon extends StatelessWidget {
  const ChoiceIcon(this.asset, {super.key, required this.tint});

  final String asset;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54.sp,
      height: 54.sp,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18.sp),
      ),
      alignment: Alignment.center,
      child: ThreeD(asset, size: 36.sp),
    );
  }
}

/// Tinted square with a short number or symbol ("7", "14", "?"), used as
/// [ChoiceTile.leading] when an illustration would be noise.
class ChoiceGlyph extends StatelessWidget {
  const ChoiceGlyph(String this.text, {super.key, required this.tint})
    : icon = null;

  /// Same tile with an icon instead of text.
  const ChoiceGlyph.icon(IconData this.icon, {super.key, required this.tint})
    : text = null;

  final String? text;
  final IconData? icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.sp,
      height: 46.sp,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(15.sp),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? PhosphorIcon(icon!, size: 22.sp, color: context.k.text)
          : Text(
              text!,
              style: AppText.h1.copyWith(
                fontSize: 16.sp,
                letterSpacing: -0.2,
                color: context.k.text,
              ),
            ),
    );
  }
}
