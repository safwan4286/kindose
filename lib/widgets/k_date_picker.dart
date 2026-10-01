import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'k_sheet.dart';
import 'k_widgets.dart';
import 'press_scale.dart';

/// Kindose calendar in a bottom sheet. Tapping a day picks it and closes.
///
/// * [marked] puts a small dot under days that have something logged.
/// * Days before [lockedBefore] (but after [firstDate]) show a lock; tapping
///   one closes the sheet and calls [onLockedTap] (e.g. open Plus).
/// * Tap the month title to jump by month / year.
/// * Swipe left or right to change month.
Future<DateTime?> showKDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Pick a day',
  String? note,
  bool Function(DateTime day)? marked,
  DateTime? lockedBefore,
  VoidCallback? onLockedTap,
  bool startWithMonths = false,
}) async {
  Haptics.instance.selectionClick();
  final result = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _KDatePicker(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      note: note,
      marked: marked,
      lockedBefore: lockedBefore,
      startWithMonths: startWithMonths,
    ),
  );
  if (result == _locked) {
    onLockedTap?.call();
    return null;
  }
  return result is DateTime ? result : null;
}

const Object _locked = Object();

DateTime _d(DateTime d) => DateTime(d.year, d.month, d.day);
String _short(String month) => month.length > 3 ? month.substring(0, 3) : month;
bool _same(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _KDatePicker extends StatefulWidget {
  const _KDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.note,
    required this.marked,
    required this.lockedBefore,
    required this.startWithMonths,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String? note;
  final bool Function(DateTime day)? marked;
  final DateTime? lockedBefore;
  final bool startWithMonths;

  @override
  State<_KDatePicker> createState() => _KDatePickerState();
}

class _KDatePickerState extends State<_KDatePicker> {
  late final DateTime _first = _d(widget.firstDate);
  late final DateTime _last = _d(widget.lastDate);
  late final DateTime _selected = _clamp(_d(widget.initialDate));
  late DateTime _month = DateTime(_selected.year, _selected.month);
  late bool _months = widget.startWithMonths;
  int _dir = 1;

  DateTime _clamp(DateTime d) =>
      d.isBefore(_first) ? _first : (d.isAfter(_last) ? _last : d);

  bool get _canPrev => _months
      ? _month.year > _first.year
      : DateTime(
          _month.year,
          _month.month,
        ).isAfter(DateTime(_first.year, _first.month));
  bool get _canNext => _months
      ? _month.year < _last.year
      : DateTime(
          _month.year,
          _month.month,
        ).isBefore(DateTime(_last.year, _last.month));

  void _step(int by) {
    if ((by < 0 && !_canPrev) || (by > 0 && !_canNext)) return;
    Haptics.instance.selectionClick();
    setState(() {
      _dir = by;
      _month = _months
          ? DateTime(_month.year + by, _month.month)
          : DateTime(_month.year, _month.month + by);
    });
  }

  void _pick(DateTime d) {
    final locked =
        widget.lockedBefore != null && d.isBefore(_d(widget.lockedBefore!));
    Haptics.instance.selectionClick();
    Navigator.of(context).pop(locked ? _locked : d);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final loc = MaterialLocalizations.of(context);
    final today = _d(DateTime.now());
    final todayOk = !today.isBefore(_first) && !today.isAfter(_last);

    return KSheetFrame(
      title: widget.title,
      sub: widget.note,
      children: [
        // Month / year header with arrows.
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: _months ? 'Show days' : 'Choose month and year',
                excludeSemantics: true,
                child: PressScale(
                  onTap: () {
                    Haptics.instance.selectionClick();
                    setState(() => _months = !_months);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _months
                              ? '${_month.year}'
                              : loc.formatMonthYear(_month),
                          style: AppText.h2.copyWith(
                            fontSize: 20.sp,
                            color: k.text,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.sp),
                      AnimatedRotation(
                        turns: _months ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          PhosphorIconsBold.caretDown,
                          size: 16.sp,
                          color: k.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CircleIconButton(
              icon: PhosphorIconsBold.caretLeft,
              label: _months ? 'Previous year' : 'Previous month',
              size: 38.sp,
              background: k.card,
              onTap: _canPrev ? () => _step(-1) : null,
            ),
            SizedBox(width: 8.sp),
            CircleIconButton(
              icon: PhosphorIconsBold.caretRight,
              label: _months ? 'Next year' : 'Next month',
              size: 38.sp,
              background: k.card,
              onTap: _canNext ? () => _step(1) : null,
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v.abs() < 200) return;
            _step(v < 0 ? 1 : -1);
          },
          child: Container(
            padding: EdgeInsets.fromLTRB(8.sp, 12.sp, 8.sp, 8.sp),
            decoration: BoxDecoration(
              color: k.card,
              borderRadius: BorderRadius.circular(24.sp),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.08 * _dir, 0),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(
                  '${_months ? 'y' : 'm'}${_month.year}-${_months ? 0 : _month.month}',
                ),
                child: _months ? _monthGrid(context) : _dayGrid(context, today),
              ),
            ),
          ),
        ),
        if (todayOk) ...[
          SizedBox(height: 12.sp),
          Row(
            children: [
              _QuickChip(label: 'Today', onTap: () => _pick(today)),
              if (!today
                  .subtract(const Duration(days: 1))
                  .isBefore(_first)) ...[
                SizedBox(width: 8.sp),
                _QuickChip(
                  label: 'Yesterday',
                  onTap: () => _pick(today.subtract(const Duration(days: 1))),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _dayGrid(BuildContext context, DateTime today) {
    final k = context.k;
    final loc = MaterialLocalizations.of(context);
    final dark = k.selectedBorder == AppColors.lime;
    final firstDow = loc.firstDayOfWeekIndex; // 0 = Sunday
    final first = DateTime(_month.year, _month.month);
    final lead = (first.weekday % 7 - firstDow + 7) % 7;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final labels = [
      for (var i = 0; i < 7; i++) loc.narrowWeekdays[(firstDow + i) % 7],
    ];
    final locked = widget.lockedBefore == null
        ? null
        : _d(widget.lockedBefore!);

    Widget cell(int index) {
      final n = index - lead + 1;
      if (n < 1 || n > days) return const SizedBox.shrink();
      final d = DateTime(_month.year, _month.month, n);
      final inRange = !d.isBefore(_first) && !d.isAfter(_last);
      final isLocked = inRange && locked != null && d.isBefore(locked);
      final isSel = _same(d, _selected);
      final isToday = _same(d, today);
      final dot = inRange && !isLocked && (widget.marked?.call(d) ?? false);
      final bg = isSel
          ? (dark ? AppColors.lime : AppColors.ink)
          : Colors.transparent;
      final fg = isSel
          ? (dark ? AppColors.ink : AppColors.lime)
          : !inRange || isLocked
          ? k.faint.withValues(alpha: 0.6)
          : k.text;
      return Semantics(
        button: inRange,
        selected: isSel,
        label:
            '${loc.formatFullDate(d)}${isLocked ? ', Plus' : ''}${dot ? ', has logs' : ''}',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: inRange ? () => _pick(d) : null,
          child: Center(
            child: Container(
              width: 40.sp,
              height: 40.sp,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: isToday && !isSel
                    ? Border.all(color: k.text, width: 1.5)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$n',
                    style: AppText.bodyStrong.copyWith(
                      fontSize: 15.sp,
                      fontWeight: isSel || isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (dot || isLocked)
                    Positioned(
                      bottom: 4.sp,
                      child: isLocked
                          ? Icon(
                              PhosphorIconsFill.lockSimple,
                              size: 8.sp,
                              color: k.faint,
                            )
                          : Container(
                              width: 4.sp,
                              height: 4.sp,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? fg
                                    : (dark
                                          ? AppColors.lime
                                          : AppColors.tangerine),
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final l in labels)
              Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: AppText.caps.copyWith(
                      fontSize: 11.sp,
                      letterSpacing: 0.6,
                      color: k.faint,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.sp),
        // Always 6 rows so the sheet doesn't jump between months.
        for (var r = 0; r < 6; r++)
          SizedBox(
            height: 44.sp,
            child: Row(
              children: [
                for (var c = 0; c < 7; c++) Expanded(child: cell(r * 7 + c)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _monthGrid(BuildContext context) {
    final k = context.k;
    final loc = MaterialLocalizations.of(context);
    final dark = k.selectedBorder == AppColors.lime;
    return SizedBox(
      height: 6 * 44.sp + 22.sp,
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        padding: EdgeInsets.all(4.sp),
        mainAxisSpacing: 8.sp,
        crossAxisSpacing: 8.sp,
        children: [
          for (var m = 1; m <= 12; m++)
            Builder(
              builder: (_) {
                final start = DateTime(_month.year, m);
                final end = DateTime(
                  _month.year,
                  m + 1,
                ).subtract(const Duration(days: 1));
                final ok = !end.isBefore(_first) && !start.isAfter(_last);
                final sel =
                    _selected.year == _month.year && _selected.month == m;
                return Semantics(
                  button: ok,
                  selected: sel,
                  label: loc.formatMonthYear(start),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: ok
                        ? () {
                            Haptics.instance.selectionClick();
                            setState(() {
                              _month = start;
                              _months = false;
                            });
                          }
                        : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? (dark ? AppColors.lime : AppColors.ink)
                            : k.cardAlt.withValues(alpha: ok ? 1 : 0.4),
                        borderRadius: BorderRadius.circular(16.sp),
                      ),
                      child: Text(
                        _short(loc.formatMonthYear(start).split(' ').first),
                        style: AppText.bodyStrong.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: sel
                              ? (dark ? AppColors.ink : AppColors.lime)
                              : (ok ? k.text : k.faint),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PressScale(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        height: 38.sp,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(19.sp),
          border: Border.all(color: k.border, width: 1.5),
        ),
        child: Text(
          label,
          style: AppText.small.copyWith(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w800,
            color: k.text,
          ),
        ),
      ),
    );
  }
}
