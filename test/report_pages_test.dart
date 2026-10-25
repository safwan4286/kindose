// Report preview pages: double-tap zooms, and every page can be reached
// while zoomed in.
// Run with:
//   fvm flutter test test/report_pages_test.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindose/features/report/widgets/report_pages.dart';
import 'package:kindose/services/responsiveness/device_manager.dart';
import 'package:kindose/services/theme/theme.dart';

Future<ui.Image> _page() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 595, 842),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(595, 842);
}

void main() {
  testWidgets('double-tap zooms; last page reachable while zoomed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pages = (await tester.runAsync(
      () => Future.wait([_page(), _page(), _page()]),
    ))!;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) {
          DeviceManager.instance.initWith(MediaQuery.of(context));
          return child!;
        },
        home: Scaffold(body: PageStack(pages: pages)),
      ),
    );

    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();

    final centre = tester.getCenter(find.byType(PageStack));
    await tester.tapAt(centre);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(centre);
    await tester.pumpAndSettle();
    expect(scale(), closeTo(2.5, 0.01));

    // Drag up a long way: the last page comes into view, still zoomed.
    for (var i = 0; i < 12; i++) {
      await tester.dragFrom(centre, const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    expect(scale(), closeTo(2.5, 0.01));
    final last = tester.getRect(find.bySemanticsLabel('Report page 3 of 3'));
    expect(last.overlaps(Offset.zero & const Size(402, 700)), isTrue);

    // Double-tap again: back to full width.
    await tester.tapAt(centre);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(centre);
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, 0.01));

    for (final p in pages) {
      p.dispose();
    }
  });
}
