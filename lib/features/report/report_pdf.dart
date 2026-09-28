import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
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

  static pw.Widget _tiles(ReportData r) {
    final goal = r.profile?.proteinGoalG ?? 100;
    final waterGoal = (r.profile?.waterGoalMl ?? 2500) / 1000;
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
          'goal $goal g · met ${r.proteinDaysHit} of ${r.days} days',
        ),
        _tile(
          'WATER',
          r.loggedDays == 0
              ? '—'
              : '${(r.avgWaterMl / 1000).toStringAsFixed(1)} L/day',
          'goal ${waterGoal.toStringAsFixed(1)} L · ${r.loggedDays} days logged',
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

  /// Whole-treatment weight line, dose changes marked, report period shaded.
  static pw.Widget _weightChart(ReportData r) {
    final pts = r.allWeights;
    final values = [for (final w in pts) r.shown(w.kg)];
    final lo = (values.reduce(math.min) - 0.5).floorToDouble();
    final hi = (values.reduce(math.max) + 0.5).ceilToDouble();
    final first = pts.first.date;
    final span = math.max(1, Dates.daysBetween(first, pts.last.date));
    const h = 110.0;
    const labelW = 26.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section('Weight (${r.unit}) · since start, dose changes marked'),
        pw.LayoutBuilder(
          builder: (ctx, c) {
            final w = (c?.maxWidth ?? 519) - labelW;
            double x(DateTime d) =>
                w * Dates.daysBetween(first, d).clamp(0, span) / span;
            // PDF y grows upward: bottom = 14 (room for labels), top = h - 12.
            double y(double v) => 14 + (v - lo) / (hi - lo) * (h - 26);
            final markers = r.doseChanges
                .skip(1)
                .where((m) => !m.$1.isBefore(first))
                .toList();
            return pw.Stack(
              children: [
                pw.CustomPaint(
                  size: PdfPoint(w + labelW, h),
                  painter: (canvas, size) {
                    // Report period.
                    final px0 = x(r.from.isBefore(first) ? first : r.from);
                    final px1 = x(r.to);
                    canvas
                      ..setFillColor(
                        PdfColor(
                          _lime.red,
                          _lime.green,
                          _lime.blue,
                          0.25,
                        ).flatten(),
                      )
                      ..drawRect(px0, 14, math.max(2, px1 - px0), h - 26)
                      ..fillPath();
                    // Grid.
                    canvas.setStrokeColor(_hair);
                    canvas.setLineWidth(0.6);
                    for (final gv in [lo, (lo + hi) / 2, hi]) {
                      canvas
                        ..moveTo(0, y(gv))
                        ..lineTo(w, y(gv))
                        ..strokePath();
                    }
                    // Dose markers.
                    canvas
                      ..setStrokeColor(
                        PdfColor(
                          _ink.red,
                          _ink.green,
                          _ink.blue,
                          0.3,
                        ).flatten(),
                      )
                      ..setLineWidth(0.8);
                    for (final m in markers) {
                      canvas
                        ..moveTo(x(m.$1), 14)
                        ..lineTo(x(m.$1), h - 4)
                        ..strokePath();
                    }
                    // Line.
                    canvas
                      ..setStrokeColor(_ink)
                      ..setLineWidth(1.6)
                      ..setLineJoin(PdfLineJoin.round)
                      ..setLineCap(PdfLineCap.round);
                    for (var i = 0; i < pts.length; i++) {
                      final px = x(pts[i].date);
                      final py = y(values[i]);
                      if (i == 0) {
                        canvas.moveTo(px, py);
                      } else {
                        canvas.lineTo(px, py);
                      }
                    }
                    canvas.strokePath();
                    canvas
                      ..setFillColor(_ink)
                      ..drawEllipse(x(pts.last.date), y(values.last), 2.6, 2.6)
                      ..fillPath();
                  },
                ),
                for (final gv in [lo, (lo + hi) / 2, hi])
                  pw.Positioned(
                    right: 0,
                    top: h - y(gv) - 5,
                    child: pw.Text(
                      gv.toStringAsFixed(0),
                      style: const pw.TextStyle(fontSize: 7, color: _faint),
                    ),
                  ),
                for (final m in markers)
                  pw.Positioned(
                    left: math.min(x(m.$1) + 3, w - 70),
                    top: 0,
                    child: pw.Text(
                      '${Catalog.mgLabel(m.$2)} from ${Dates.short(m.$1)}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: _limeText,
                      ),
                    ),
                  ),
                pw.Positioned(
                  left: 0,
                  bottom: 0,
                  child: pw.Text(
                    Dates.short(first),
                    style: const pw.TextStyle(fontSize: 7, color: _faint),
                  ),
                ),
                pw.Positioned(
                  right: labelW,
                  bottom: 0,
                  child: pw.Text(
                    Dates.short(pts.last.date),
                    style: const pw.TextStyle(fontSize: 7, color: _faint),
                  ),
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
        _section('Side effects · ${r.checkInDays} check-ins in ${r.days} days'),
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
