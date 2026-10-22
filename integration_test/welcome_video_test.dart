// Records the clip that plays on the welcome screen
// (assets/video/welcome_demo.mp4). Not a regular test: it seeds demo data
// into the real app and taps through it at a calm pace, with a visible
// finger, while the simulator records. See tool/welcome_video/README.md.
//
//   tool/welcome_video/record.sh <simulator udid>
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kindose/features/today/today_controller.dart';
import 'package:kindose/features/today/widgets/next_bite_card.dart';
import 'package:kindose/main.dart' as app;
import 'package:kindose/models/user_profile.dart';
import 'package:kindose/resources/catalog.dart';
import 'package:kindose/resources/date_utils.dart';
import 'package:kindose/resources/routes.dart';
import 'package:kindose/services/debug/test_data.dart';
import 'package:kindose/services/plus/plus_access.dart';
import 'package:kindose/services/responsiveness/device_manager.dart';
import 'package:kindose/services/tracker_service.dart';
import 'package:kindose/widgets/body_map.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('welcome video', (tester) async {
    // main() installs its own error handlers; the test needs its own back.
    final onError = FlutterError.onError;
    await app.main();
    FlutterError.onError = onError;
    await _wait(4); // splash → welcome (no profile yet)

    // Demo profile: weekly Mounjaro, today is shot day, 16 weeks of logs.
    final t = Get.find<TrackerService>();
    final today = Dates.dateOnly(DateTime.now());
    await t.saveProfile(
      UserProfile.fromMap({
        'medicineId': 'mounjaro',
        'form': 'pen',
        'strengthMg': 5.0,
        'everyDays': 7,
        'shotWeekday': today.weekday,
        'shotMinutes': 9 * 60,
        'startWeightKg': 88.0,
        'goalWeightKg': 76.0,
        'proteinGoalG': 110,
        'waterGoalMl': 2500,
        'useKg': true,
        'remindersOn': false,
      })!,
    );
    await TestData.fill(t);
    await PlusAccess.setDebugPlus(true); // no paywall mid-video
    // The App Store rating prompt waits 3 days after the last ask.
    await Hive.box<dynamic>('settings').put(
      'reviewLastAt',
      DateTime.now().millisecondsSinceEpoch,
    );
    await t.dismissSetup();
    Get.offAllNamed<void>(Routes.home);
    await _wait(2.5);
    Get.find<TodayController>().dismissWeekly();
    await _wait(1);

    final f = _Finger(tester);
    _mark('start');
    await _wait(1.2);

    // Shot day → Log my dose.
    await f.tap(find.text('Log my dose'));
    await _waitFor(find.byType(BodyMap));
    await _wait(0.5);

    // Scroll to the body map and pick a fresh spot.
    await f.drag(const Offset(0, -330), from: const Offset(0.5, 0.62));
    await _wait(0.3);
    final recent = t.doses.take(3).map((d) => d.site).toSet();
    final spot = Catalog.sites.firstWhere(
      (s) => s.id != t.nextSiteId && !recent.contains(s.id),
    );
    final map = tester.getTopLeft(find.byType(BodyMap));
    final scale = 240.sp / 200;
    await f.tapAt(map + Offset(30.sp + spot.x * scale, spot.y * scale));
    await _wait(0.6);
    await f.tap(find.textContaining('Log dose ·'));
    await _waitFor(find.text('Done'));
    await _wait(2.0); // the tick and "Dose N logged"

    await f.tap(find.text('Done'));
    await _wait(0.7);

    // Next bite: add the first idea, the count goes up.
    await f.drag(const Offset(0, -150), from: const Offset(0.5, 0.6));
    await _wait(0.3);
    final add = find.descendant(
      of: find.byType(NextBiteCard),
      matching: find.textContaining(RegExp(r'^\+ \d+ g$')),
    );
    await f.tap(add.first);
    await _wait(1.4);

    // Progress, then the doctor report.
    await f.tap(find.byTooltip('Progress'));
    await _wait(1.8);
    await f.tap(find.byTooltip('Doctor report'));
    f.hide();
    await _wait(2.6);
    _mark('end');
    await _wait(0.5);
  });
}

/// Waits (up to 6 s) for [finder] to show up.
Future<void> _waitFor(Finder finder) async {
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await _wait(0.1);
  }
  if (finder.evaluate().isEmpty) {
    throw StateError('Not on screen: $finder (route ${Get.currentRoute})');
  }
}

Future<void> _wait(double seconds) =>
    Future<void>.delayed(Duration(milliseconds: (seconds * 1000).round()));

/// Prints when a part of the script happens, so the recording can be cut.
void _mark(String name) =>
    debugPrint('WELCOME_VIDEO $name ${DateTime.now().millisecondsSinceEpoch}');

/// A soft disc over the app that glides to each tap and follows drags,
/// like "show touches" in a screen recording.
class _Finger {
  _Finger(this.tester);

  final WidgetTester tester;
  final _state = ValueNotifier<_Touch>(const _Touch(null));
  OverlayEntry? _entry;

  /// Puts the disc back on top (pushed routes go above it).
  void _raise() {
    _entry?.remove();
    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: ValueListenableBuilder<_Touch>(
          valueListenable: _state,
          builder: (_, s, _) => CustomPaint(
            size: Size.infinite,
            painter: _TouchPainter(s),
          ),
        ),
      ),
    );
    Get.key.currentState!.overlay!.insert(entry);
    _entry = entry;
  }

  Future<void> _glide(Offset to, {double seconds = 0.38}) async {
    _raise();
    final from = _state.value.at ?? to + const Offset(40, 90);
    const frame = 1 / 60;
    for (var x = 0.0; x <= seconds; x += frame) {
      final p = Curves.easeInOutCubic.transform(math.min(1, x / seconds));
      _state.value = _Touch(Offset.lerp(from, to, p), shown: math.min(1, x * 6));
      await _wait(frame);
    }
    _state.value = _Touch(to);
  }

  Future<void> tap(Finder finder) => tapAt(tester.getCenter(finder.first));

  Future<void> tapAt(Offset at) async {
    await _glide(at);
    _state.value = _Touch(at, down: true);
    final g = await tester.startGesture(at);
    await _wait(0.12);
    await g.up();
    unawaited(_ripple(at));
  }

  Future<void> _ripple(Offset at) async {
    for (var r = 0.0; r <= 0.4; r += 1 / 60) {
      if (_state.value.at != at) return; // moved on
      _state.value = _Touch(at, ripple: r / 0.4);
      await _wait(1 / 60);
    }
  }

  /// Drags by [by], starting at [from] (fractions of the screen).
  Future<void> drag(Offset by, {required Offset from}) async {
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final start = Offset(size.width * from.dx, size.height * from.dy);
    await _glide(start);
    final g = await tester.startGesture(start);
    const steps = 30;
    for (var i = 1; i <= steps; i++) {
      final p = Curves.easeInOut.transform(i / steps);
      final q = Curves.easeInOut.transform((i - 1) / steps);
      await g.moveBy(by * (p - q));
      _state.value = _Touch(start + by * p, down: true);
      await _wait(1 / 60);
    }
    await g.up();
    _state.value = _Touch(start + by);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _Touch {
  const _Touch(this.at, {this.down = false, this.ripple = 0, this.shown = 1});

  final Offset? at;
  final bool down;
  final double ripple;
  final double shown;
}

class _TouchPainter extends CustomPainter {
  _TouchPainter(this.s);

  final _Touch s;

  static const _ink = Color(0xFF15142B);

  @override
  void paint(Canvas canvas, Size size) {
    final at = s.at;
    if (at == null) return;
    if (s.ripple > 0 && s.ripple < 1) {
      final r = 22 + 26 * Curves.easeOutCubic.transform(s.ripple);
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _ink.withValues(alpha: 0.25 * (1 - s.ripple)),
      );
    }
    final radius = s.down ? 19.0 : 22.0;
    canvas.drawCircle(
      at,
      radius,
      Paint()..color = _ink.withValues(alpha: (s.down ? 0.28 : 0.14) * s.shown),
    );
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.95 * s.shown),
    );
  }

  @override
  bool shouldRepaint(_TouchPainter old) => true;
}
