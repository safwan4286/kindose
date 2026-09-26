import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart' show KColorsX;
import '../../resources/images.dart';
import '../../services/theme/theme.dart';
import '../../services/tracker_service.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/mood_row.dart';
import '../../widgets/toast.dart';
import '../../widgets/safe_bottom.dart';

const double kLbPerKg = 2.20462;

/// Quick weigh-in. Starts from the last weight so most people tap once
/// or twice and save.
Future<void> showWeightSheet() {
  return Get.bottomSheet<void>(const WeightSheet(), isScrollControlled: true);
}

class WeightSheet extends StatefulWidget {
  const WeightSheet({super.key});

  @override
  State<WeightSheet> createState() => _WeightSheetState();
}

/// Local UI state only (the number being edited). Saving goes through
/// [TrackerService], like everywhere else.
class _WeightSheetState extends State<WeightSheet> {
  final TrackerService _tracker = Get.find<TrackerService>();
  late bool _useKg = _tracker.profile.value?.useKg ?? true;
  late double _kg = _tracker.latestWeightKg ?? 80;
  bool _saving = false;

  double get _shown => _useKg ? _kg : _kg * kLbPerKg;
  String get _unit => _useKg ? 'kg' : 'lb';

  void _step(double shownDelta) {
    setState(() {
      final kgDelta = _useKg ? shownDelta : shownDelta / kLbPerKg;
      _kg = ((_kg + kgDelta).clamp(30.0, 300.0) * 100).round() / 100;
    });
  }

  Future<void> _type() async {
    final v = await askNumber(
      context,
      title: 'Weight today',
      unit: _unit,
      initial: _shown,
      min: _useKg ? 30 : 66,
      max: _useKg ? 300 : 660,
    );
    if (v == null || v.isNaN) return;
    setState(() => _kg = ((_useKg ? v : v / kLbPerKg) * 100).round() / 100);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _tracker.addWeight(_kg);
      popRoute();
      showToast('Weight saved: ${_shown.toStringAsFixed(1)} $_unit');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: k.border, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 14),
            Row(
              children: [
                const ThreeD(Img3d.chartDown, size: 40),
                const SizedBox(width: 10),
                Expanded(child: Text('Weigh-in', style: AppText.h2)),
                SizedBox(
                  width: 110,
                  child: KSegmented<bool>(
                    options: const [true, false],
                    selected: _useKg,
                    onChanged: (v) => setState(() => _useKg = v),
                    labelOf: (v) => v ? 'kg' : 'lb',
                    dense: true,
                    darkSelected: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            KCard(
              child: Row(
                children: [
                  CircleIconButton(
                    icon: PhosphorIconsBold.minus,
                    label: 'Less',
                    size: 52,
                    background: k.cardAlt,
                    onTap: () => _step(-0.1),
                  ),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Weight ${_shown.toStringAsFixed(1)} $_unit. Tap to type',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: _type,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(_shown.toStringAsFixed(1), style: AppText.number(54)),
                              const SizedBox(width: 4),
                              Text(_unit, style: AppText.title.copyWith(fontSize: 20, color: k.muted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: PhosphorIconsBold.plus,
                    label: 'More',
                    size: 52,
                    background: k.cardAlt,
                    onTap: () => _step(0.1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Weigh at the same time each week for a fair trend.',
              style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            PillButton(
              label: 'Save weight',
              icon: PhosphorIconsBold.check,
              busy: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

