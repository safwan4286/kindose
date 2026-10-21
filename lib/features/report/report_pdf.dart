import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/water_units.dart';
import 'report_data.dart';

/// Builds the doctor report as PDF bytes: one A4 page for most periods,
/// more pages only when the dose list is long.
class ReportPdf {
  ReportPdf._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF15142B);
  static const PdfColor _text2 = PdfColor.fromInt(0xFF3A3946);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6A76);
  static const PdfColor _faint = PdfColor.fromInt(0xFF9A99A3);
  static const PdfColor _paper = PdfColor.fromInt(0xFFF6F5F1);
  static const PdfColor _line = PdfColor.fromInt(0xFFDCDAD2);
  static const PdfColor _hair = PdfColor.fromInt(0xFFF0EEE8);
  static const PdfColor _lime = PdfColor.fromInt(0xFFD6F84C);
  static const PdfColor _limeText = PdfColor.fromInt(0xFF3E5205);

  static Future<Uint8List> build(ReportData r) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Figtree-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Figtree-Bold.ttf'),
    );

    final doc = pw.Document(title: 'Treatment summary', author: 'Kindose');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 28),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Logged by the patient in the Kindose app. Not a medical record and not medical advice.',
                style: const pw.TextStyle(fontSize: 7.5, color: _faint),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 7.5, color: _faint),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          _header(r),
          pw.SizedBox(height: 8),
          if (r.medicineLine.isNotEmpty) _medicine(r),
          pw.SizedBox(height: 10),
          _tiles(r),
          if (r.sections.weight && r.allWeights.length >= 2) ...[
            pw.SizedBox(height: 12),
            _weightChart(r),
          ],
          if (r.sections.doses) ...[pw.SizedBox(height: 12), ..._doses(r)],
          if (r.sections.sideEffects) ...[
            pw.SizedBox(height: 12),
            _sideEffects(r),
          ],
          if (r.questions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _questions(r),
          ],
          if (r.sections.notes && r.notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            ..._notes(r),
          ],
        ],
      ),
    );
    return doc.save();
  }

  // ------------------------------------------------------------------ parts

  static pw.TextStyle _label() => pw.TextStyle(
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    color: _muted,
    letterSpacing: 0.5,
  );

  static pw.Widget _section(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Text(text.toUpperCase(), style: _label()),
  );

  static pw.Widget _header(ReportData r) {
    final name = r.patientName;
    final dob = r.patientDob;
    final now = DateTime.now();
    pw.Widget meta(String k, String v) => pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$k  ',
            style: const pw.TextStyle(fontSize: 9, color: _faint),
          ),
          pw.TextSpan(
            text: v,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _text2,
            ),
          ),
        ],
      ),
    );
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 9,
                      height: 9,
                      decoration: pw.BoxDecoration(
                        color: _lime,
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: _ink, width: 1),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(
                      'KINDOSE · PATIENT-LOGGED SUMMARY',
                      style: _label(),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Treatment summary',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Text(
                  r.periodNote.isEmpty
                      ? r.period
                      : '${r.period} · ${r.periodNote}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _text2,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (name != null && name.isNotEmpty) meta('Name', name),
              if (dob != null && dob.isNotEmpty) meta('Born', dob),
              meta('Made', '${Dates.short(now)} ${now.year}'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _medicine(ReportData r) => pw.RichText(
    text: pw.TextSpan(
      children: [
        const pw.TextSpan(
          text: 'Medicine  ',
          style: pw.TextStyle(fontSize: 9.5, color: _faint),
        ),
        pw.TextSpan(
          text: r.medicineLine,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _tile(String label, String value, String sub) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(9, 7, 9, 7),
      decoration: const pw.BoxDecoration(
        color: _paper,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(sub, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
        ],
      ),
    ),
  );

  static String _days(int n) => n == 1 ? '1 day' : '$n days';

  static pw.Widget _tiles(ReportData r) {
    final goal = r.profile?.proteinGoalG ?? 100;
    final waterGoal = r.profile?.waterGoalMl ?? 2500;
    // The person's own water unit (no Get lookups while building the PDF).
    final oz = r.profile?.useOz ?? false;
    String water(int ml) => oz
        ? '${Water.toOz(ml).round()} fl oz'
        : '${(ml / 1000).toStringAsFixed(1)} L';
    final tiles = <pw.Widget>[
      if (r.sections.weight)
        _tile('WEIGHT CHANGE', r.periodChange ?? '—', r.weightSub),
      if (r.sections.doses)
        _tile(
          'DOSES',
          r.dosesValue,
          r.isDaily ? 'days taken' : 'on schedule (±1 day)',
        ),
      if (r.sections.nutrition) ...[
        _tile(
          'PROTEIN',
          r.loggedDays == 0 ? '—' : '${r.avgProtein} g/day',
          'goal $goal g · met ${r.proteinDaysHit} of ${_days(r.days)}'
              '${r.loggedDays < r.days ? ' · avg of ${_days(r.loggedDays)} logged' : ''}',
        ),
        _tile(
          'WATER',
          r.waterDays == 0
              ? '—'
              : '${water(r.avgWaterMl)}/day',
          'goal ${water(waterGoal)} · avg of ${_days(r.waterDays)} logged',
        ),
      ],
    ];
    if (tiles.isEmpty) return pw.SizedBox();
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 7),
          tiles[i],
        ],
      ],
    );
  }

  /// Round-number grid values covering [lo]–[hi] (3 to 5 lines), same
  /// rule as the app's chart.
  static List<double> _ticks(double lo, double hi) {
    var span = hi - lo;
    if (span < 1) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
      span = 1;
    }
    const steps = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0];
    final step = steps.firstWhere((s) => span / s <= 4, orElse: () => 100);
    final a = (lo / step).floor() * step;
    final b = (hi / step).ceil() * step;
    return [for (var v = a; v <= b + 1e-9; v += step) v];
  }

  static String _tick(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Whole-treatment weight line in the app's style: smooth line with a
  /// light lime fill, round-number grid, short dose tags with a dotted
  /// guide, the report period shaded, goal line only when it fits.
  static pw.Widget _weightChart(ReportData r) {
    final pts = r.allWeights;
    final values = [for (final w in pts) r.shown(w.kg)];
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    final goalKg = r.profile?.goalWeightKg;
    final goal = goalKg == null ? null : r.shown(goalKg);
    final dataSpan = math.max(1.0, hi - lo);
    final showGoal =
        goal != null && goal >= lo - dataSpan * 0.6 && goal <= hi + dataSpan;
    if (showGoal) {
      lo = math.min(lo, goal);
      hi = math.max(hi, goal);
    }
    final ticks = _ticks(lo - 0.2, hi + 0.2);
    lo = ticks.first;
    hi = ticks.last;
    final first = pts.first.date;
    final last = pts.last.date;
    final span = math.max(1, Dates.daysBetween(first, last));
    const h = 120.0;
    const labelW = 24.0;
    // PDF y grows upward: plot from 14 (date labels below) to h - 18 (tags).
    const plotBottom = 14.0;
    const plotTop = h - 18;
    final lineFill = PdfColor(_lime.red, _lime.green, _lime.blue, 0.35).flatten();
    final period = PdfColor(_ink.red, _ink.green, _ink.blue, 0.04).flatten();
    final guide = PdfColor(_ink.red, _ink.green, _ink.blue, 0.3).flatten();
    const tagBg = PdfColor.fromInt(0xFFF1FAD0);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section('Weight (${r.unit}) · since start, dose changes marked'),
        pw.LayoutBuilder(
          builder: (ctx, c) {
            final w = (c?.maxWidth ?? 519) - labelW;
            double x(DateTime d) =>
                4 + (w - 8) * Dates.daysBetween(first, d).clamp(0, span) / span;
            double y(double v) =>
                plotBottom + (v - lo) / (hi - lo) * (plotTop - plotBottom);
            final xs = [for (final p in pts) x(p.date)];
            final ys = [for (final v in values) y(v)];
            final markers = r.doseChanges
                .skip(1)
                .where((m) => !m.$1.isBefore(first) && !m.$1.isAfter(last))
                .toList();
            // Tags left to right; one that would overlap the last is left out.
            final tags = <(double, String)>[];
            var lastTag = -999.0;
            for (final m in markers) {
              final mx = x(m.$1);
              if (mx - lastTag >= 34) {
                tags.add((mx, Catalog.mgLabel(m.$2)));
                lastTag = mx;
              }
            }

            // Smooth line that never overshoots a weigh-in (monotone cubic).
            void smooth(PdfGraphics g) {
              final n = xs.length;
              g.moveTo(xs[0], ys[0]);
              if (n == 1) return;
              final dx = [for (var i = 0; i < n - 1; i++) xs[i + 1] - xs[i]];
              final sl = [
                for (var i = 0; i < n - 1; i++)
                  dx[i] == 0 ? 0.0 : (ys[i + 1] - ys[i]) / dx[i],
              ];
              final m = List<double>.filled(n, 0);
              m[0] = sl[0];
              m[n - 1] = sl[n - 2];
              for (var i = 1; i < n - 1; i++) {
                m[i] = sl[i - 1] * sl[i] <= 0 ? 0 : (sl[i - 1] + sl[i]) / 2;
              }
              for (var i = 0; i < n - 1; i++) {
                final k = dx[i] / 3;
                g.curveTo(
                  xs[i] + k,
                  ys[i] + m[i] * k,
                  xs[i + 1] - k,
                  ys[i + 1] - m[i + 1] * k,
                  xs[i + 1],
                  ys[i + 1],
                );
              }
            }

            final mid = DateTime.fromMillisecondsSinceEpoch(
              (first.millisecondsSinceEpoch + last.millisecondsSinceEpoch) ~/ 2,
            );
            const tickStyle = pw.TextStyle(fontSize: 7, color: _faint);
            return pw.Stack(
              children: [
                pw.CustomPaint(
                  size: PdfPoint(w + labelW, h),
                  painter: (canvas, size) {
                    // Report period, very light.
                    final px0 = x(r.from.isBefore(first) ? first : r.from);
                    final px1 = x(r.to.isAfter(last) ? last : r.to);
                    if (px1 > px0) {
                      canvas
                        ..setFillColor(period)
                        ..drawRect(px0, plotBottom, px1 - px0, plotTop - plotBottom)
                        ..fillPath();
                    }
                    // Grid.
                    canvas
                      ..setStrokeColor(_hair)
                      ..setLineWidth(0.6);
                    for (final t in ticks) {
                      canvas
                        ..moveTo(0, y(t))
                        ..lineTo(w, y(t))
                        ..strokePath();
                    }
                    // Dose changes: dotted guides.
                    canvas
                      ..setStrokeColor(guide)
                      ..setLineWidth(0.6)
                      ..setLineDashPattern([1.5, 2]);
                    for (final m in markers) {
                      canvas
                        ..moveTo(x(m.$1), plotBottom)
                        ..lineTo(x(m.$1), plotTop + 2)
                        ..strokePath();
                    }
                    // Goal, dashed lime.
                    if (showGoal) {
                      canvas
                        ..setStrokeColor(_limeText)
                        ..setLineWidth(0.9)
                        ..setLineDashPattern([3, 3])
                        ..moveTo(0, y(goal))
                        ..lineTo(w, y(goal))
                        ..strokePath();
                    }
                    canvas.setLineDashPattern();
                    // Fill under the line, then the line.
                    if (xs.length > 1) {
                      smooth(canvas);
                      canvas
                        ..lineTo(xs.last, plotBottom)
                        ..lineTo(xs.first, plotBottom)
                        ..closePath()
                        ..setFillColor(lineFill)
                        ..fillPath();
                    }
                    smooth(canvas);
                    canvas
                      ..setStrokeColor(_ink)
                      ..setLineWidth(1.6)
                      ..setLineJoin(PdfLineJoin.round)
                      ..setLineCap(PdfLineCap.round)
                      ..strokePath();
                    // Latest weigh-in: lime dot, ink ring.
                    canvas
                      ..setFillColor(_lime)
                      ..drawEllipse(xs.last, ys.last, 3.2, 3.2)
                      ..fillPath()
                      ..setStrokeColor(_ink)
                      ..setLineWidth(1.2)
                      ..drawEllipse(xs.last, ys.last, 3.2, 3.2)
                      ..strokePath();
                  },
                ),
                for (final t in ticks)
                  pw.Positioned(
                    right: 0,
                    top: h - y(t) - 4,
                    child: pw.Text(_tick(t), style: tickStyle),
                  ),
                if (showGoal)
                  pw.Positioned(
                    left: 2,
                    top: h - y(goal) - 10,
                    child: pw.Text(
                      'Goal ${_tick(goal)}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: _limeText,
                      ),
                    ),
                  ),
                for (final (tx, label) in tags)
                  pw.Positioned(
                    left: math.min(tx - 1, w - 34),
                    top: 0,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: tagBg,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        label,
                        style: pw.TextStyle(
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _limeText,
                        ),
                      ),
                    ),
                  ),
                pw.Positioned(
                  left: 0,
                  bottom: 0,
                  child: pw.Text(Dates.short(first), style: tickStyle),
                ),
                if (span >= 6)
                  pw.Positioned(
                    left: 0,
                    right: labelW,
                    bottom: 0,
                    child: pw.Center(
                      child: pw.Text(Dates.short(mid), style: tickStyle),
                    ),
                  ),
                pw.Positioned(
                  right: labelW,
                  bottom: 0,
                  child: pw.Text(Dates.short(last), style: tickStyle),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    Map<int, pw.TableColumnWidth>? widths,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _hair, width: 0.6),
      ),
      headerDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.8)),
      ),
      headerStyle: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: _muted,
      ),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 8.5, color: _ink),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3.5,
      ),
      columnWidths: widths,
    );
  }

  static List<pw.Widget> _doses(ReportData r) {
    final injections = r.doses.any((d) => d.site.isNotEmpty);
    return [
      _section('Doses (${r.doses.length})'),
      if (r.doses.isEmpty)
        pw.Text(
          'No doses logged in this period.',
          style: const pw.TextStyle(fontSize: 8.5, color: _muted),
        )
      else
        _table(
          [
            'DATE',
            'TIME',
            'DOSE',
            if (injections) 'SPOT',
            if (injections) 'HOW IT FELT',
            'NOTE',
          ],
          [
            for (final d in r.doses)
              [
                Dates.shortWithDay(d.takenAt),
                Dates.time(d.takenAt),
                Catalog.mgLabel(d.strengthMg),
                if (injections) d.site.isEmpty ? '' : Catalog.siteName(d.site),
                if (injections)
                  d.pain == null ? '' : Catalog.painLabels[d.pain!.clamp(0, 3)],
                d.note ?? '',
              ],
          ],
        ),
    ];
  }

  static pw.Widget _sideEffects(ReportData r) {
    final left = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section(
          'Side effects · ${r.checkInDays} check-in${r.checkInDays == 1 ? '' : 's'} in ${_days(r.days)}',
        ),
        if (r.symptoms.isEmpty)
          pw.Text(
            'No side effects logged.',
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          )
        else ...[
          _table(
            ['SYMPTOM', 'DAYS', 'STRONGEST', if (!r.isDaily) 'USUAL DAY*'],
            [
              for (final s in r.symptoms)
                [
                  s.label,
                  '${s.days}',
                  _cap(Catalog.levelWords[s.strongest]),
                  if (!r.isDaily) s.usualDay ?? '—',
                ],
            ],
          ),
          if (!r.isDaily)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                '*Day after the dose when it was logged most. Shown with 3+ dose weeks.',
                style: const pw.TextStyle(fontSize: 7, color: _faint),
              ),
            ),
        ],
        if (!r.isDaily && r.hardestDay != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              '${r.hardestDay!}  (from check-ins)',
              style: pw.TextStyle(
                fontSize: 8.5,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
      ],
    );
    final lines = [
      r.foodNoise,
      r.appetite,
      r.moodLine,
    ].where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return left;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 6, child: left),
        pw.SizedBox(width: 14),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _section('Food noise and appetite'),
              for (final l in lines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    l,
                    style: const pw.TextStyle(fontSize: 8.5, color: _ink),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static pw.Widget _questions(ReportData r) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _ink, width: 1.2),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "PATIENT'S QUESTIONS",
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        for (var i = 0; i < r.questions.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              '${i + 1}. ${r.questions[i]}',
              style: const pw.TextStyle(fontSize: 9.5, color: _ink),
            ),
          ),
      ],
    ),
  );

  static List<pw.Widget> _notes(ReportData r) => [
    _section('My notes'),
    for (final n in r.notes)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(
          n,
          style: const pw.TextStyle(fontSize: 8.5, color: _ink),
        ),
      ),
  ];
}
