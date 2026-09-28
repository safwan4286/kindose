import 'package:flutter/material.dart';

/// Brand colours that look the same in light and dark mode.
class AppColors {
  AppColors._();

  static const Color violet = Color(0xFF5B4BFF);
  static const Color violetDark = Color(0xFF4336D9);
  static const Color violetSoft = Color(0xFFE8E5FF);

  static const Color lime = Color(0xFFD6F84C);
  static const Color limeSoft = Color(0xFFF1FBD2);
  static const Color limeText = Color(0xFF3E5205);

  static const Color tangerine = Color(0xFFF08A5D); // protein
  static const Color tangerineSoft = Color(0xFFFBE9E0);
  static const Color tangerineText = Color(0xFF9A3F17);

  static const Color aqua = Color(0xFF4AA8D8); // water
  static const Color aquaSoft = Color(0xFFE3F1F8);
  static const Color aquaText = Color(0xFF1E6A93);

  static const Color ink = Color(0xFF15142B); // logo ink, primary in palette B
  static const Color paper = Color(0xFFF6F5F1);
  static const Color hero = Color(0xFF15142B);
  static const Color heroMuted = Color(0xFFB9B7D6);

  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFDE8E8);
  static const Color dangerText = Color(0xFF6B1414);

  // Gentle warnings ("used last time", "already logged").
  static const Color amberSoft = Color(0xFFFDEFD9);
  static const Color amberWash = Color(0xFFFDF6EA);
  static const Color amberText = Color(0xFF8A4B00);

  /// Top level on the "How did it feel?" dots.
  static const Color pain = Color(0xFFE0603A);

  static const Color white = Color(0xFFFFFFFF);

  static const primary = Color(0xff0F67FE);
  static const black = Colors.black;
  static const red = Colors.red;
  static const Color lightGreyTextColor = Color(0xff808080);
  static const Color darkGreyColor161616 = Color(0xff161616);
  static const Color lightThemeGreyBorderColor = Color(0xffe0e0e0);
  static const Color lightThemeBlackColor = Color(0xff121212);
  static const Color darkGrayColor = Color(0xffB2B2B2);
  static const Color darkGreyColor = Color(0xff202123);
  static const Color darkRedColor = Color(0xffB31E1B);
  static const common5D6A85 = Color(0xff5D6A85);
  static const greyDCE1E8 = Color(0xffDCE1E8);
  static const common252B3D = Color(0xFF252B3D);
  static const Color lightThemeTextFieldColor = Color(0xffF3F5F8);
  static const Color lightThemePrimaryColor = Color(0xff272829);
  static const Color lightThemeTertairyColor = Color(0xffF3F5F8);
  static const Color lightThemeSecondaryColor = Color(0xffFFFFFF);
  static const Color lightThemeLightGreyTextColor = Color(0xff939394);
  static const Color lightThemeScaffoldColor = Colors.white;
  static const Color darkThemePrimaryColor = Color(0xff212121);
  static const Color darkThemeTextFieldColor = Color(0xff1E1C1E);
  static const Color darkThemeLightGreyTextColor = Color(0xff939394);
  static const Color darkThemeScaffoldColor = Color(0xff111527);
  static const Color darkThemeSecondaryColor = Color(0xff292929);
  static const Color darkThemeTertairyColor = Color(0xff343434);
  static const shadowColor = Color(0x0D090E1D);
  static const Color teal1A9E6E = Color(0xFF1A9E6E);
  static const black242E49 = Color(0xff242E49);
  static const common535862 = Color(0xFF535862);
  static const Color grey414651 = Color(0xFF414651);
  static const Color borderColorE6E7EA = Color(0xffE6E7EA);
}

/// Surface and text colours that change between light and dark mode.
/// Read them with `context.k` (see [KColorsX]).
@immutable
class KColors extends ThemeExtension<KColors> {
  const KColors({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.faint,
    required this.border,
    required this.selectedBg,
    required this.selectedBorder,
    required this.nav,
    required this.navActiveBg,
    required this.navActiveFg,
    required this.fab,
    required this.fabIcon,
    required this.tint,
    required this.tintText,
    required this.proteinTrack,
    required this.waterEmpty,
    required this.waterEdge,
  });

  final Color bg;
  final Color card;
  final Color cardAlt;
  final Color text;
  final Color textSoft;
  final Color muted;
  final Color faint;
  final Color border;
  final Color selectedBg;
  final Color selectedBorder;
  final Color nav;
  final Color navActiveBg;
  final Color navActiveFg;
  final Color fab;
  final Color fabIcon;
  final Color tint;
  final Color tintText;
  final Color proteinTrack;
  final Color waterEmpty;
  final Color waterEdge;

  // Palette B · "Calm Paper" (approved). Ink + lime come from the logo.
  static const KColors light = KColors(
    bg: Color(0xFFF6F5F1),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFEEEDE7),
    text: AppColors.ink,
    textSoft: Color(0xFF3A3946),
    muted: Color(0xFF6B6A76),
    faint: Color(0xFF9A99A3),
    border: Color(0xFFE7E5DE),
    selectedBg: Color(0xFFF1F0EA),
    selectedBorder: AppColors.ink,
    nav: Color(0xFFFFFFFF),
    navActiveBg: AppColors.ink,
    navActiveFg: AppColors.lime,
    fab: AppColors.lime,
    fabIcon: AppColors.ink,
    tint: Color(0xFFEEEDE7),
    tintText: AppColors.ink,
    proteinTrack: AppColors.tangerineSoft,
    waterEmpty: Color(0xFFFFFFFF),
    waterEdge: Color(0xFFCFE6F3),
  );

  static const KColors dark = KColors(
    bg: Color(0xFF0F0E1A),
    card: Color(0xFF1A1928),
    cardAlt: Color(0xFF23222F),
    text: Color(0xFFF4F3EE),
    textSoft: Color(0xFFDCDAD3),
    muted: Color(0xFFA3A1AC),
    faint: Color(0xFF74727E),
    border: Color(0xFF2C2B38),
    selectedBg: Color(0xFF26252F),
    selectedBorder: AppColors.lime,
    nav: Color(0xFF1A1928),
    navActiveBg: AppColors.lime,
    navActiveFg: AppColors.ink,
    fab: AppColors.lime,
    fabIcon: AppColors.ink,
    tint: Color(0xFF23222F),
    tintText: Color(0xFFF4F3EE),
    proteinTrack: Color(0xFF3A2419),
    waterEmpty: Color(0xFF1A1928),
    waterEdge: Color(0xFF1F4A60),
  );

  @override
  KColors copyWith({Color? bg, Color? card, Color? text}) {
    return KColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      cardAlt: cardAlt,
      text: text ?? this.text,
      textSoft: textSoft,
      muted: muted,
      faint: faint,
      border: border,
      selectedBg: selectedBg,
      selectedBorder: selectedBorder,
      nav: nav,
      navActiveBg: navActiveBg,
      navActiveFg: navActiveFg,
      fab: fab,
      fabIcon: fabIcon,
      tint: tint,
      tintText: tintText,
      proteinTrack: proteinTrack,
      waterEmpty: waterEmpty,
      waterEdge: waterEdge,
    );
  }

  @override
  KColors lerp(ThemeExtension<KColors>? other, double t) {
    if (other is! KColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return KColors(
      bg: l(bg, other.bg),
      card: l(card, other.card),
      cardAlt: l(cardAlt, other.cardAlt),
      text: l(text, other.text),
      textSoft: l(textSoft, other.textSoft),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      border: l(border, other.border),
      selectedBg: l(selectedBg, other.selectedBg),
      selectedBorder: l(selectedBorder, other.selectedBorder),
      nav: l(nav, other.nav),
      navActiveBg: l(navActiveBg, other.navActiveBg),
      navActiveFg: l(navActiveFg, other.navActiveFg),
      fab: l(fab, other.fab),
      fabIcon: l(fabIcon, other.fabIcon),
      tint: l(tint, other.tint),
      tintText: l(tintText, other.tintText),
      proteinTrack: l(proteinTrack, other.proteinTrack),
      waterEmpty: l(waterEmpty, other.waterEmpty),
      waterEdge: l(waterEdge, other.waterEdge),
    );
  }
}

extension KColorsX on BuildContext {
  KColors get k => Theme.of(this).extension<KColors>() ?? KColors.light;
}
