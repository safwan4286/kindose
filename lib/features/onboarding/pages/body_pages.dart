import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/images.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/mood_row.dart';
import '../../../widgets/painters.dart';
import '../onboarding_controller.dart';
import '../onboarding_screen.dart';

const double _lbPerKg = 2.20462;

/// Step 4: today's weight, optional goal and height.
class BaselinePage extends GetView<OnboardingController> {
  const BaselinePage({super.key});

  double _shown(double kg) => controller.useKg.value ? kg : kg * _lbPerKg;
  double _toKg(double shown) => controller.useKg.value ? shown : shown / _lbPerKg;
  String get _unit => controller.useKg.value ? 'kg' : 'lb';

  /// One tap = 0.1 in the unit on screen.
  double get _stepKg => controller.useKg.value ? 0.1 : 0.1 / _lbPerKg;

  Future<void> _typeWeight(BuildContext context) async {
    final v = await askNumber(
      context,
      title: 'Weight today',
      unit: _unit,
      initial: _shown(controller.weightKg.value),
      min: controller.useKg.value ? 30 : 66,
      max: controller.useKg.value ? 300 : 660,
    );
    if (v != null && !v.isNaN) controller.setWeight(_toKg(v));
  }

  Future<void> _typeGoal(BuildContext context) async {
    final g = controller.goalKg.value;
    final v = await askNumber(
      context,
      title: 'Goal weight',
      unit: _unit,
      initial: g == null ? null : _shown(g),
      min: controller.useKg.value ? 30 : 66,
      max: controller.useKg.value ? 300 : 660,
      allowClear: true,
    );
    if (v == null) return;
    controller.goalKg.value = v.isNaN ? null : (_toKg(v) * 10).round() / 10;
  }

  Future<void> _typeHeight(BuildContext context) async {
    final v = await askNumber(
      context,
      title: 'Height',
      unit: 'cm',
      initial: controller.heightCm.value,
      min: 100,
      max: 250,
      allowClear: true,
    );
    if (v == null) return;
    controller.heightCm.value = v.isNaN ? null : v.roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return StepScaffold(
      title: 'Your starting point',
      subtitle: 'Only you see this. It makes your progress chart meaningful.',
      cta: PillButton(label: 'Continue', onPressed: controller.next),
      children: [
        Obx(() {
          final kg = controller.weightKg.value;
          return KCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Weight today', style: AppText.title.copyWith(color: k.muted))),
                    SizedBox(
                      width: 110,
                      child: KSegmented<bool>(
                        options: const [true, false],
                        selected: controller.useKg.value,
                        onChanged: (v) => controller.useKg.value = v,
                        labelOf: (v) => v ? 'kg' : 'lb',
                        dense: true,
                        darkSelected: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleIconButton(
                      icon: PhosphorIconsBold.minus,
                      label: 'Less',
                      size: 52,
                      background: k.cardAlt,
                      onTap: () => controller.stepWeight(-_stepKg),
                    ),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Weight ${_shown(kg).toStringAsFixed(1)} $_unit. Tap to type',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => _typeWeight(context),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(_shown(kg).toStringAsFixed(1), style: AppText.number(58)),
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
                      onTap: () => controller.stepWeight(_stepKg),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Ruler(
                  value: _shown(kg),
                  onDrag: (deltaShown) => controller.stepWeight(controller.useKg.value ? deltaShown : deltaShown / _lbPerKg),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag the ruler or tap the number to type it',
                  style: AppText.tiny.copyWith(fontSize: 12, color: k.faint),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Obx(() {
          final goal = controller.goalKg.value;
          final h = controller.heightCm.value;
          final bmi = controller.bmi;
          final toGo = goal == null ? null : controller.weightKg.value - goal;
          return Row(
            children: [
              Expanded(
                child: _OptionalCard(
                  label: 'Goal weight · optional',
                  value: goal == null ? 'Add' : '${_shown(goal).toStringAsFixed(goal % 1 == 0 ? 0 : 1)} $_unit',
                  note: toGo == null
                      ? 'Skip if unsure'
                      : toGo > 0
                          ? '${_shown(toGo).toStringAsFixed(1)} $_unit to go'
                          : 'At or below today',
                  onTap: () => _typeGoal(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OptionalCard(
                  label: 'Height · optional',
                  value: h == null ? 'Add' : '${h.toStringAsFixed(0)} cm',
                  note: bmi == null ? 'For BMI on reports' : 'BMI ${bmi.toStringAsFixed(1)}',
                  onTap: () => _typeHeight(context),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _OptionalCard extends StatelessWidget {
  const _OptionalCard({required this.label, required this.value, required this.note, required this.onTap});

  final String label;
  final String value;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KCard(
      radius: 22,
      onTap: onTap,
      semanticLabel: '$label: $value. $note',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.tiny.copyWith(fontSize: 12, color: k.muted)),
          const SizedBox(height: 6),
          Text(value, style: AppText.h2.copyWith(color: value == 'Add' ? AppColors.violet : k.text)),
          const SizedBox(height: 2),
          Text(note, style: AppText.tiny.copyWith(fontSize: 12, color: k.faint)),
        ],
      ),
    );
  }
}

/// Horizontal ruler. Dragging left increases the value, like a dial.
class _Ruler extends StatefulWidget {
  const _Ruler({required this.value, required this.onDrag});

  /// Value in the unit on screen.
  final double value;

  /// Change in the unit on screen, always ±0.1.
  final ValueChanged<double> onDrag;

  static const double pxPerTenth = 9;

  @override
  State<_Ruler> createState() => _RulerState();
}

class _RulerState extends State<_Ruler> {
  double _pending = 0;

  void _onUpdate(DragUpdateDetails d) {
    _pending += -d.delta.dx / _Ruler.pxPerTenth;
    while (_pending.abs() >= 1) {
      final sign = _pending.sign;
      widget.onDrag(0.1 * sign);
      _pending -= sign;
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => _pending = 0,
        onHorizontalDragUpdate: _onUpdate,
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: CustomPaint(
            painter: _RulerPainter(widget.value, k.border, k.muted, AppColors.violet),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter(this.value, this.tick, this.label, this.accent);

  final double value;
  final Color tick;
  final Color label;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final tenths = (value * 10).round();
    final span = (cx / _Ruler.pxPerTenth).ceil() + 1;
    final paint = Paint()
      ..color = tick
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final frac = value * 10 - tenths;
    for (var i = -span; i <= span; i++) {
      final t = tenths + i;
      final x = cx + (i - frac) * _Ruler.pxPerTenth;
      final isWhole = t % 10 == 0;
      final isHalf = t % 5 == 0;
      final h = isWhole ? 26.0 : isHalf ? 18.0 : 11.0;
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      if (isWhole) {
        final tp = TextPainter(
          text: TextSpan(
            text: (t ~/ 10).toString(),
            style: AppText.tiny.copyWith(color: label, fontWeight: FontWeight.w800),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 32));
      }
    }
    final marker = Paint()
      ..color = accent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    canvas.drawLine(Offset(cx, 0), Offset(cx, 30), marker);
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.value != value || old.tick != tick;
}

/// Step 5: protein goal with an interactive sample plate.
class ProteinPage extends GetView<OnboardingController> {
  const ProteinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return StepScaffold(
      title: 'Protect your muscle',
      subtitle: 'Eating less can mean losing muscle. A daily protein goal helps. Adjust it with your dietitian.',
      cta: PillButton(label: 'Continue', onPressed: controller.next),
      children: [
        Obx(() {
          final goal = controller.proteinGoal.value;
          return KCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const ThreeD(Img3d.biceps, size: 34),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Daily protein goal', style: AppText.title)),
                    Text('$goal g', style: AppText.number(26).copyWith(color: AppColors.tangerine)),
                  ],
                ),
                Slider(
                  value: goal.toDouble().clamp(60.0, 180.0),
                  min: 60,
                  max: 180,
                  divisions: 24,
                  activeColor: AppColors.tangerine,
                  inactiveColor: k.proteinTrack,
                  thumbColor: AppColors.tangerine,
                  label: '$goal g',
                  semanticFormatterCallback: (v) => '${v.round()} grams a day',
                  onChanged: controller.setProteinGoal,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: SectionLabel('Try a sample day')),
            Obx(() => SizedBox(
                  width: 170,
                  child: KSegmented<bool>(
                    options: const [false, true],
                    selected: controller.veg.value,
                    onChanged: controller.setVeg,
                    labelOf: (v) => v ? 'Veg' : 'Everyday',
                    dense: true,
                    darkSelected: true,
                  ),
                )),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final foods = controller.plateFoods;
          final off = controller.plateOff.toSet();
          final total = controller.plateTotal;
          final goal = controller.proteinGoal.value;
          final hit = total >= goal;
          return Column(
            children: [
              Row(
                children: [
                  ProgressRing(
                    value: total / goal,
                    color: AppColors.tangerine,
                    track: k.proteinTrack,
                    size: 150,
                    stroke: 12,
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        children: [
                          for (var i = 0; i < foods.length; i++)
                            Positioned(
                              left: 43 + 38 * math.cos(-math.pi / 2 + i * math.pi / 3),
                              top: 43 + 38 * math.sin(-math.pi / 2 + i * math.pi / 3),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: off.contains(foods[i].id) ? 0.15 : 1,
                                child: ThreeD(foods[i].icon, size: 24),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$total g', style: AppText.number(40)),
                        Text('of $goal g', style: AppText.small.copyWith(color: k.muted)),
                        const SizedBox(height: 10),
                        KTag(
                          hit ? 'Goal reached' : '${goal - total} g to go',
                          bg: hit ? AppColors.limeSoft : AppColors.tangerineSoft,
                          fg: hit ? AppColors.limeText : AppColors.tangerineText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.1,
                children: [
                  for (final f in foods)
                    _FoodToggle(food: f, on: !off.contains(f.id), onTap: () => controller.toggleFood(f.id)),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _FoodToggle extends StatelessWidget {
  const _FoodToggle({required this.food, required this.on, required this.onTap});

  final Food food;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: on,
      label: '${food.name}, ${food.grams} grams protein',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: k.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: on ? AppColors.tangerine : k.border, width: 2),
          ),
          child: Opacity(
            opacity: on ? 1 : 0.45,
            child: Row(
              children: [
                ThreeD(food.icon, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name, style: AppText.small.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${food.grams} g', style: AppText.tiny.copyWith(color: k.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 6: what the user wants help with (multi-select).
class FocusPage extends GetView<OnboardingController> {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'What should Kindose help with?',
      subtitle: 'Pick as many as you like. We tune your Today screen to match.',
      cta: PillButton(label: 'Build my plan', onPressed: controller.next),
      children: [
        Obx(() {
          final on = controller.focus.toSet();
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              for (final f in Catalog.focusItems)
                _FocusTile(item: f, selected: on.contains(f.id), onTap: () => controller.toggleFocus(f.id)),
            ],
          );
        }),
      ],
    );
  }
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({required this.item, required this.selected, required this.onTap});

  final FocusItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.title}. ${item.sub}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? k.selectedBg : k.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? k.selectedBorder : k.card, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: selected ? 1.1 : 1,
                    child: ThreeD(item.icon, size: 48),
                  ),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.violet : Colors.transparent,
                      shape: BoxShape.circle,
                      border: selected ? null : Border.all(color: k.border, width: 2),
                    ),
                    child: selected
                        ? const Center(child: PhosphorIcon(PhosphorIconsBold.check, size: 14, color: AppColors.white))
                        : null,
                  ),
                ],
              ),
              const Spacer(),
              Text(item.title, style: AppText.title.copyWith(height: 1.15), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(item.sub, style: AppText.tiny.copyWith(fontSize: 12, color: k.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
