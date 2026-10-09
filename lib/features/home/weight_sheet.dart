import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/logs.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/access_service.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../services/tracker_service.dart';
import '../../widgets/buttons.dart';
import '../../widgets/day_switcher.dart';
import '../../widgets/k_ruler.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import '../../widgets/trend_line.dart';
import '../../widgets/weight_input.dart';
import '../common/day_nav.dart';

/// Opens the Log weight screen (it was a bottom sheet before 10 Oct; the
/// name stays so callers don't change).
Future<void> showWeightSheet() async {
  Haptics.instance.lightImpact();
  await Get.toNamed<void>(Routes.logWeight);
}

/// Log weight screen: date, ruler, change since last and since start, a
/// small trend with the goal line, and a calm tip. Starts from the last
/// weight so most people nudge it once or twice and save.
class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

/// Local UI state only (the number being edited). Saving goes through
/// [TrackerService], like everywhere else.
class _WeightScreenState extends State<WeightScreen> {
  final TrackerService _t = Get.find<TrackerService>();
  late bool _useKg = _t.profile.value?.useKg ?? true;
  late double _kg = _t.latestWeightKg ?? 80;
  /// ‹ Today › in the header, the same switcher as Water and Protein.
  late final _WeightDayNav _nav = _WeightDayNav(onChanged: _onDayChanged);
  DateTime get _day => _nav.day.value;

  /// A day that already has a weigh-in starts from that number.
  void _onDayChanged() {
    if (!mounted) return;
    setState(() {
      final existing = _sameDay;
      if (existing != null) _kg = existing.kg;
    });
  }
  bool _saving = false;

  String get _unit => _useKg ? 'kg' : 'lb';
  double _conv(double kg) => _useKg ? kg : kg * Imperial.lbPerKg;
  String _fmt(double kg) => _conv(kg).toStringAsFixed(1);

  /// "−0.6 kg" / "+0.4 kg" / "±0.0 kg".
  String _signed(double kgDiff) {
    final v = double.parse(_conv(kgDiff).toStringAsFixed(1));
    final sign = v < 0 ? '−' : (v > 0 ? '+' : '±');
    return '$sign${v.abs().toStringAsFixed(1)} $_unit';
  }

  /// Weigh-ins before the chosen day, oldest first.
  List<WeightEntry> get _before =>
      _t.weights.where((w) => w.date.isBefore(_day)).toList();

  WeightEntry? get _sameDay {
    for (final w in _t.weights) {
      if (Dates.sameDay(w.date, _day)) return w;
    }
    return null;
  }

  String get _dayLabel {
    final today = Dates.dateOnly(DateTime.now());
    final diff = Dates.daysBetween(_day, today);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return Dates.shortWithDay(_day);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!await AccessService.ensure()) return;
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await _t.addWeight(_kg, _day);
      final p = _t.profile.value;
      if (p != null && p.useKg != _useKg)
        await _t.saveProfile(p.copyWith(useKg: _useKg));
      Haptics.instance.mediumImpact();
      popRoute();
      showToast('Weight saved: ${_fmt(_kg)} $_unit');
    } catch (_) {
      showToast("Couldn't save. Please try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final before = _before;
    final last = before.isEmpty ? null : before.last;
    final start = _t.startWeightKg;
    final goal = _t.profile.value?.goalWeightKg;
    final trend = [
      ...before
          .skip(before.length > 6 ? before.length - 6 : 0)
          .map((w) => _conv(w.kg)),
      _conv(_kg),
    ];
    final replaces = _sameDay;

    return Scaffold(
      backgroundColor: k.bg,
      body: KSafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 4.sp),
              child: Row(
                children: [
                  BackCircle(onTap: popRoute),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Semantics(
                      header: true,
                      // Short, one line: same header as Water / Protein.
                      child: Text(
                        'Weight',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h2.copyWith(
                          fontSize: 22.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                  ),
                  DaySwitcher(nav: _nav),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, 16.sp),
                children: [
              if (replaces != null) ...[
                SizedBox(height: 6.sp),
                Text(
                  'Replaces the ${_fmt(replaces.kg)} $_unit saved for this day.',
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: k.muted,
                  ),
                ),
              ],
              SizedBox(height: 16.sp),
              WeightInput(
                kg: _kg,
                useKg: _useKg,
                typeTitle: 'Weight',
                onKg: (v) => setState(() => _kg = (v * 100).round() / 100),
                onUnit: (v) => setState(() => _useKg = v),
              ),
              SizedBox(height: 16.sp),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatBox(
                      label: last == null
                          ? 'SINCE LAST'
                          : 'SINCE ${Dates.short(last.date).toUpperCase()}',
                      value: last == null
                          ? 'First one'
                          : _signed(_kg - last.kg),
                    ),
                  ),
                  SizedBox(width: 10.sp),
                  Expanded(
                    child: _StatBox(
                      label: 'SINCE YOU STARTED',
                      value: start <= 0 ? '—' : _signed(_kg - start),
                      sub: start <= 0
                          ? null
                          : '${_kg - start < 0 ? '−' : '+'}${((_kg - start).abs() / start * 100).toStringAsFixed(1)}% of your start',
                    ),
                  ),
                ],
              ),
              if (trend.length >= 2) ...[
                SizedBox(height: 10.sp),
                Semantics(
                  label:
                      'Trend of your last ${trend.length} weigh-ins, from ${trend.first.toStringAsFixed(1)} '
                      'to ${trend.last.toStringAsFixed(1)} $_unit',
                  excludeSemantics: true,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 16.sp, 10.sp),
                    decoration: BoxDecoration(
                      color: k.card,
                      borderRadius: BorderRadius.circular(18.sp),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'LAST ${trend.length} WEIGH-INS',
                                style: AppText.caps.copyWith(
                                  fontSize: 11.5.sp,
                                  letterSpacing: 0.6,
                                  color: k.faint,
                                ),
                              ),
                            ),
                            if (goal != null)
                              Text(
                                '- - Goal ${_fmt(goal)} $_unit',
                                style: AppText.small.copyWith(
                                  fontSize: 11.5.sp,
                                  color: k.faint,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6.sp),
                        TrendLine(
                          values: trend,
                          goal: goal == null ? null : _conv(goal),
                          height: 90.sp,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                Dates.short(
                                  before[before.length > 6
                                          ? before.length - 6
                                          : 0]
                                      .date,
                                ),
                                style: AppText.small.copyWith(
                                  fontSize: 11.5.sp,
                                  color: k.faint,
                                ),
                              ),
                            ),
                            Text(
                              _dayLabel,
                              style: AppText.small.copyWith(
                                fontSize: 11.5.sp,
                                color: k.faint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 10.sp),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.sp,
                  vertical: 12.sp,
                ),
                decoration: BoxDecoration(
                  color: k.cardAlt,
                  borderRadius: BorderRadius.circular(16.sp),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Same time, same scale. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: k.text,
                        ),
                      ),
                      const TextSpan(
                        text:
                            'Weigh after waking; once a week is enough. A 1–2 kg swing from day to day is normal (water, salt).',
                      ),
                    ],
                  ),
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: k.textSoft,
                  ),
                ),
              ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 12.sp),
              child: PillButton(
                label: 'Save ${_fmt(_kg)} $_unit',
                icon: PhosphorIconsBold.check,
                busy: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      label: '${label.toLowerCase()}: $value${sub == null ? '' : ', $sub'}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(14.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(18.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caps.copyWith(
                fontSize: 11.5.sp,
                letterSpacing: 0.6,
                color: k.faint,
              ),
            ),
            SizedBox(height: 4.sp),
            Text(
              value,
              style: AppText.h3.copyWith(fontSize: 21.sp, color: k.text),
            ),
            if (sub != null)
              Text(
                sub!,
                style: AppText.small.copyWith(fontSize: 12.sp, color: k.muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// Day for this weigh-in (‹ Today ›). Back to the start of treatment,
/// never the future.
class _WeightDayNav extends GetxController with DayNav {
  _WeightDayNav({required this.onChanged});

  final VoidCallback onChanged;

  @override
  void onDayChanged() => onChanged();
}
