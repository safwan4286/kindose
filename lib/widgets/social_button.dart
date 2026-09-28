import 'package:flutter/material.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'press_scale.dart';

enum SocialProvider { apple, google }

/// "Continue with Apple / Google" pill, following each company's button
/// rules: Apple black (white in dark mode), Google white with a grey border
/// (dark grey in dark mode). The logos are the official assets in
/// assets/social/ — never redraw them.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.busy = false,
  });

  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool busy;

  static const Color _googleBorder = Color(0xFFDADCE0);
  static const Color _googleText = Color(0xFF1F1F1F);
  static const Color _googleDarkBg = Color(0xFF131314);
  static const Color _googleDarkBorder = Color(0xFF8E918F);
  static const Color _googleDarkText = Color(0xFFE3E3E3);

  @override
  Widget build(BuildContext context) {
    final dark = context.k.selectedBorder == AppColors.lime;
    final apple = provider == SocialProvider.apple;

    final Color bg;
    final Color fg;
    final Color? border;
    final String logo;
    if (apple) {
      bg = dark ? AppColors.white : Colors.black;
      fg = dark ? Colors.black : AppColors.white;
      border = null;
      logo = dark
          ? 'assets/social/apple_logo_black.png'
          : 'assets/social/apple_logo_white.png';
    } else {
      bg = dark ? _googleDarkBg : AppColors.white;
      fg = dark ? _googleDarkText : _googleText;
      border = dark ? _googleDarkBorder : _googleBorder;
      logo = 'assets/social/google_g.png';
    }
    final label = apple ? 'Continue with Apple' : 'Continue with Google';
    final enabled = onPressed != null && !busy;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 56.sp,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(28.sp),
            border: border == null
                ? null
                : Border.all(color: border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: busy
              ? SizedBox.square(
                  dimension: 22.sp,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      logo,
                      width: 20.sp,
                      height: 20.sp,
                      excludeFromSemantics: true,
                      // Logo not added yet: show the text alone.
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    SizedBox(width: 10.sp),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.button.copyWith(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: fg,
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
