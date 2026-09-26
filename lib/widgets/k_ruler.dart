import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// Horizontal ruler you drag (and fling) to pick a number: height, weight,
/// goal weight. Each tick is one [step]; every [majorEvery] ticks gets a
/// long mark and, where [labelOf] returns text, a label. The centre marker
/// is the current [value]. Every new value gives a light tick.
class KRuler extends StatefulWidget {
  const KRuler({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.majorEvery = 5,
    this.midEvery,
    this.labelOf,
    this.semanticLabel,
    this.semanticValueOf,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final double step;
  final int majorEvery;
  final int? midEvery;

  /// Label under a major tick, or null for none.
  final String? Function(double value)? labelOf;
  final String? semanticLabel;
  final String Function(double value)? semanticValueOf;

  @override
  State<KRuler> createState() => _KRulerState();
}

class _KRulerState extends State<KRuler> with SingleTickerProviderStateMixin {
  late final AnimationController _fling = AnimationController.unbounded(vsync: this)..addListener(_onFlingTick);
  double _pendingPx = 0;
  double _lastFlingPx = 0;
  DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);

  double get _pxPerStep => 10.sp;

  @override
  void dispose() {
    _fling.dispose();
    super.dispose();
  }

  double _snap(double v) {
    final snapped = (v / widget.step).round() * widget.step;
    return double.parse(snapped.clamp(widget.min, widget.max).toStringAsFixed(3));
  }

  /// Turns dragged pixels into whole steps; leftovers carry over.
  void _applyPx(double px) {
    _pendingPx += px;
    final steps = (_pendingPx / _pxPerStep).truncate();
    if (steps == 0) return;
    _pendingPx -= steps * _pxPerStep;
    final next = _snap(widget.value - steps * widget.step);
    if (next == widget.value) {
      // Hit the end of the range: stop any fling.
      if (_fling.isAnimating) _fling.stop();
      _pendingPx = 0;
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastHaptic).inMilliseconds > 30) {
      Haptics.instance.selectionClick();
      _lastHaptic = now;
    }
    widget.onChanged(next);
  }

  void _onFlingTick() {
    final px = _fling.value;
    _applyPx(px - _lastFlingPx);
    _lastFlingPx = px;
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    if (v.abs() < 60 || MediaQuery.disableAnimationsOf(context)) return;
    _lastFlingPx = 0;
    _fling.value = 0;
    _fling.animateWith(FrictionSimulation(0.12, 0, v));
  }

  void _nudge(int steps) {
    final next = _snap(widget.value + steps * widget.step);
    if (next == widget.value) return;
    Haptics.instance.selectionClick();
    widget.onChanged(next);
  }

  String _describe(double v) => widget.semanticValueOf?.call(v) ?? v.toString();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    // Flutter requires increasedValue / decreasedValue whenever the
    // increase / decrease actions exist, so both are set (or both null at
    // the ends of the range).
    final up = _snap(widget.value + widget.step);
    final down = _snap(widget.value - widget.step);
    final canUp = up != widget.value;
    final canDown = down != widget.value;
    return Semantics(
      label: widget.semanticLabel,
      value: _describe(widget.value),
      slider: true,
      increasedValue: canUp ? _describe(up) : null,
      decreasedValue: canDown ? _describe(down) : null,
      onIncrease: canUp ? () => _nudge(1) : null,
      onDecrease: canDown ? () => _nudge(-1) : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            _fling.stop();
            _pendingPx = 0;
          },
          onHorizontalDragUpdate: (d) => _applyPx(d.delta.dx),
          onHorizontalDragEnd: _onDragEnd,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
              stops: [0, 0.2, 0.8, 1],
            ).createShader(rect),
            child: SizedBox(
              height: 78.sp,
              width: double.infinity,
              child: CustomPaint(
                painter: _RulerPainter(
                  value: widget.value,
                  step: widget.step,
                  majorEvery: widget.majorEvery,
                  midEvery: widget.midEvery,
                  labelOf: widget.labelOf,
                  pxPerStep: _pxPerStep,
                  minor: k.border,
                  major: k.muted,
                  label: k.faint,
                  marker: k.selectedBorder,
                  min: widget.min,
                  max: widget.max,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.value,
    required this.step,
    required this.majorEvery,
    required this.midEvery,
    required this.labelOf,
    required this.pxPerStep,
    required this.minor,
    required this.major,
    required this.label,
    required this.marker,
    required this.min,
    required this.max,
  });

  final double value;
  final double step;
  final int majorEvery;
  final int? midEvery;
  final String? Function(double)? labelOf;
  final double pxPerStep;
  final Color minor;
  final Color major;
  final Color label;
  final Color marker;
  final double min;
  final double max;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final centre = (value / step).round();
    final span = (cx / pxPerStep).ceil() + 1;
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final longH = 42.sp;
    final midH = 30.sp;
    final shortH = 20.sp;

    for (var i = -span; i <= span; i++) {
      final n = centre + i;
      final v = n * step;
      if (v < min - step / 2 || v > max + step / 2) continue;
      final x = cx + i * pxPerStep;
      final isMajor = n % majorEvery == 0;
      final isMid = !isMajor && midEvery != null && n % midEvery! == 0;
      tick.color = isMajor ? major : minor;
      final h = isMajor ? longH : isMid ? midH : shortH;
      if (i != 0) canvas.drawLine(Offset(x, 4.sp), Offset(x, 4.sp + h), tick);
      if (isMajor) {
        final text = labelOf?.call(v);
        if (text != null) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: AppText.small.copyWith(fontSize: 12.sp, color: label)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x - tp.width / 2, 4.sp + longH + 8.sp));
        }
      }
    }

    final m = Paint()
      ..color = marker
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    canvas.drawLine(Offset(cx, 0), Offset(cx, 4.sp + longH + 6.sp), m);
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.value != value || old.marker != marker || old.minor != minor || old.step != step;
}

/// Imperial helpers shared by height screens.
class Imperial {
  Imperial._();

  static const double cmPerInch = 2.54;
  static const double lbPerKg = 2.20462;

  /// 67 → "5′ 7″"
  static String feetInches(double inches) {
    final t = inches.round();
    return '${t ~/ 12}′ ${t % 12}″';
  }
}
