import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../services/plus/access_service.dart';
import '../../models/logs.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../services/tracker_service.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_ruler.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import '../../widgets/trend_line.dart';
import '../../widgets/weight_input.dart';
import '../../widgets/k_date_picker.dart';

/// Weigh-in sheet: date, ruler, change since last and since start, a small
/// trend with the goal line, and a calm tip. Starts from the last weight
/// so most people nudge it once or twice and save.
Future<void> showWeightSheet() async {
  if (!AccessService.allow()) return;
  Haptics.instance.lightImpact();
  await Get.bottomSheet<void>(const WeightSheet(), isScrollControlled: true);
}

class WeightSheet extends StatefulWidget {
  const WeightSheet({super.key});

  @override
  State<WeightSheet> createState() => _WeightSheetState();
}

/// Local UI state only (the number being edited). Saving goes through
/// [TrackerService], like everywhere else.
class _WeightSheetState extends State<WeightSheet> {
  final TrackerService _t = Get.find<TrackerService>();
  late bool _useKg = _t.profile.value?.useKg ?? true;
  late double _kg = _t.latestWeightKg ?? 80;
  DateTime _day = Dates.dateOnly(DateTime.now());
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

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showKDatePicker(
      context: context,
      initialDate: _day,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      title: 'Day of this weigh-in',
    );
    if (d == null || !mounted) return;
    setState(() {
      _day = Dates.dateOnly(d);
      final existing = _sameDay;
      if (existing != null) _kg = existing.kg;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
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

    return KSafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: k.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.sp)),
        ),
        padding: EdgeInsets.fromLTRB(
          20.sp,
          10.sp,
          20.sp,
          12.sp + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.sp,
                  height: 5.sp,
                  decoration: BoxDecoration(
                    color: k.border,
                    borderRadius: BorderRadius.circular(3.sp),
                  ),
                ),
              ),
              SizedBox(height: 14.sp),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Log weight',
                        style: AppText.h2.copyWith(
                          fontSize: 24.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: PhosphorIconsBold.x,
                    label: 'Close',
                    size: 40.sp,
                    onTap: popRoute,
                  ),
                ],
              ),
              SizedBox(height: 10.sp),
              Align(
                alignment: Alignment.centerLeft,
                child: PressScale(
                  semanticLabel: 'Date: $_dayLabel. Tap to change',
                  onTap: _pickDay,
                  child: Container(
                    height: 36.sp,
                    padding: EdgeInsets.symmetric(horizontal: 12.sp),
                    decoration: BoxDecoration(
                      color: k.card,
                      borderRadius: BorderRadius.circular(18.sp),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ThreeD(Img3d.calendar, size: 18.sp),
                        SizedBox(width: 6.sp),
                        Text(
                          _dayLabel,
                          style: AppText.small.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: k.text,
                          ),
                        ),
                        SizedBox(width: 4.sp),
                        Icon(
                          PhosphorIconsBold.caretDown,
                          size: 12.sp,
                          color: k.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
              SizedBox(height: 14.sp),
              PillButton(
                label: 'Save ${_fmt(_kg)} $_unit',
                icon: PhosphorIconsBold.check,
                busy: _saving,
                onPressed: _save,
              ),
            ],
          ),
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
