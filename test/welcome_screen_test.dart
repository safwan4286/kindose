// Welcome screen with the demo clip: fits small to large phones, light and
// dark, large text and the tablet width cap.
// (Widget tests can't play video, so the phone shows the poster here.)
// Run with:
//   fvm flutter test test/welcome_screen_test.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kindose/features/welcome/welcome_controller.dart';
import 'package:kindose/features/welcome/welcome_screen.dart';
import 'package:kindose/features/welcome/widgets/demo_video.dart';
import 'package:kindose/services/responsiveness/device_manager.dart';
import 'package:kindose/services/theme/theme.dart';

/// The app's own fonts, so text has its real width (the default test font
/// draws every letter as a wide square).
Future<void> _loadFonts() async {
  final fonts =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final f in fonts.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(f['family'] as String);
    for (final font in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  // Same width cap (kMaxAppWidth) and text-size cap as main.dart.
  const maxWidth = 520.0;
  for (final (name, size, textScale, dark, reduceMotion) in [
    ('small phone', const Size(320, 568), 1.0, false, false),
    ('small phone, largest text', const Size(375, 667), 1.6, false, false),
    ('iPhone 17', const Size(402, 874), 1.0, false, false),
    ('large phone, dark mode', const Size(440, 956), 1.0, true, false),
    ('tablet, reduce motion', const Size(1024, 1366), 1.35, false, true),
  ]) {
    testWidgets('welcome screen fits: $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.testMode = true;
      Get.put(WelcomeController());
      addTearDown(Get.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final data = mq.copyWith(
              size: Size(math.min(mq.size.width, maxWidth), mq.size.height),
              disableAnimations: reduceMotion,
              textScaler: TextScaler.linear(textScale)
                  .clamp(maxScaleFactor: 1.35),
            );
            DeviceManager.instance.initWith(data);
            return MediaQuery(
              data: data,
              child: Center(
                child: SizedBox(width: data.size.width, child: child),
              ),
            );
          },
          home: const WelcomeScreen(),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(DemoScreen), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    });
  }
}
