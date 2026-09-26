import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/bmi.dart';
import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../resources/images.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/ask_number.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/drop_mark.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/goal_curve.dart';
import '../../../widgets/k_ruler.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';
import '../onboarding_controller.dart';

/// Wrap-up 3: the plan, built from the answers. Goal curve, dose schedule,
/// daily protein and water (editable), and what the first weeks look like.
class PlanPage extends GetView<OnboardingController> {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
              padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 16.sp),
              children: [
                Semantics(
                  header: true,
                  child: Text("Here's your plan", style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text)),
                ).enter(motion, delay: 40, dy: 0.12),
                SizedBox(height: 8.sp),
                Text(
                  'Made from your answers. You can change any of it later in Me.',
                  style: AppText.bodyText.copyWith(fontSize: 15.5.sp, height: 1.45, color: k.muted),
                ).enter(motion, delay: 100, dy: 0.12),
                SizedBox(height: 18.sp),
                const _GoalCard().enter(motion, delay: 160, dy: 0.12),
                SizedBox(height: 12.sp),
                const _DoseCard().enter(motion, delay: 240, dy: 0.12),
                SizedBox(height: 20.sp),
                const SectionLabel('EVERY DAY').enter(motion, delay: 320),
                SizedBox(height: 10.sp),
                Obx(
                  () => _DailyGoals(
                    controller: controller,
                    protein: controller.proteinShown,
                    waterMl: controller.waterShownMl,
                  ),
                ).enter(motion, delay: 360, dy: 0.12),
                SizedBox(height: 20.sp),
                const SectionLabel('YOUR FIRST WEEKS').enter(motion, delay: 440),
                SizedBox(height: 10.sp),
                const _FirstWeeks().enter(motion, delay: 480, dy: 0.12),
                SizedBox(height: 14.sp),
                Text(
                  'Goals are general guidance, not medical advice. Your doctor can adjust them with you.',
                  textAlign: TextAlign.center,
                  style: AppText.small.copyWith(fontSize: 12.5.sp, height: 1.45, color: k.faint),
                ),
              ],
            ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 4.sp, 20.sp, 8.sp),
          child: Obx(
            () => PillButton(
              label: 'Looks good',
              busy: controller.saving.value,
              onPressed: controller.confirmPlan,
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- helpers

String _weight(double kg, bool useKg) {
  if (!useKg) return (kg * Imperial.lbPerKg).round().toString();
  final r = (kg * 10).round() / 10;
  return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
}

TextStyle _bigNumber(Color color) =>
    AppText.h1.copyWith(fontSize: 26.sp, height: 1, letterSpacing: -0.6, color: color);

// --------------------------------------------------------------- goal card

/// Ink card: today → goal curve and BMI numbers. Without a goal it shows
/// just the starting point.
class _GoalCard extends StatefulWidget {
  const _GoalCard();

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _draw.value = 1;
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _draw.forward().whenComplete(() {
        if (mounted) Haptics.instance.lightImpact();
      });
    });
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OnboardingController>();
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final useKg = c.useKg.value;
    final unit = useKg ? 'kg' : 'lb';
    final now = c.weightKg.value;
    final goal = c.goalKg.value;
    final bmiNow = c.bmi;
    final bmiGoal = goal == null ? null : Bmi.of(goal, c.heightCm.value);

    final diffKg = goal == null ? 0.0 : goal - now;
    final badge = goal == null
        ? null
        : diffKg.abs() < 0.1
            ? 'Keep it steady'
            : '${_weight(diffKg.abs(), useKg)} $unit to ${diffKg < 0 ? 'lose' : 'gain'}';

    Widget weightLabel(String value, String caption, Color color, {bool end = false}) => Column(
          crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: value, style: _bigNumber(color)),
                TextSpan(
                  text: ' $unit',
                  style: AppText.bodyStrong.copyWith(fontSize: 14.sp, color: AppColors.heroMuted),
                ),
              ]),
            ),
            SizedBox(height: 3.sp),
            Text(caption, style: AppText.small.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.heroMuted)),
          ],
        );

    final stats = <(String, String, Color)>[
      if (bmiNow != null) ('BMI TODAY', bmiNow.toStringAsFixed(1), AppColors.white),
      if (bmiGoal != null) ('BMI AT GOAL', bmiGoal.toStringAsFixed(1), AppColors.lime),
      if (goal != null && diffKg.abs() >= 0.1)
        ('CHANGE', '${diffKg < 0 ? '−' : '+'}${(diffKg.abs() / now * 100).round()}%', AppColors.white),
      if (goal == null && bmiNow != null) ('RANGE', Bmi.label(Bmi.range(bmiNow)), AppColors.white),
    ];

    return Semantics(
      container: true,
      label: goal == null
          ? 'Starting weight ${_weight(now, useKg)} $unit'
          : 'Today ${_weight(now, useKg)} $unit, goal ${_weight(goal, useKg)} $unit. ${badge ?? ''}',
      child: Container(
        padding: EdgeInsets.fromLTRB(18.sp, 18.sp, 18.sp, 16.sp),
        decoration: BoxDecoration(
          color: AppColors.hero,
          borderRadius: BorderRadius.circular(24.sp),
          border: dark ? Border.all(color: k.border) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal == null ? 'Your starting point' : 'Your goal',
                    style: AppText.bodyStrong.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 11.sp, vertical: 5.sp),
                    decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(11.sp)),
                    child: Text(
                      badge,
                      style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
              ],
            ),
            if (goal != null) ...[
              SizedBox(height: 8.sp),
              ExcludeSemantics(
                child: SizedBox(
                  height: 150.sp,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _draw,
                          builder: (context, _) => GoalCurve(
                            height: 150.sp,
                            progress: Curves.easeInOutCubic.transform(_draw.value),
                            rising: diffKg > 0,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: diffKg > 0 ? 40.sp : 2.sp,
                        child: weightLabel(_weight(now, useKg), 'Today', AppColors.white),
                      ),
                      Positioned(
                        right: 0,
                        top: diffKg > 0 ? 2.sp : 30.sp,
                        child: FadeTransition(
                          opacity: CurvedAnimation(parent: _draw, curve: const Interval(0.8, 1)),
                          child: weightLabel(_weight(goal, useKg), 'Goal', AppColors.lime, end: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(height: 12.sp),
              weightLabel(_weight(now, useKg), 'Today', AppColors.white),
              SizedBox(height: 4.sp),
            ],
            if (stats.isNotEmpty) ...[
              SizedBox(height: 10.sp),
              Container(height: 1, color: AppColors.heroMuted.withValues(alpha: 0.18)),
              SizedBox(height: 12.sp),
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) ...[
                        Container(width: 1, color: AppColors.heroMuted.withValues(alpha: 0.18)),
                        SizedBox(width: 14.sp),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats[i].$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caps.copyWith(fontSize: 11.5.sp, color: AppColors.heroMuted),
                            ),
                            SizedBox(height: 2.sp),
                            Text(
                              stats[i].$2,
                              style: AppText.bodyStrong.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w800, color: stats[i].$3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- dose card

class _DoseCard extends GetView<OnboardingController> {
  const _DoseCard();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final m = controller.medicine;
    final undecided = m.id == Catalog.undecided;
    final name = Catalog.medicineName(m.id, controller.customMedicine.value);
    final dose = controller.doseMode.value == 'unsure' ? '' : ' ${Catalog.mgLabel(controller.strength.value)}';
    final time = Dates.timeOfDay(controller.shotMinutes.value);
    final rhythm = controller.rhythmLabel;
    final schedule = '${rhythm == 'daily' ? 'Every day' : rhythm[0].toUpperCase() + rhythm.substring(1)} · $time';
    final next = controller.nextDosePreview;
    final reminders = controller.remindersOn.value;
    final tablet = controller.form.value == 'tablet';

    Widget fact(String label, String value, {Widget? trailing}) => Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
            decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(14.sp)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.caps.copyWith(fontSize: 11.5.sp, color: k.faint)),
                SizedBox(height: 2.sp),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong.copyWith(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: k.text),
                      ),
                    ),
                    if (trailing != null) ...[SizedBox(width: 6.sp), trailing],
                  ],
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
        border: Border.all(color: k.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.sp,
                height: 44.sp,
                decoration: BoxDecoration(color: k.tint, borderRadius: BorderRadius.circular(14.sp)),
                alignment: Alignment.center,
                child: Icon(
                  tablet ? PhosphorIconsBold.pill : PhosphorIconsBold.syringe,
                  size: 22.sp,
                  color: k.text,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: undecided ? 'Medicine not added yet' : name),
                        if (!undecided && m.mark != null)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.top,
                            child: Text(m.mark!, style: AppText.small.copyWith(fontSize: 9.sp, color: k.text)),
                          ),
                        if (!undecided) TextSpan(text: dose),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: k.text),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      undecided ? 'Add it once you and your doctor decide' : schedule,
                      style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: k.muted),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.sp),
              _EditChip(
                label: undecided ? 'Add' : 'Edit',
                semantic: undecided ? 'Add medicine' : 'Edit dose schedule',
                color: k.muted,
                onTap: controller.editDoseFromPlan,
              ),
            ],
          ),
          if (!undecided) ...[
            SizedBox(height: 12.sp),
            Row(
              children: [
                fact('NEXT DOSE', next == null ? 'Not set' : Dates.shortWithDay(next)),
                SizedBox(width: 8.sp),
                fact(
                  'REMINDERS',
                  reminders ? 'On' : 'Off',
                  trailing: Container(
                    width: 7.sp,
                    height: 7.sp,
                    decoration: BoxDecoration(
                      color: reminders ? const Color(0xFF9BC21B) : k.faint,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Small "Edit" pill with a 44pt touch target.
class _EditChip extends StatelessWidget {
  const _EditChip({
    required this.label,
    required this.semantic,
    required this.color,
    required this.onTap,
    this.background,
  });

  final String label;
  final String semantic;
  final Color color;
  final Color? background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      semanticLabel: semantic,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 44.sp, minWidth: 44.sp),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
            decoration: background == null
                ? null
                : BoxDecoration(color: background, borderRadius: BorderRadius.circular(10.sp)),
            child: Text(label, style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: color)),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- daily goals

class _DailyGoals extends StatelessWidget {
  const _DailyGoals({required this.controller, required this.protein, required this.waterMl});

  final OnboardingController controller;
  final int protein;
  final int waterMl;

  Future<void> _editProtein(BuildContext context) async {
    Haptics.instance.selectionClick();
    final v = await askNumber(
      context,
      title: 'Daily protein',
      unit: 'g',
      initial: controller.proteinShown.toDouble(),
      min: 40,
      max: 250,
      decimals: 0,
    );
    if (v != null) controller.setProteinGoal(v);
  }

  Future<void> _editWater(BuildContext context) async {
    Haptics.instance.selectionClick();
    final v = await askNumber(
      context,
      title: 'Daily water',
      unit: 'L',
      initial: controller.waterShownMl / 1000,
      min: 1,
      max: 5,
      decimals: 2,
    );
    if (v != null) controller.setWaterGoal(v);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    Color tint(Color light, Color accent) => dark ? accent.withValues(alpha: 0.16) : light;

    final perKg = protein / controller.weightKg.value;
    final ml = waterMl;
    final litres = ml / 1000;
    final litreText = litres == litres.roundToDouble()
        ? litres.toStringAsFixed(0)
        : litres.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _GoalTile(
            background: tint(AppColors.tangerineSoft, AppColors.tangerine),
            accent: dark ? AppColors.tangerine : AppColors.tangerineText,
            icon: ThreeD(Img3d.biceps, size: 34.sp),
            value: '$protein',
            unit: 'g',
            title: 'Protein',
            sub: '${perKg.toStringAsFixed(1)} g per kg',
            onEdit: () => _editProtein(context),
          ),
        ),
        SizedBox(width: 10.sp),
        Expanded(
          child: _GoalTile(
            background: tint(AppColors.aquaSoft, AppColors.aqua),
            accent: dark ? AppColors.aqua : AppColors.aquaText,
            icon: SizedBox.square(
              dimension: 34.sp,
              child: const CustomPaint(painter: _WaterDropPainter()),
            ),
            value: litreText,
            unit: 'L',
            title: 'Water',
            sub: 'About ${(ml / 250).round()} glasses',
            onEdit: () => _editWater(context),
          ),
        ),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.background,
    required this.accent,
    required this.icon,
    required this.value,
    required this.unit,
    required this.title,
    required this.sub,
    required this.onEdit,
  });

  final Color background;
  final Color accent;
  final Widget icon;
  final String value;
  final String unit;
  final String title;
  final String sub;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      container: true,
      label: '$title goal, $value $unit a day',
      child: Container(
        padding: EdgeInsets.fromLTRB(14.sp, 8.sp, 6.sp, 14.sp),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(22.sp)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(child: icon),
                const Spacer(),
                _EditChip(
                  label: 'Edit',
                  semantic: 'Edit $title goal',
                  color: accent,
                  background: AppColors.white.withValues(alpha: 0.7),
                  onTap: onEdit,
                ),
              ],
            ),
            SizedBox(height: 4.sp),
            ExcludeSemantics(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
                ),
                child: Text.rich(
                  key: ValueKey(value),
                  TextSpan(children: [
                    TextSpan(text: value, style: _bigNumber(accent)),
                    TextSpan(text: ' $unit', style: AppText.bodyStrong.copyWith(fontSize: 15.sp, color: accent)),
                  ]),
                ),
              ),
            ),
            SizedBox(height: 4.sp),
            Text(title, style: AppText.bodyStrong.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: k.text)),
            SizedBox(height: 2.sp),
            Text(sub, style: AppText.small.copyWith(fontSize: 12.sp, color: k.muted)),
          ],
        ),
      ),
    );
  }
}

/// Aqua drop with a white shine: the brand drop, used as the water icon.
class _WaterDropPainter extends CustomPainter {
  const _WaterDropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawPath(DropMarkPainter.dropPath, Paint()..color = AppColors.aqua);
    canvas.drawPath(
      DropMarkPainter.shinePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_WaterDropPainter old) => false;
}

// ------------------------------------------------------------- first weeks

class _FirstWeeks extends GetView<OnboardingController> {
  const _FirstWeeks();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final undecided = controller.medicine.id == Catalog.undecided;
    final daily = controller.everyDays == 1;
    final tablet = controller.form.value == 'tablet';
    final next = controller.nextDosePreview;
    final time = Dates.timeOfDay(controller.shotMinutes.value);

    final rows = <(String, String)>[
      ('Today', 'Log your first meals and water'),
      if (!undecided && daily) ('Every day at $time', tablet ? 'Your dose, with a nudge if reminders are on' : 'Your dose, tracked for you'),
      if (!undecided && !daily && next != null)
        (
          Dates.relativeDay(next, DateTime.now()),
          tablet ? 'Dose day. We’ll keep track for you' : 'Dose day. We’ll suggest the next site',
        ),
      ('Every day', 'Quick check-in: protein, water, how you feel'),
      ('Week 4', 'Your first monthly report to share with your doctor'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
        border: Border.all(color: k.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
              decoration: BoxDecoration(
                border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: k.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 5.sp),
                    child: Container(
                      width: 10.sp,
                      height: 10.sp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? k.text : null,
                        border: i == 0 ? null : Border.all(color: k.text, width: 2),
                        boxShadow: i == 0 ? [BoxShadow(color: AppColors.lime, spreadRadius: 4.sp)] : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].$1,
                          style: AppText.bodyStrong.copyWith(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: k.text),
                        ),
                        SizedBox(height: 1.sp),
                        Text(rows[i].$2, style: AppText.small.copyWith(fontSize: 13.sp, color: k.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
