import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';

/// The PDF's pages stacked in one zoomable view: pinch or double-tap to
/// zoom, and every page stays reachable while zoomed in.
class ReportPages extends StatefulWidget {
  const ReportPages({super.key, required this.build});

  final Future<Uint8List> Function() build;

  @override
  State<ReportPages> createState() => _ReportPagesState();
}

class _ReportPagesState extends State<ReportPages> {
  List<ui.Image>? _pages;
  bool _failed = false;
  bool _started = false;

  static const double _a4Inches = 8.27;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Sharp at about 1.6× zoom on this screen without huge page images.
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final dpi = (width * dpr * 1.6 / _a4Inches).clamp(120.0, 260.0);
    _load(dpi);
  }

  Future<void> _load(double dpi) async {
    try {
      final bytes = await widget.build();
      final pages = <ui.Image>[];
      await for (final page in Printing.raster(bytes, dpi: dpi)) {
        pages.add(await page.toImage());
      }
      if (!mounted) {
        for (final p in pages) {
          p.dispose();
        }
        return;
      }
      setState(() => _pages = pages);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    for (final p in _pages ?? const <ui.Image>[]) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    if (_failed) {
      return Center(
        child: Text(
          "Couldn't show the report",
          style: AppText.title.copyWith(color: context.k.muted),
        ),
      );
    }
    if (pages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageStack(pages: pages);
  }
}

/// Page images in one column inside an [InteractiveViewer].
class PageStack extends StatefulWidget {
  const PageStack({super.key, required this.pages});

  final List<ui.Image> pages;

  @override
  State<PageStack> createState() => _PageStackState();
}

class _PageStackState extends State<PageStack>
    with SingleTickerProviderStateMixin {
  final _view = TransformationController();
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<Matrix4>? _zoomAnim;
  Offset _tapAt = Offset.zero;
  final _content = GlobalKey();

  static const double _maxScale = 4;
  static const double _doubleTapScale = 2.5;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final a = _zoomAnim;
      if (a != null) _view.value = a.value;
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    _view.dispose();
    super.dispose();
  }

  /// Zooms in around the tap, or back out when already zoomed.
  void _toggleZoom() {
    final viewport = context.size;
    final content = _content.currentContext?.size;
    if (viewport == null || content == null) return;
    final now = _view.value.getMaxScaleOnAxis();
    final s = now > 1.01 ? 1.0 : _doubleTapScale;
    // Keep the tapped spot under the finger (zooming out: the same spot
    // down the pages), without showing past the edges.
    final focus = _view.toScene(_tapAt);
    final dx = s == 1
        ? 0.0
        : (_tapAt.dx - focus.dx * s).clamp(
            viewport.width - content.width * s,
            0.0,
          );
    final dy = (_tapAt.dy - focus.dy * s).clamp(
      viewport.height - content.height * s,
      0.0,
    );
    final end = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
    _zoomAnim = Matrix4Tween(
      begin: _view.value,
      end: end,
    ).animate(CurvedAnimation(parent: _zoom, curve: Curves.easeOutCubic));
    _zoom.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        onDoubleTapDown: (d) => _tapAt = d.localPosition,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _view,
          constrained: false,
          minScale: 1,
          maxScale: _maxScale,
          boundaryMargin: EdgeInsets.zero,
          onInteractionStart: (_) => _zoom.stop(),
          child: ConstrainedBox(
            key: _content,
            constraints: BoxConstraints(
              minWidth: box.maxWidth,
              maxWidth: box.maxWidth,
              minHeight: box.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 20.sp),
              child: Column(
                children: [
                  for (var i = 0; i < pages.length; i++) ...[
                    if (i > 0) SizedBox(height: 14.sp),
                    _Page(image: pages[i], number: i + 1, of: pages.length),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.image, required this.number, required this.of});

  final ui.Image image;
  final int number;
  final int of;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Report page $number of $of',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.12),
              blurRadius: 16,
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: image.width / image.height,
          child: RawImage(
            image: image,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
