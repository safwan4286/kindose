import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../resources/water_units.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/filling_drop.dart';
import '../onboarding_controller.dart';

/// Wrap-up 2: a short "we're setting things up" moment. The drop fills with
/// lime while each part of the plan ticks off, then it smiles and we move on
/// to the plan by ourselves. Every line comes from the user's own answers.
class BuildingPage extends StatefulWidget {
  const BuildingPage({super.key});

  @override
  State<BuildingPage> createState() => _BuildingPageState();
}

class _BuildingPageState extends State<BuildingPage>
    with TickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 4200);

  // Timeline (0–1 of [_total]).
  static const double _fillEnd = 0.8;
  static const double _smileStart = 0.8;
  static const double _smileEnd = 0.92;
  static const int _rows = 5;

  final OnboardingController _c = Get.find<OnboardingController>();
  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final List<_Row> _items = _buildRows();
  int _doneCount = 0;
  bool _started = false;
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    _timeline
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Reduce motion: show everything done, pause briefly, move on.
      _timeline.value = 1;
      _doneCount = _rows;
      _advance = Timer(const Duration(milliseconds: 2200), _goNext);
    } else {
      _wave.repeat();
      _timeline.forward();
    }
  }

  @override
  void dispose() {
    _advance?.cancel();
    _timeline.dispose();
    _wave.dispose();
    super.dispose();
  }

  double get _rowSpan => _fillEnd / _rows;

  /// 0 = pending, 1 = working, 2 = done.
  int _stateOf(int i, double t) {
    if (t >= _rowSpan * (i + 1)) return 2;
    if (t >= _rowSpan * i) return 1;
    return 0;
  }

  void _onTick() {
    final t = _timeline.value;
    var done = 0;
    while (done < _rows && _stateOf(done, t) == 2) {
      done++;
    }
    if (done != _doneCount) {
      _doneCount = done;
      Haptics.instance.selectionClick();
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    _wave.stop();
    Haptics.instance.mediumImpact();
    _advance = Timer(const Duration(milliseconds: 500), _goNext);
  }

  void _goNext() {
    if (!mounted || _c.current != OnboardingStep.building) return;
    _c.next();
  }

  List<_Row> _buildRows() {
    final m = _c.medicine;
    final undecided = m.id == Catalog.undecided;
    final name = Catalog.medicineName(m.id, _c.customMedicine.value);
    final mark = m.mark ?? '';
    final dose = _c.doseMode.value == 'unsure'
        ? ''
        : ' ${Catalog.mgLabel(_c.strength.value)}';
    final water = _c.useOz.value
        ? '${Water.toOz(_c.suggestedWaterMl).round()} fl oz'
        : '${Water.litres(_c.suggestedWaterMl)} L';
    return [
      _Row(
        'Setting your dose schedule',
        undecided
            ? 'You can add your medicine anytime'
            : '$name$mark$dose · ${_c.rhythmLabel}',
      ),
      _Row(
        'Working out your protein goal',
        'About ${_c.suggestedProtein} g a day',
      ),
      _Row('Setting your water goal', 'About $water a day'),
      _Row(
        'Planning your reminders',
        _c.remindersOn.value
            ? 'Dose day at ${Dates.timeOfDay(_c.shotMinutes.value)}'
            : 'Off for now. Turn on anytime in Me.',
      ),
      const _Row('Putting it all together', 'Your plan is ready'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24.sp, 0, 24.sp, 16.sp),
            children: [
              Center(
                child: _Hero(timeline: _timeline, wave: _wave, size: 120.sp),
              ),
              SizedBox(height: 10.sp),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  'Building your plan',
                  textAlign: TextAlign.center,
                  style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text),
                ),
              ).enter(motion, delay: 80, dy: 0.12),
              SizedBox(height: 5.sp),
              Text(
                'Using your answers, just a moment.',
                textAlign: TextAlign.center,
                style: AppText.bodyText.copyWith(
                  fontSize: 14.5.sp,
                  height: 1.45,
                  color: k.muted,
                ),
              ).enter(motion, delay: 140, dy: 0.12),
              SizedBox(height: 20.sp),
              AnimatedBuilder(
                animation: _timeline,
                builder: (context, _) {
                  final t = _timeline.value;
                  return Column(
                    children: [
                      for (var i = 0; i < _items.length; i++) ...[
                        _StepRow(row: _items[i], state: _stateOf(i, t)),
                        Divider(height: 1, thickness: 1, color: k.border),
                      ],
                    ],
                  );
                },
              ).enter(motion, delay: 220, dy: 0.18),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24.sp, 4.sp, 24.sp, 14.sp),
          child: Text(
            'Goals are general guidance, not medical advice. Your doctor can adjust them with you.',
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(
              fontSize: 12.5.sp,
              height: 1.4,
              color: k.faint,
            ),
          ),
        ),
      ],
    );
  }
}

class _Row {
  const _Row(this.title, this.detail);

  final String title;
  final String detail;
}

/// The filling drop with a soft lime glow that breathes behind it.
class _Hero extends StatelessWidget {
  const _Hero({required this.timeline, required this.wave, required this.size});

  final AnimationController timeline;
  final AnimationController wave;
  final double size;

  static double _span(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: Listenable.merge([timeline, wave]),
        builder: (context, _) {
          final t = timeline.value;
          final fill = Curves.easeInOutCubic.transform(
            _span(t, 0, _BuildingPageState._fillEnd),
          );
          final smile = Curves.easeOut.transform(
            _span(
              t,
              _BuildingPageState._smileStart,
              _BuildingPageState._smileEnd,
            ),
          );
          final squash = _span(t, 0.8, 0.95);
          final breathe = 0.5 + 0.5 * math.sin(wave.value * 2 * math.pi);
          final glow = 0.22 + 0.18 * (t >= 1 ? 1 : breathe) + 0.2 * fill;
          return SizedBox.square(
            dimension: size * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.lime.withValues(alpha: glow.clamp(0.0, 0.7)),
                        AppColors.lime.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: SizedBox.square(dimension: size * 1.5),
                ),
                FillingDrop(
                  size: size,
                  fill: fill,
                  wave: wave.value,
                  smile: smile,
                  shine: smile,
                  squash: squash,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One line of the checklist: empty ring → spinner → ink tick.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.row, required this.state});

  final _Row row;
  final int state;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final done = state == 2;
    final active = state == 1;
    final dot = 30.sp;

    final Widget mark = switch (state) {
      2 => Container(
        key: const ValueKey('done'),
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          color: k.selectedBorder,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 17.sp,
          color: k.selectedBorder == AppColors.lime
              ? AppColors.ink
              : AppColors.lime,
        ),
      ),
      1 => SizedBox(
        key: const ValueKey('active'),
        width: dot,
        height: dot,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: k.text,
          backgroundColor: k.border,
          strokeCap: StrokeCap.round,
        ),
      ),
      _ => Container(
        key: const ValueKey('pending'),
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: k.border, width: 3),
        ),
      ),
    };

    return Semantics(
      label:
          '${row.title}${done
              ? ', done. ${row.detail}'
              : active
              ? ', in progress'
              : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.sp),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: state == 0 ? 0.25 : 1,
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: mark,
              ),
              SizedBox(width: 14.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: k.text,
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    // Space is kept so rows don't jump when the detail appears.
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: done ? 1 : 0,
                      child: Text(
                        row.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small.copyWith(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: k.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
