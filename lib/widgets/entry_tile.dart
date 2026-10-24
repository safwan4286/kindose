import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../resources/colors.dart';
import '../services/plus/access_service.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'k_widgets.dart';

/// One logged food or drink, the same everywhere it is listed: a 3D icon
/// on a soft tile, the name with its portion and time below, and the
/// amount on the right. Name and sub never share a line, so long names
/// don't push the amount off.
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.sub,
    required this.amount,
    required this.amountColor,
    this.divider = true,
    this.padding,
  });

  final String icon;
  final Color tint;
  final String title;
  final String sub;
  final String amount;
  final Color amountColor;

  /// A hairline above (off for the first row).
  final bool divider;

  /// Defaults to vertical only (rows inside a card's own padding).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      decoration: BoxDecoration(
        color: k.card,
        border: divider ? Border(top: BorderSide(color: k.border)) : null,
      ),
      padding: padding ?? EdgeInsets.symmetric(vertical: 10.sp),
      child: Row(
        children: [
          Container(
            width: 40.sp,
            height: 40.sp,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(13.sp),
            ),
            alignment: Alignment.center,
            child: ThreeD(icon, size: 26.sp),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(
                    fontSize: 14.5.sp,
                    color: k.text,
                  ),
                ),
                SizedBox(height: 1.sp),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: k.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.sp),
          Text(
            amount,
            // Small amount: body font, equal-width digits.
            style: AppText.title.copyWith(
              fontSize: 15.sp,
              color: amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipe left to remove, with the red trash background. Paywall first; a
/// locked swipe springs back.
class SwipeToRemove extends StatelessWidget {
  const SwipeToRemove({
    super.key,
    required this.id,
    required this.onRemove,
    required this.child,
  });

  final String id;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Dismissible(
        key: ValueKey('swipe-$id'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => AccessService.ensure(),
        onDismissed: (_) => onRemove(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 12.sp),
          color: AppColors.dangerSoft,
          child: Icon(
            PhosphorIconsBold.trash,
            size: 18.sp,
            color: AppColors.danger,
          ),
        ),
        child: child,
      ),
    );
  }
}
