import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// Rounded surface used for almost every block in the app.
class KCard extends StatelessWidget {
  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.radius = 26,
    this.onTap,
    this.border,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.k.card,
        borderRadius: shape,
        border: border,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(borderRadius: shape, onTap: onTap, child: content),
      ),
    );
  }
}

/// A Fluent 3D illustration. Decorative, so hidden from screen readers.
class ThreeD extends StatelessWidget {
  const ThreeD(this.asset, {super.key, this.size = 40});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
  }
}

/// Gently bobs its child up and down. Stays still when the user has
/// asked the system to reduce motion.
class Floaty extends StatefulWidget {
  const Floaty({
    super.key,
    required this.child,
    this.distance = 6,
    this.delayMs = 0,
  });

  final Widget child;
  final double distance;
  final int delayMs;

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted && !MediaQuery.disableAnimationsOf(context))
        _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -widget.distance * t),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Small on/off switch that matches the design.
/// Brand switch: ink track with a lime knob when on (lime track with an
/// ink knob in dark mode), soft grey with a white knob when off.
class KSwitch extends StatelessWidget {
  const KSwitch({super.key, required this.value, this.width = 44});

  final bool value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final w = width.sp;
    final h = w * 0.6;
    final pad = 3.sp;
    const duration = Duration(milliseconds: 200);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: w,
      height: h,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: value ? (dark ? AppColors.lime : AppColors.ink) : k.border,
        borderRadius: BorderRadius.circular(h / 2),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: duration,
          width: h - pad * 2,
          height: h - pad * 2,
          decoration: BoxDecoration(
            color: value
                ? (dark ? AppColors.ink : AppColors.lime)
                : AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.18),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width row with a label and a [KSwitch].
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
    this.leading,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        toggled: value,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.sp),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                if (leading != null) ...[leading!, SizedBox(width: 12.sp)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.title.copyWith(fontSize: 15.sp),
                      ),
                      if (sub != null)
                        Text(
                          sub!,
                          style: AppText.small.copyWith(
                            fontSize: 13.sp,
                            color: context.k.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 10.sp),
                KSwitch(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44 px round icon button (back, close, calendar …).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.label,
    this.size = 44,
    this.background,
    this.foreground,
  });

  final IconData icon;

  /// Null shows the button dimmed and disabled.
  final VoidCallback? onTap;
  final String label;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: background ?? context.k.card,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: PhosphorIcon(
                  icon,
                  size: size * 0.45,
                  color: foreground ?? context.k.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackCircle extends StatelessWidget {
  const BackCircle({
    super.key,
    required this.onTap,
    this.dark = false,
    this.size = 44,
  });

  final VoidCallback onTap;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      icon: PhosphorIconsBold.caretLeft,
      label: 'Back',
      onTap: onTap,
      size: size,
      background: dark ? const Color(0xFF22213F) : null,
      foreground: dark ? AppColors.white : null,
    );
  }
}

/// Upper-case section title.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppText.caps.copyWith(
          fontSize: 12.sp,
          color: color ?? context.k.muted,
        ),
      ),
    );
  }
}

/// Small rounded tag such as "PLUS" or "FREE".
class KTag extends StatelessWidget {
  const KTag(this.text, {super.key, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9.sp),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppText.tiny.copyWith(
          fontSize: 11.sp,
          color: fg,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Plus tag in brand colours.
class PlusTag extends StatelessWidget {
  const PlusTag({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return onDark
        ? const KTag('Plus', bg: AppColors.lime, fg: AppColors.hero)
        : KTag('Plus', bg: context.k.tint, fg: context.k.tintText);
  }
}

/// Rounded card that stacks settings rows with thin dividers.
class KGroup extends StatelessWidget {
  const KGroup({super.key, required this.children, this.padded = false});

  final List<Widget> children;

  /// Adds side padding for rows that have none of their own (switches).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.sp),
      child: ColoredBox(
        color: k.card,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padded ? 16.sp : 0),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: k.border,
                    indent: padded ? 0 : 16.sp,
                    endIndent: padded ? 0 : 16.sp,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small arrow that says "tap to open the full screen".
class OpenArrow extends StatelessWidget {
  const OpenArrow({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      width: 28.sp,
      height: 28.sp,
      margin: EdgeInsets.only(left: 8.sp),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: k.cardAlt, shape: BoxShape.circle),
      child: Icon(PhosphorIconsBold.caretRight, size: 14.sp, color: k.muted),
    );
  }
}

/// A big number with its unit ("40 g"): the number in the display font,
/// the unit smaller in the body font so it doesn't look heavy.
class NumberUnit extends StatelessWidget {
  const NumberUnit(
    this.number,
    this.unit, {
    super.key,
    required this.size,
    this.color,
    this.unitColor,
  });

  final String number;
  final String unit;

  /// Number size, already scaled (e.g. 30.sp).
  final double size;
  final Color? color;

  /// Defaults to [color].
  final Color? unitColor;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.k.text;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: number, style: AppText.number(size).copyWith(color: c)),
          TextSpan(
            text: ' $unit',
            style: AppText.title.copyWith(
              fontSize: (size * 0.5).clamp(12.0, 22.0),
              color: unitColor ?? c,
            ),
          ),
        ],
      ),
    );
  }
}
