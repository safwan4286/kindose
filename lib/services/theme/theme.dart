import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../resources/colors.dart';

/// Type scale. Colours come from the theme (DefaultTextStyle) unless a
/// widget sets one on purpose.
class AppText {
  AppText._();

  static const String display = 'Bricolage';
  static const String body = 'Figtree';

  static const TextStyle h1 = TextStyle(
    fontFamily: display,
    fontSize: 30,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: display,
    fontSize: 19,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );

  static TextStyle number(double size) => TextStyle(
    fontFamily: display,
    fontSize: size,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: size >= 40 ? -2 : -0.5,
  );

  static const TextStyle caps = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
  );

  static const TextStyle title = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle small = TextStyle(
    fontFamily: body,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle tiny = TextStyle(
    fontFamily: body,
    fontSize: 11,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle button = TextStyle(
    fontFamily: body,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, KColors.light);
  static ThemeData get dark => _build(Brightness.dark, KColors.dark);

  static ThemeData _build(Brightness brightness, KColors k) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.violet,
      onPrimary: AppColors.white,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      surface: k.card,
      onSurface: k.text,
      error: AppColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppText.body,
      scaffoldBackgroundColor: k.bg,
      extensions: <ThemeExtension<dynamic>>[k],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: AppText.body,
        bodyColor: k.text,
        displayColor: k.text,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: k.bg,
        foregroundColor: k.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: k.bg,
        modalBackgroundColor: k.bg,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.violet,
        inactiveTrackColor: k.border,
        thumbColor: AppColors.violet,
        overlayColor: AppColors.violet.withValues(alpha: 0.12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.bodyStrong.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: k.card,
        hintStyle: AppText.bodyText.copyWith(color: k.faint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.violet, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: k.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
