import 'package:flutter/material.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'safe_bottom.dart';

/// Standard bottom-sheet body: drag handle, optional icon, title, text,
/// then [children]. Use inside `Get.bottomSheet(..., isScrollControlled: true)`.
class KSheetFrame extends StatelessWidget {
  const KSheetFrame({
    super.key,
    required this.title,
    required this.children,
    this.sub,
    this.icon,
  });

  final String title;
  final String? sub;
  final Widget? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: k.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.sp)),
        ),
        padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 12.sp),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.sp,
                  height: 5.sp,
                  decoration: BoxDecoration(
                    color: k.border,
                    borderRadius: BorderRadius.circular(3.sp),
                  ),
                ),
              ),
              SizedBox(height: 16.sp),
              if (icon != null) ...[
                Align(alignment: Alignment.centerLeft, child: icon),
                SizedBox(height: 12.sp),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppText.h2.copyWith(fontSize: 22.sp, color: k.text),
                ),
              ),
              if (sub != null) ...[
                SizedBox(height: 6.sp),
                Text(
                  sub!,
                  style: AppText.bodyText.copyWith(
                    fontSize: 14.sp,
                    color: k.muted,
                  ),
                ),
              ],
              SizedBox(height: 16.sp),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded icon tile used at the top of sheets and cards.
class KIconTile extends StatelessWidget {
  const KIconTile({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 48,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.sp,
      height: size.sp,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size.sp / 3),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size.sp / 2, color: fg),
    );
  }
}

/// A card-coloured box that shows a strong border when [selected]
/// (ink in light mode, lime in dark). Used for single-choice rows and chips.
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.height,
    this.radius = 18,
    this.padding,
    this.alignment = Alignment.center,
    this.idleBorder,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  /// Border when not selected (for boxes sitting on a card).
  final Color? idleBorder;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final shape = BorderRadius.circular(radius.sp);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: k.card,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: height,
            constraints: BoxConstraints(minHeight: 44.sp),
            padding:
                padding ??
                EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
            alignment: alignment,
            decoration: BoxDecoration(
              borderRadius: shape,
              border: Border.all(
                color: selected
                    ? k.selectedBorder
                    : (idleBorder ?? Colors.transparent),
                width: 2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
