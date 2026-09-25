import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../resources/colors.dart';
import '../services/theme/theme.dart';

/// Main call to action: ink pill with a lime circle on the right.
/// Pass `onPressed: null` to disable. [busy] blocks double taps while
/// something is saving.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = PhosphorIconsBold.arrowRight,
    this.busy = false,
    this.lime = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  /// Lime pill for dark screens.
  final bool lime;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final bg = lime
        ? AppColors.lime
        : context.k.fab == AppColors.lime
        ? AppColors.lime
        : AppColors.ink;
    final fg = bg == AppColors.lime ? AppColors.ink : AppColors.white;
    final circle = bg == AppColors.lime ? AppColors.ink : AppColors.lime;
    final circleIcon = bg == AppColors.lime ? AppColors.lime : AppColors.ink;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: enabled ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.button.copyWith(color: fg),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: circle,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: busy
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: circleIcon,
                                ),
                              )
                            : PhosphorIcon(icon, size: 20, color: circleIcon),
                      ),
                    ),
                  ],
                ),
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

/// Segmented control, e.g. 1M / 3M / All or Mild / Moderate / Severe.
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: darkSelected ? k.card : k.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: o == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: dense ? 32 : 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: o == selected
                          ? (darkSelected ? k.text : k.card)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      labelOf(o),
                      style: AppText.small.copyWith(
                        fontWeight: FontWeight.w800,
                        color: o == selected
                            ? (darkSelected ? k.bg : k.text)
                            : k.muted,
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
