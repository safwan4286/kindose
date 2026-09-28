import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import 'ask_number.dart';
import 'big_value.dart';
import 'buttons.dart';
import 'entrance.dart';
import 'k_ruler.dart';
import 'k_widgets.dart';

/// kg | lb switch, big tappable number, ruler in 0.1 steps and − / +.
/// Always talks in kg to the outside; the unit only changes what's shown.
/// Used by the weight and goal-weight questions, and later by weigh-ins.
class WeightInput extends StatelessWidget {
  const WeightInput({
    super.key,
    required this.kg,
    required this.useKg,
    required this.onKg,
    required this.onUnit,
    required this.typeTitle,
    this.minKg = 30,
    this.maxKg = 300,
    this.animate = true,
  });

  final double kg;
  final bool useKg;
  final ValueChanged<double> onKg;
  final ValueChanged<bool> onUnit;

  /// Title of the "type it" sheet, e.g. "Weight today".
  final String typeTitle;
  final double minKg;
  final double maxKg;
  final bool animate;

  double _shown(double v) => useKg ? v : v * Imperial.lbPerKg;
  String get _unit => useKg ? 'kg' : 'lb';
  double get _min => _shown(minKg).ceilToDouble();
  double get _max => _shown(maxKg).floorToDouble();
  double get _shownValue => double.parse(_shown(kg).toStringAsFixed(1));

  Future<void> _type(BuildContext context) async {
    // The answer is in the unit shown when the sheet opened.
    final metric = useKg;
    final v = await askNumber(
      context,
      title: typeTitle,
      unit: _unit,
      initial: _shownValue,
      min: _min,
      max: _max,
    );
    if (v != null && !v.isNaN) onKg(metric ? v : v / Imperial.lbPerKg);
  }

  void _step(int tenths) {
    Haptics.instance.selectionClick();
    final v = (_shownValue + tenths * 0.1).clamp(_min, _max);
    onKg(useKg ? v : v / Imperial.lbPerKg);
  }

  @override
  Widget build(BuildContext context) {
    final motion = animate && !MediaQuery.disableAnimationsOf(context);
    final metric = useKg;
    final shown = _shownValue.toStringAsFixed(1);
    return Column(
      children: [
        SizedBox(
          width: 220.sp,
          child: KSegmented<bool>(
            options: const [true, false],
            selected: useKg,
            onChanged: onUnit,
            labelOf: (v) => v ? 'kg' : 'lb',
          ),
        ).enter(motion, delay: 100, dy: 0.1),
        SizedBox(height: 30.sp),
        BigValue(
          value: shown,
          unit: _unit,
          semanticLabel: '$typeTitle $shown $_unit',
          onTap: () => _type(context),
        ).enter(motion, delay: 160),
        SizedBox(height: 26.sp),
        KRuler(
          // One ruler per unit, and each converts with its own unit, so a
          // fling that is still running during a unit switch can't save a
          // lb number as kg.
          key: ValueKey(metric),
          semanticLabel: '$typeTitle in $_unit',
          value: _shownValue,
          min: _min,
          max: _max,
          step: 0.1,
          majorEvery: 10,
          midEvery: 5,
          labelOf: (v) => v.round().toString(),
          semanticValueOf: (v) => '${v.toStringAsFixed(1)} $_unit',
          onChanged: (v) => onKg(metric ? v : v / Imperial.lbPerKg),
        ).enter(motion, delay: 220),
        SizedBox(height: 8.sp),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleIconButton(
              icon: PhosphorIconsBold.minus,
              label: 'Less',
              size: 44.sp,
              onTap: () => _step(-1),
            ),
            SizedBox(width: 12.sp),
            CircleIconButton(
              icon: PhosphorIconsBold.plus,
              label: 'More',
              size: 44.sp,
              onTap: () => _step(1),
            ),
          ],
        ).enter(motion, delay: 260),
      ],
    );
  }
}
