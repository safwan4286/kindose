import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'press_scale.dart';

/// The app's main call to action: ink pill with a lime arrow circle
/// (lime pill with an ink circle in dark mode, or when [lime] is set for
/// dark screens). Use it for every primary "Continue / Save / Get started".
///
/// Pass `onPressed: null` to disable. [busy] shows a spinner and blocks
/// double taps while something is saving. Haptics stay with the caller,
/// because the right strength depends on what the tap does.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = PhosphorIconsBold.arrowRight,
    this.busy = false,
    this.lime = false,
    this.ink = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  /// Lime pill for dark screens.
  final bool lime;

  /// Always ink, even in dark mode (for use on a lime card).
  final bool ink;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    // Ink in light mode, lime in dark mode (selectedBorder is lime there).
    final bg = ink
        ? AppColors.ink
        : lime || context.k.selectedBorder == AppColors.lime
            ? AppColors.lime
            : AppColors.ink;
    final onLime = bg == AppColors.lime;
    final fg = onLime ? AppColors.ink : AppColors.white;
    final circle = onLime ? AppColors.ink : AppColors.lime;
    final circleIcon = onLime ? AppColors.lime : AppColors.ink;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.45,
        child: PressScale(
          onTap: enabled ? onPressed : null,
          child: Container(
            constraints: BoxConstraints(minHeight: 60.sp),
            padding: EdgeInsets.fromLTRB(24.sp, 8.sp, 8.sp, 8.sp),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(30.sp),
              boxShadow: enabled
                  ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.18), blurRadius: 18.sp, offset: Offset(0, 8.sp))]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppText.button.copyWith(fontSize: 17.sp, color: fg),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.sp),
                Container(
                  width: 44.sp,
                  height: 44.sp,
                  decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: busy
                      ? SizedBox(
                          width: 18.sp,
                          height: 18.sp,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: circleIcon),
                        )
                      : PhosphorIcon(icon, size: 20.sp, color: circleIcon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet text button under a main CTA ("Skip for now", "I already have an
/// account"). 44pt tall for an easy tap.
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        // Sizes to its text (never infinite width), so it works in a Row
        // too. Min 44pt tall and padded sideways for an easy tap.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 44.sp, minWidth: 44.sp),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: 15.sp, color: color ?? context.k.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain rounded button: filled or outlined.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground,
    this.outlined = false,
    this.height = 54,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;
  final bool outlined;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? context.k.text;
    final radius = BorderRadius.circular(height / 2);
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: Material(
        color: outlined ? Colors.transparent : (background ?? context.k.card),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: outlined ? BorderSide(color: fg, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, box) {
                final text = Text(
                  label,
                  style: AppText.button.copyWith(fontSize: 16, color: fg),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: box.hasBoundedWidth
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        PhosphorIcon(
                          icon ?? Icons.no_accounts,
                          size: 18,
                          color: fg,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (box.hasBoundedWidth) Flexible(child: text) else text,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggleable chip used for symptoms, foods and filters.
class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.selectedColor,
    this.selectedText,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Color? selectedColor;
  final Color? selectedText;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final bg = selected ? (selectedColor ?? k.text) : k.card;
    final fg = selected ? (selectedText ?? k.bg) : k.textSoft;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: EdgeInsets.fromLTRB(leading == null ? 14 : 8, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    label,
                    style: AppText.small.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w800,
                    ),
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

/// Segmented switch (kg | lb, Pen | Vial, cm | ft · in). The selected
/// segment slides in as a raised card (or ink with [darkSelected]); every
/// change gives a selection tick.
class KSegmented<T> extends StatelessWidget {
  const KSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.dense = false,
    this.darkSelected = false,
  });

  final List<T> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final bool dense;

  /// Selected segment in ink instead of card colour.
  final bool darkSelected;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: EdgeInsets.all(4.sp),
      decoration: BoxDecoration(
        color: darkSelected ? k.card : k.cardAlt,
        borderRadius: BorderRadius.circular(18.sp),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: o == selected,
                inMutuallyExclusiveGroup: true,
                label: labelOf(o),
                excludeSemantics: true,
                child: PressScale(
                  pressedScale: 0.95,
                  onTap: () {
                    if (o == selected) return;
                    Haptics.instance.selectionClick();
                    onChanged(o);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: (dense ? 34 : 42).sp,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: o == selected ? (darkSelected ? k.text : k.card) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14.sp),
                      boxShadow: o == selected && !darkSelected
                          ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 6.sp, offset: Offset(0, 2.sp))]
                          : null,
                    ),
                    child: Text(
                      labelOf(o),
                      style: AppText.title.copyWith(
                        fontSize: (dense ? 13.5 : 15).sp,
                        color: o == selected ? (darkSelected ? k.bg : k.text) : k.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
