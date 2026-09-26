import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Status / navigation bar style for a screen. Both bars are transparent so
/// the page colour runs edge to edge (no white strip under the content on
/// Android), and icons flip to stay readable.
class KSystemUi {
  KSystemUi._();

  /// [darkBackground]: the page behind the bars is dark (ink hero, dark mode).
  static SystemUiOverlayStyle style({required bool darkBackground}) {
    final icons = darkBackground ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      // iOS reads this one: the brightness of what's *behind* the status bar.
      statusBarBrightness: darkBackground ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      // Android 15 adds a translucent scrim behind 3-button nav unless this is off.
      systemNavigationBarContrastEnforced: false,
    );
  }

  /// Call once in main(): draw behind the system bars on every Android version
  /// (Android 15+ already does this by default).
  static Future<void> enableEdgeToEdge() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
