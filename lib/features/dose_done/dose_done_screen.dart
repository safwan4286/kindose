import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/system_ui.dart';
import '../../services/theme/theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/safe_bottom.dart';
import 'dose_done_controller.dart';

/// Celebration after logging a dose: what was logged, when the next one
/// is, the on-time streak, and a way to undo.
class DoseDoneScreen extends GetView<DoseDoneController> {
  const DoseDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final reminder = controller.reminderLine;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: KSystemUi.style(darkBackground: true),
      child: Scaffold(
        backgroundColor: AppColors.hero,
        body: KSafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.sp, 8.sp, 24.sp, 12.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => _UndoButton(busy: controller.busy.value, onTap: controller.undo)),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SuccessMark(size: 120.sp, animate: motion),
                          SizedBox(height: 28.sp),
                          Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              controller.title,
                              textAlign: TextAlign.center,
                              style: AppText.h1.copyWith(fontSize: 32.sp, color: AppColors.white),
                            ),
                          ).enter(motion, delay: 300),
                          SizedBox(height: 8.sp),
                          Text(
                            controller.summary,
                            textAlign: TextAlign.center,
                            style: AppText.bodyStrong.copyWith(fontSize: 15.5.sp, color: AppColors.heroMuted),
                          ).enter(motion, delay: 360),
                          SizedBox(height: 26.sp),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'NEXT DOSE',
                                  value: controller.nextDate,
                                  sub: controller.nextSub,
                                ),
                              ),
                              SizedBox(width: 10.sp),
                              Expanded(
                                child: _StatBox(
                                  label: 'ON TIME',
                                  value: controller.streakValue,
                                  sub: controller.streakSub,
                                  lime: true,
                                ),
                              ),
                            ],
                          ).enter(motion, delay: 440),
                          if (reminder != null) ...[
                            SizedBox(height: 10.sp),
                            _InfoRow(
                              icon: PhosphorIconsBold.bell,
                              text: TextSpan(children: [
                                const TextSpan(text: 'Reminder set for '),
                                TextSpan(text: reminder, style: const TextStyle(color: AppColors.white)),
                              ]),
                            ).enter(motion, delay: 520),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                _DoneButton(onTap: controller.done).enter(motion, delay: 600),
                SizedBox(height: 6.sp),
                TextButton(
                  onPressed: controller.feeling,
                  style: TextButton.styleFrom(minimumSize: Size.fromHeight(44.sp)),
                  child: Text(
                    'How are you feeling after it?',
                    style: AppText.title.copyWith(fontSize: 15.sp, color: AppColors.white),
                  ),
                ).enter(motion, delay: 640),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Undo, remove this dose',
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64.sp, 40.sp),
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          foregroundColor: AppColors.white,
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.18), width: 1.5),
          shape: const StadiumBorder(),
        ),
        child: Text('Undo', style: AppText.title.copyWith(fontSize: 14.sp, color: AppColors.white)),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.sub, this.lime = false});

  final String label;
  final String value;
  final String sub;
  final bool lime;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${label.toLowerCase()}: $value, $sub',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(14.sp),
        decoration: BoxDecoration(
          color: lime ? AppColors.lime.withValues(alpha: 0.12) : AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.caps.copyWith(
                fontSize: 11.5.sp,
                letterSpacing: 0.6,
                color: lime ? AppColors.lime : AppColors.heroMuted,
              ),
            ),
            SizedBox(height: 4.sp),
            Text(value, style: AppText.title.copyWith(fontSize: 16.sp, color: AppColors.white)),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: AppColors.heroMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final InlineSpan text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16.sp),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 18.sp, color: AppColors.lime),
          SizedBox(width: 10.sp),
          Expanded(
            child: Text.rich(
              text,
              style: AppText.small.copyWith(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: AppColors.heroMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.ink,
        minimumSize: Size.fromHeight(58.sp),
        shape: const StadiumBorder(),
      ),
      child: Text('Done', style: AppText.button.copyWith(fontSize: 17.sp, color: AppColors.ink)),
    );
  }
}

// ---------------------------------------------------------- success mark

/// Lime circle that pops in, a tick that draws itself and a ring that
/// ripples out. Plays a firm haptic when the tick lands.
class _SuccessMark extends StatefulWidget {
  const _SuccessMark({required this.size, required this.animate});

  final double size;
  final bool animate;

  @override
  State<_SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<_SuccessMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _pop = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
  );
  late final Animation<double> _tick = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.32, 0.6, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _ripple = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.25, 1, curve: Curves.easeOut),
  );

  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _c.value = 1;
      Haptics.instance.heavyImpact();
      return;
    }
    _c.addListener(_maybeBuzz);
    _c.forward();
  }

  void _maybeBuzz() {
    if (!_buzzed && _c.value >= 0.55) {
      _buzzed = true;
      Haptics.instance.heavyImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: s,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final r = _ripple.value;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (widget.animate && r > 0 && r < 1)
                  Transform.scale(
                    scale: 0.8 + r,
                    child: Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lime.withValues(alpha: 0.6 * (1 - r)), width: 3),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: math.max(0, _pop.value),
                  child: Container(
                    width: s,
                    height: s,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.lime),
                    child: CustomPaint(painter: _TickPainter(_tick.value)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final u = size.width / 24;
    final path = Path()
      ..moveTo(7.5 * u, 12.4 * u)
      ..lineTo(10.6 * u, 15.5 * u)
      ..lineTo(16.8 * u, 9 * u);
    final paint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t.clamp(0.0, 1.0)), paint);
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.t != t;
}
