import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/press_scale.dart';

/// Share PDF and Download side by side: the same size and shape, icon
/// first, Share filled as the main action. Without Plus both show a lock
/// and open the Plus screen.
class ReportActions extends StatelessWidget {
  const ReportActions({
    super.key,
    required this.plus,
    required this.sharing,
    required this.saving,
    required this.onShare,
    required this.onDownload,
  });

  final bool plus;
  final bool sharing;
  final bool saving;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final lock = PhosphorIconsBold.lockSimple;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Share PDF',
            icon: plus ? PhosphorIconsBold.shareNetwork : lock,
            primary: true,
            busy: sharing,
            onTap: onShare,
          ),
        ),
        SizedBox(width: 10.sp),
        Expanded(
          child: _ActionButton(
            label: 'Download',
            icon: plus ? PhosphorIconsBold.downloadSimple : lock,
            primary: false,
            busy: saving,
            onTap: onDownload,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    // Ink in light mode, lime in dark mode, like the app's main buttons.
    final dark = k.selectedBorder == AppColors.lime;
    final bg = primary ? (dark ? AppColors.lime : AppColors.ink) : k.card;
    final fg = primary ? (dark ? AppColors.ink : AppColors.white) : k.text;
    final accent = primary ? (dark ? AppColors.ink : AppColors.lime) : k.text;
    return Semantics(
      button: true,
      enabled: !busy,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: busy ? null : onTap,
        child: Container(
          height: 54.sp,
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(27.sp),
            border: primary ? null : Border.all(color: k.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 18.sp,
                child: busy
                    ? CircularProgressIndicator(strokeWidth: 2, color: accent)
                    : PhosphorIcon(icon, size: 18.sp, color: accent),
              ),
              SizedBox(width: 8.sp),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button.copyWith(fontSize: 16.sp, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
