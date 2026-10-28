import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';
import '../progress_controller.dart';

/// "How you felt" as a heatmap: the headline, side-effect filter chips, a
/// Grid / Trend switch, and the picked day's details underneath. Every
/// number comes from the check-ins; nothing is predicted.
class FeelHeatmap extends StatefulWidget {
  const FeelHeatmap({
    super.key,
    required this.controller,
    required this.heat,
    required this.patternCard,
  });

  final ProgressController controller;

  /// Fine → severe, light to dark.
  final List<Color> heat;

  /// The "Your pattern" card, or null when it isn't shown.
  final Widget? patternCard;

  @override
  State<FeelHeatmap> createState() => _FeelHeatmapState();
}

class _FeelHeatmapState extends State<FeelHeatmap> {
  ProgressController get c => widget.controller;
  List<Color> get heat => widget.heat;

  /// 'all' or a side effect id.
  String _filter = 'all';
  bool _trend = false;
  DateTime? _sel;
  int _page = 0;

  static const _levels = ['Fine', 'Mild', 'Moderate', 'Severe'];

  /// The medicine's own icon marks dose days.
  IconData get _doseIcon => c.profile?.form == 'tablet'
      ? PhosphorIconsBold.pill
      : PhosphorIconsBold.syringe;

  /// Today when it's in these weeks, else the latest check-in.
  DateTime? _defaultDay(List<FeelCell> cells) {
    final today = Dates.dateOnly(DateTime.now());
    if (cells.any((x) => Dates.sameDay(x.date, today))) return today;
    final checked = cells.where((x) => !x.inFuture && x.level >= 0);
    return checked.isEmpty ? null : checked.last.date;
  }

  /// A tick only when the picked day changes, so dragging across the
  /// trend clicks once per day, like the weight chart.
  void _pick(DateTime d) {
    if (_sel != null && Dates.sameDay(_sel!, d)) return;
    Haptics.instance.selectionClick();
    setState(() => _sel = d);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final cells = c.feelCells;
    if (_page != c.feelPage.value) {
      _page = c.feelPage.value;
      _sel = null;
      _filter = 'all';
    }
    _sel ??= _defaultDay(cells);
    final effects = c.feelFilters;
    if (_filter != 'all' && !effects.contains(_filter)) {
      _filter = 'all';
    }
    final pattern = c.patternLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        SizedBox(height: 10.sp),
        Text(
          c.feelHeadline,
          style: AppText.title.copyWith(
            fontSize: 17.sp,
            height: 1.3,
            color: k.text,
          ),
        ),
        if (c.isPlus && pattern != null) ...[
          SizedBox(height: 4.sp),
          Text(
            pattern,
            style: AppText.small.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: k.muted,
            ),
          ),
        ],
        SizedBox(height: 14.sp),
        _chips(context, effects),
        SizedBox(height: 12.sp),
        Row(children: [_range(context), const Spacer(), _toggle(context)]),
        SizedBox(height: 14.sp),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _trend
              ? KeyedSubtree(
                  key: const ValueKey('trend'),
                  child: _trendView(context, cells),
                )
              : KeyedSubtree(
                  key: const ValueKey('grid'),
                  child: _grid(context, cells),
                ),
        ),
        SizedBox(height: 12.sp),
        _legend(context),
        if (_sel != null) ...[
          SizedBox(height: 16.sp),
          Container(height: 1, color: k.border.withValues(alpha: 0.6)),
          SizedBox(height: 14.sp),
          _detail(context, _sel!),
        ],
        if (widget.patternCard != null && !(c.isPlus && pattern != null)) ...[
          SizedBox(height: 16.sp),
          widget.patternCard!,
        ],
      ],
    );
  }

  // ---------------------------------------------------------------- top

  Widget _header(BuildContext context) => Text(
    'HOW YOU FELT',
    style: AppText.caps.copyWith(
      fontSize: 12.sp,
      letterSpacing: 1.1,
      color: context.k.faint,
    ),
  );

  /// ‹ 5 Oct – 1 Nov ›
  Widget _range(BuildContext context) {
    final k = context.k;
    Widget arrow(IconData icon, String label, VoidCallback? onTap) =>
        CircleIconButton(
          icon: icon,
          label: label,
          size: 30.sp,
          background: k.text.withValues(alpha: 0.06),
          onTap: onTap,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(
          PhosphorIconsBold.caretLeft,
          'Earlier weeks',
          c.canFeelBack ? c.feelBack : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.sp),
          child: Text(
            c.feelRange,
            style: AppText.small.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: k.muted,
            ),
          ),
        ),
        arrow(
          PhosphorIconsBold.caretRight,
          'Later weeks',
          c.feelPage.value > 0 ? c.feelForward : null,
        ),
      ],
    );
  }

  Widget _chips(BuildContext context, List<String> effects) {
    final k = context.k;
    Widget chip(String id, String label) {
      final on = _filter == id;
      return Padding(
        padding: EdgeInsets.only(right: 6.sp),
        child: Semantics(
          button: true,
          selected: on,
          label: id == 'all' ? 'All side effects' : 'Only $label',
          excludeSemantics: true,
          child: PressScale(
            onTap: () {
              Haptics.instance.selectionClick();
              setState(() => _filter = id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 32.sp,
              padding: EdgeInsets.symmetric(horizontal: 12.sp),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? k.text : Colors.transparent,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: on ? k.text : k.border, width: 1.5),
              ),
              child: Text(
                label,
                style: AppText.small.copyWith(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: on ? k.card : k.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('all', 'All'),
          for (final id in effects) chip(id, Catalog.symptomLabel(id)),
        ],
      ),
    );
  }

  Widget _toggle(BuildContext context) {
    final k = context.k;
    Widget seg(String label, bool trend) {
      final on = _trend == trend;
      return Semantics(
        button: true,
        selected: on,
        label: '$label view',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            if (on) return;
            Haptics.instance.selectionClick();
            setState(() => _trend = trend);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 28.sp,
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? k.card : Colors.transparent,
              borderRadius: BorderRadius.circular(9.sp),
            ),
            child: Text(
              label,
              style: AppText.small.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: on ? k.text : k.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(2.sp),
      decoration: BoxDecoration(
        color: k.cardAlt,
        borderRadius: BorderRadius.circular(11.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('Grid', false), seg('Trend', true)],
      ),
    );
  }

  // --------------------------------------------------------------- grid

  Widget _grid(BuildContext context, List<FeelCell> cells) {
    final k = context.k;
    final today = Dates.dateOnly(DateTime.now());
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final (i, n) in names.indexed) ...[
                if (i > 0) SizedBox(width: 6.sp),
                Expanded(
                  child: Text(
                    n,
                    textAlign: TextAlign.center,
                    style: AppText.tiny.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: k.faint,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 6.sp),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6.sp,
          crossAxisSpacing: 6.sp,
          children: [for (final x in cells) _tile(context, x, today)],
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, FeelCell x, DateTime today) {
    final k = context.k;
    if (x.inFuture) return const SizedBox.shrink();
    final dark = k.selectedBorder == AppColors.lime;
    final level = c.feelLevel(x, _filter);
    final filled = level >= 0;
    final onDark = filled && level >= 2;
    final isToday = Dates.sameDay(x.date, today);
    final picked = _sel != null && Dates.sameDay(_sel!, x.date);
    final fg = onDark
        ? AppColors.white
        : (filled ? AppColors.tangerineText : (isToday ? k.text : k.faint));
    return Semantics(
      button: true,
      selected: picked,
      label:
          '${Dates.shortWithDay(x.date)}: '
          '${filled ? _levels[level] : 'no check-in'}'
          '${x.doseDay ? ', dose day' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pick(x.date),
        child: AnimatedScale(
          scale: picked ? 1.08 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            decoration: BoxDecoration(
              color: filled ? heat[level] : Colors.transparent,
              borderRadius: BorderRadius.circular(11.sp),
              border: picked ? Border.all(color: k.text, width: 2) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  x.date.day == 1
                      ? '1 ${Dates.monthShort(x.date.month)}'
                      : '${x.date.day}',
                  style: AppText.tiny.copyWith(
                    fontSize: x.date.day == 1 ? 10.sp : 12.sp,
                    fontWeight: isToday || filled
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (isToday)
                  Positioned(
                    bottom: 5.sp,
                    child: Container(
                      width: 10.sp,
                      height: 2.sp,
                      decoration: BoxDecoration(
                        color: onDark ? AppColors.white : k.text,
                        borderRadius: BorderRadius.circular(1.sp),
                      ),
                    ),
                  ),
                if (x.doseDay)
                  Positioned(
                    top: 3.sp,
                    right: 3.sp,
                    child: PhosphorIcon(
                      _doseIcon,
                      size: 10.sp,
                      color: onDark
                          ? AppColors.white
                          : (dark ? AppColors.lime : AppColors.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    TextStyle t() => AppText.tiny.copyWith(fontSize: 11.5.sp, color: k.muted);
    return ExcludeSemantics(
      child: Row(
        children: [
          Text('Fine', style: t()),
          SizedBox(width: 6.sp),
          for (final h in heat) ...[
            Container(
              width: 12.sp,
              height: 10.sp,
              decoration: BoxDecoration(
                color: h,
                borderRadius: BorderRadius.circular(3.sp),
              ),
            ),
            SizedBox(width: 3.sp),
          ],
          SizedBox(width: 3.sp),
          Text('Severe', style: t()),
          const Spacer(),
          if (!c.isDaily) ...[
            PhosphorIcon(
              _doseIcon,
              size: 13.sp,
              color: dark ? AppColors.lime : AppColors.ink,
            ),
            SizedBox(width: 5.sp),
            Text('Dose day', style: t()),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------- trend

  Widget _trendView(BuildContext context, List<FeelCell> cells) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final shown = cells.where((x) => !x.inFuture).toList();
    final levels = [for (final x in shown) c.feelLevel(x, _filter)];
    final selIndex = _sel == null
        ? -1
        : shown.indexWhere((x) => Dates.sameDay(x.date, _sel!));
    final h = 120.sp;
    TextStyle t() => AppText.tiny.copyWith(fontSize: 11.sp, color: k.faint);
    return Column(
      children: [
        Semantics(
          label: 'Trend of how rough each day was. Tap or drag to see a day',
          child: LayoutBuilder(
            builder: (context, box) {
              void pickAt(double dx) {
                if (shown.isEmpty) return;
                final step = box.maxWidth / (shown.length - 1).clamp(1, 27);
                final i = (dx / step).round().clamp(0, shown.length - 1);
                _pick(shown[i].date);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Tap or drag: the day under the finger, as on the weight
                // chart. The day details below follow along.
                onTapDown: (e) => pickAt(e.localPosition.dx),
                onHorizontalDragStart: (e) => pickAt(e.localPosition.dx),
                onHorizontalDragUpdate: (e) => pickAt(e.localPosition.dx),
                child: CustomPaint(
                  size: Size(box.maxWidth, h),
                  painter: _TrendPainter(
                    levels: levels,
                    doses: [for (final x in shown) x.doseDay],
                    selected: selIndex,
                    heat: heat,
                    line: AppColors.tangerine,
                    grid: k.border,
                    ink: k.text,
                    dose: dark ? AppColors.lime : AppColors.ink,
                    doseIcon: _doseIcon,
                    surface: k.card,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 6.sp),
        ExcludeSemantics(
          child: Row(
            children: [
              Text(Dates.short(c.feelStart), style: t()),
              const Spacer(),
              Text(
                c.feelPage.value == 0 ? 'Today' : Dates.short(c.feelEnd),
                style: t(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- detail

  Widget _detail(BuildContext context, DateTime day) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final t = c.tracker;
    final log = t.dayLog(day);
    final checked = log.hasCheckIn;
    final level = checked ? ProgressController.dayLevel(log) : -1;
    final isToday = Dates.sameDay(day, DateTime.now());
    final dose = c.isDaily ? null : t.doseOn(day);
    final title = switch (level) {
      -1 => 'No check-in',
      0 => 'Felt fine',
      1 => 'Mild side effects',
      2 => 'Moderate side effects',
      _ => 'Severe side effects',
    };
    final effects = [
      for (final id in log.symptoms) (id, c.symptomLevel(log, id)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42.sp,
              height: 42.sp,
              decoration: BoxDecoration(
                color: level >= 0 ? heat[level] : k.cardAlt,
                borderRadius: BorderRadius.circular(13.sp),
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: AppText.title.copyWith(
                  fontSize: 16.sp,
                  color: level >= 2
                      ? AppColors.white
                      : (level >= 0 ? AppColors.tangerineText : k.text),
                ),
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (isToday ? 'Today' : Dates.long(day)).toUpperCase(),
                    style: AppText.caps.copyWith(
                      fontSize: 11.sp,
                      letterSpacing: 1,
                      color: k.faint,
                    ),
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    title,
                    style: AppText.title.copyWith(
                      fontSize: 15.sp,
                      color: k.text,
                    ),
                  ),
                ],
              ),
            ),
            if (dose != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.sp,
                  vertical: 6.sp,
                ),
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.lime.withValues(alpha: 0.14)
                      : AppColors.limeSoft,
                  borderRadius: BorderRadius.circular(14.sp),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsBold.syringe,
                      size: 13.sp,
                      color: dark ? AppColors.lime : AppColors.limeText,
                    ),
                    SizedBox(width: 5.sp),
                    Text(
                      Catalog.mgLabel(dose.strengthMg),
                      style: AppText.small.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: dark ? AppColors.lime : AppColors.limeText,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (log.mood case final m?) ...[
          SizedBox(height: 12.sp),
          Row(
            children: [
              ThreeD(Catalog.moods[m].icon, size: 22.sp),
              SizedBox(width: 8.sp),
              Text(
                'Mood: ${Catalog.moods[m].label}',
                style: AppText.bodyStrong.copyWith(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: k.text,
                ),
              ),
            ],
          ),
        ],
        for (final (id, l) in effects)
          Padding(
            padding: EdgeInsets.only(top: 10.sp),
            child: Semantics(
              label: '${Catalog.symptomLabel(id)}: ${_levels[l]}',
              excludeSemantics: true,
              child: Row(
                children: [
                  SizedBox(
                    width: 96.sp,
                    child: Text(
                      Catalog.symptomLabel(id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: k.text,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.sp),
                      child: SizedBox(
                        height: 8.sp,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(
                                color: k.border.withValues(alpha: 0.55),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: l / 3,
                              heightFactor: 1,
                              child: ColoredBox(color: heat[l]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 74.sp,
                    child: Text(
                      _levels[l],
                      textAlign: TextAlign.right,
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: k.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (checked && effects.isEmpty && log.mood == null)
          Padding(
            padding: EdgeInsets.only(top: 10.sp),
            child: Text(
              'No side effects logged.',
              style: AppText.small.copyWith(fontSize: 13.sp, color: k.muted),
            ),
          ),
        if ((log.note ?? '').isNotEmpty) ...[
          SizedBox(height: 10.sp),
          Text(
            '“${log.note}”',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.small.copyWith(
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
              color: k.muted,
            ),
          ),
        ],
        SizedBox(height: 14.sp),
        PressScale(
          semanticLabel: checked ? 'Edit this check-in' : 'Check in',
          onTap: () => c.openCheckIn(day),
          child: Container(
            height: 44.sp,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: checked ? Colors.transparent : k.text,
              borderRadius: BorderRadius.circular(22.sp),
              border: Border.all(color: k.text, width: 1.5),
            ),
            child: Text(
              checked
                  ? 'Edit check-in'
                  : (isToday ? 'Check in today' : 'Add a check-in'),
              style: AppText.bodyStrong.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: checked ? k.text : k.card,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Daily roughness across the 4 weeks, drawn like the weight chart: a
/// smooth line through the check-ins (days without one are skipped) with
/// a soft fill, dose days as dashed lines, and a dot on the latest day.
class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.levels,
    required this.doses,
    required this.selected,
    required this.heat,
    required this.line,
    required this.grid,
    required this.ink,
    required this.dose,
    required this.doseIcon,
    required this.surface,
  });

  final List<int> levels;
  final List<bool> doses;
  final int selected;
  final List<Color> heat;
  final Color line;
  final Color grid;
  final Color ink;
  final Color dose;
  final IconData doseIcon;
  final Color surface;

  /// Smooth line through the points that never overshoots them
  /// (monotone cubic, Fritsch–Carlson), as in the weight chart.
  static Path _smooth(List<Offset> pts) {
    final n = pts.length;
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    if (n == 1) return p;
    final dx = [for (var i = 0; i < n - 1; i++) pts[i + 1].dx - pts[i].dx];
    final sl = [
      for (var i = 0; i < n - 1; i++)
        dx[i] == 0 ? 0.0 : (pts[i + 1].dy - pts[i].dy) / dx[i],
    ];
    final m = List<double>.filled(n, 0);
    m[0] = sl[0];
    m[n - 1] = sl[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = sl[i - 1] * sl[i] <= 0 ? 0 : (sl[i - 1] + sl[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      final h = dx[i] / 3;
      p.cubicTo(
        pts[i].dx + h,
        pts[i].dy + m[i] * h,
        pts[i + 1].dx - h,
        pts[i + 1].dy - m[i + 1] * h,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    return p;
  }

  void _dashed(Canvas c, double x, double top, double bottom, Paint p) {
    for (var y = top; y < bottom; y += 5) {
      c.drawLine(Offset(x, y), Offset(x, (y + 2).clamp(top, bottom)), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const top = 12.0;
    final bottom = size.height - 6;
    // Up to today on the current page, so the line ends at the right edge.
    final step = size.width / (levels.length - 1).clamp(1, 27);
    double y(int l) => bottom - (bottom - top) * l / 3;

    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var l = 0; l <= 3; l++) {
      canvas.drawLine(Offset(0, y(l)), Offset(size.width, y(l)), gridPaint);
    }

    final dosePaint = Paint()
      ..color = dose.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(doseIcon.codePoint),
        style: TextStyle(
          fontFamily: doseIcon.fontFamily,
          package: doseIcon.fontPackage,
          fontSize: 12,
          color: dose,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    for (var i = 0; i < doses.length; i++) {
      if (!doses[i]) continue;
      final x = (i * step).clamp(icon.width / 2, size.width - icon.width / 2);
      _dashed(canvas, i * step, top + 8, bottom, dosePaint);
      icon.paint(canvas, Offset(x - icon.width / 2, top - 8));
    }

    final idx = [
      for (var i = 0; i < levels.length; i++)
        if (levels[i] >= 0) i,
    ];
    final pts = [for (final i in idx) Offset(i * step, y(levels[i]))];
    if (pts.isNotEmpty) {
      final path = _smooth(pts);
      if (pts.length > 1) {
        final area = Path.from(path)
          ..lineTo(pts.last.dx, bottom)
          ..lineTo(pts.first.dx, bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [line.withValues(alpha: 0.28), line.withValues(alpha: 0)],
            ).createShader(Rect.fromLTRB(0, top, size.width, bottom)),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = line,
      );

      void dot(Offset o, int l, double r) {
        canvas.drawCircle(o, r + 2, Paint()..color = surface);
        canvas.drawCircle(o, r, Paint()..color = heat[l]);
        canvas.drawCircle(
          o,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = line,
        );
      }

      // The latest check-in.
      dot(pts.last, levels[idx.last], 5.5);
    }

    if (selected >= 0 && selected < levels.length) {
      final x = selected * step;
      canvas.drawLine(
        Offset(x, top - 6),
        Offset(x, bottom),
        Paint()
          ..color = ink.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );
      final l = levels[selected];
      if (l >= 0) {
        final o = Offset(x, y(l));
        canvas.drawCircle(o, 7, Paint()..color = surface);
        canvas.drawCircle(o, 5, Paint()..color = heat[l]);
        canvas.drawCircle(
          o,
          5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = ink,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.levels != levels ||
      old.doses != doses ||
      old.selected != selected ||
      old.line != line ||
      old.ink != ink ||
      old.surface != surface;
}
