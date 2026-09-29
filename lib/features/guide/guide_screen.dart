import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/body_map.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import 'guide_controller.dart';

/// Injection guide: one calm step at a time.
class GuideScreen extends GetView<GuideController> {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) Haptics.instance.selectionClick();
      },
      child: Scaffold(
        backgroundColor: k.bg,
        body: KSafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 12.sp),
            child: Obx(() {
              final s = controller.step.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(step: s, onClose: controller.close),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
                          child: child,
                        ),
                      ),
                      child: _StepBody(key: ValueKey<int>(s), controller: controller),
                    ),
                  ),
                  const _LeafletNote(),
                  SizedBox(height: 10.sp),
                  Row(
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: s == 0
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: EdgeInsets.only(right: 10.sp),
                                child: CircleIconButton(
                                  icon: PhosphorIconsBold.caretLeft,
                                  label: 'Previous step',
                                  onTap: controller.back,
                                  size: 56.sp,
                                ),
                              ),
                      ),
                      Expanded(
                        child: PillButton(label: controller.cta, onPressed: controller.next),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onClose});

  final int step;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Row(
      children: [
        CircleIconButton(icon: PhosphorIconsBold.x, label: 'Close guide', onTap: onClose),
        SizedBox(width: 12.sp),
        Expanded(
          child: Semantics(
            label: 'Step ${step + 1} of ${GuideController.stepCount}',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 0; i < GuideController.stepCount; i++) ...[
                  if (i > 0) SizedBox(width: 5.sp),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 5.sp,
                      decoration: BoxDecoration(
                        color: i <= step ? (dark ? AppColors.lime : AppColors.ink) : k.border,
                        borderRadius: BorderRadius.circular(3.sp),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: 12.sp),
        ExcludeSemantics(
          child: Text(
            '${step + 1} of ${GuideController.stepCount}',
            style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: k.muted),
          ),
        ),
      ],
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({super.key, required this.controller});

  final GuideController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;
    final visual = switch (c.step.value) {
      0 => _Checklist(controller: c),
      1 => _Spot(controller: c),
      2 => const _Breathe(),
      3 => _HoldTimer(controller: c),
      _ => const _After(),
    };
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 22.sp),
              SectionLabel(c.caps, color: k.faint),
              SizedBox(height: 6.sp),
              Semantics(
                header: true,
                child: Text(c.title, style: AppText.h1.copyWith(fontSize: 30.sp, height: 1.08, color: k.text)),
              ),
              SizedBox(height: 8.sp),
              Text(
                c.body,
                style: AppText.bodyText.copyWith(fontSize: 15.sp, height: 1.45, fontWeight: FontWeight.w600, color: k.muted),
              ),
              SizedBox(height: 20.sp),
              Center(child: visual),
              SizedBox(height: 16.sp),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ steps

class _Checklist extends StatelessWidget {
  const _Checklist({required this.controller});

  final GuideController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final on = dark ? AppColors.lime : AppColors.ink;
    final tick = dark ? AppColors.ink : AppColors.lime;
    return Obx(
      () => Column(
        children: [
          for (final (i, t) in GuideController.checkItems.indexed) ...[
            if (i > 0) SizedBox(height: 10.sp),
            Semantics(
              checked: controller.checks[i],
              label: t,
              excludeSemantics: true,
              child: PressScale(
                onTap: () => controller.toggleCheck(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
                  decoration: BoxDecoration(
                    color: k.card,
                    borderRadius: BorderRadius.circular(18.sp),
                    border: Border.all(color: controller.checks[i] ? on : k.card, width: 2),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26.sp,
                        height: 26.sp,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: controller.checks[i] ? on : k.card,
                          borderRadius: BorderRadius.circular(8.sp),
                          border: Border.all(color: controller.checks[i] ? on : k.border, width: 2),
                        ),
                        child: AnimatedScale(
                          scale: controller.checks[i] ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: PhosphorIcon(PhosphorIconsBold.check, size: 15.sp, color: tick),
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      Expanded(
                        child: Text(t, style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Spot extends StatelessWidget {
  const _Spot({required this.controller});

  final GuideController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return Column(
      children: [
        BodySpotPreview(
          siteId: controller.nextSiteId,
          bodyColor: k.border,
          dotColor: dark ? AppColors.lime : AppColors.ink,
          width: 160,
        ),
        SizedBox(height: 14.sp),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 10.sp),
          decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(16.sp)),
          child: Text(
            'Suggested: ${controller.nextSiteName}',
            style: AppText.title.copyWith(fontSize: 14.sp, color: k.text),
          ),
        ),
      ],
    );
  }
}

/// Grows for 4 s (breathe in), shrinks for 4 s (breathe out), with a
/// short hold at the top. Soft haptic at each change.
class _Breathe extends StatefulWidget {
  const _Breathe();

  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  String _phase = 'Breathe in…';

  @override
  void initState() {
    super.initState();
    _a.addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _a.stop();
    } else if (!_a.isAnimating) {
      _a.repeat();
    }
  }

  void _onTick() {
    final t = _a.value;
    final phase = t < 0.45 ? 'Breathe in…' : (t < 0.55 ? 'Hold' : 'Breathe out…');
    if (phase != _phase) {
      Haptics.instance.selectionClick();
      setState(() => _phase = phase);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  double _scale(double t) {
    if (t < 0.45) return 0.72 + 0.28 * Curves.easeInOut.transform(t / 0.45);
    if (t < 0.55) return 1;
    return 1 - 0.28 * Curves.easeInOut.transform((t - 0.55) / 0.45);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final size = 210.sp;
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _a,
                builder: (_, _) => Transform.scale(
                  scale: _a.isAnimating ? _scale(_a.value) : 0.9,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Color(0xFFE9F9A8), AppColors.lime], stops: [0, 0.7]),
                    ),
                  ),
                ),
              ),
              Semantics(
                liveRegion: true,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _phase,
                    key: ValueKey<String>(_phase),
                    style: AppText.h2.copyWith(fontSize: 24.sp, color: AppColors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.sp),
        Text(
          'In for 4 · hold · out for 4',
          style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: k.muted),
        ),
      ],
    );
  }
}

class _HoldTimer extends StatelessWidget {
  const _HoldTimer({required this.controller});

  final GuideController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final ring = dark ? AppColors.lime : AppColors.ink;
    final size = 190.sp;
    return Obx(() {
      final c = controller;
      final total = c.holdSecs.value;
      final left = c.remaining.value;
      final done = c.held.value;
      final progress = total == 0 ? 0.0 : (total - left) / total;
      return Column(
        children: [
          Semantics(
            liveRegion: true,
            label: done ? 'Time is up' : '$left seconds',
            excludeSemantics: true,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: c.running.value || done ? progress : 0),
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.linear,
                    builder: (_, v, _) => CustomPaint(
                      size: Size.square(size),
                      painter: _RingPainter(value: v, track: k.border, color: ring, width: 10.sp),
                    ),
                  ),
                  Container(
                    width: size - 40.sp,
                    height: size - 40.sp,
                    decoration: BoxDecoration(color: k.card, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: done
                        ? PhosphorIcon(PhosphorIconsBold.check, size: 56.sp, color: k.text)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$left', style: AppText.number(56.sp).copyWith(color: k.text, height: 1)),
                              Text(
                                'seconds',
                                style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: k.muted),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.sp),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.sp,
            runSpacing: 8.sp,
            children: [
              PressScale(
                onTap: c.toggleTimer,
                semanticLabel: c.running.value ? 'Stop timer' : 'Start hold timer',
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18.sp)),
                  child: Text(
                    c.running.value ? 'Stop' : (done ? 'Start again' : 'Start hold timer'),
                    style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: AppColors.lime),
                  ),
                ),
              ),
              for (final s in GuideController.holdChoices)
                KChip(
                  label: '$s s',
                  selected: s == total,
                  onTap: () => c.setHold(s),
                ),
            ],
          ),
        ],
      );
    });
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.color, required this.width});

  final double value;
  final Color track;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(width / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = track;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.width != width;
}

class _After extends StatelessWidget {
  const _After();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      children: [
        for (final (i, a) in GuideController.afterItems.indexed) ...[
          if (i > 0) SizedBox(height: 10.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
            decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(18.sp)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.sp,
                  height: 28.sp,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.limeSoft, borderRadius: BorderRadius.circular(9.sp)),
                  child: Text(
                    '${i + 1}',
                    style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.$1, style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
                      Text(a.$2, style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: k.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LeafletNote extends StatelessWidget {
  const _LeafletNote();

  @override
  Widget build(BuildContext context) {
    final dark = context.k.selectedBorder == AppColors.lime;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 10.sp),
      decoration: BoxDecoration(
        color: dark ? AppColors.amberText.withValues(alpha: 0.25) : AppColors.amberWash,
        borderRadius: BorderRadius.circular(14.sp),
      ),
      child: Text(
        'Always follow the leaflet that came with your pen. Unsure? Ask your pharmacist.',
        style: AppText.small.copyWith(
          fontSize: 12.5.sp,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: dark ? AppColors.amberSoft : AppColors.amberText,
        ),
      ),
    );
  }
}
