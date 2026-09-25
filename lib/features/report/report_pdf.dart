import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../resources/date_utils.dart';
import 'report_data.dart';

/// Builds the one-page doctor report as PDF bytes.
class ReportPdf {
  ReportPdf._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF121126);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5E5C7A);
  static const PdfColor _violet = PdfColor.fromInt(0xFF5B4BFF);
  static const PdfColor _soft = PdfColor.fromInt(0xFFF3F2FF);
  static const PdfColor _line = PdfColor.fromInt(0xFFE4E2F3);

  static Future<Uint8List> build(ReportData r) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Figtree-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Figtree-Bold.ttf'));

    final doc = pw.Document(title: 'Kindose report', author: 'Kindose');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Logged by the patient in Kindose. Not a medical record or device.',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ),
        build: (ctx) => [
          _header(r),
          pw.SizedBox(height: 14),
          if (r.sections.doses) ..._doses(r),
          if (r.sections.weight) ..._weight(r),
          if (r.sections.sideEffects) ..._sideEffects(r),
          if (r.sections.nutrition) ..._nutrition(r),
          if (r.sections.notes && r.notes.isNotEmpty) ..._notes(r),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _header(ReportData r) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('GLP-1 treatment summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink)),
              pw.Text('kindose', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _violet)),
            ],
          ),
          pw.SizedBox(height: 6),
          if (r.patientName != null && r.patientName!.isNotEmpty)
            pw.Text(
              'Patient: ${r.patientName}${r.patientDob == null || r.patientDob!.isEmpty ? '' : ', born ${r.patientDob}'}',
              style: const pw.TextStyle(fontSize: 10, color: _ink),
            ),
          pw.Text('Period: ${r.period}', style: const pw.TextStyle(fontSize: 10, color: _ink)),
          if (r.medicineLine.isNotEmpty)
            pw.Text('Medicine: ${r.medicineLine}', style: const pw.TextStyle(fontSize: 10, color: _ink)),
          pw.Text('Created ${Dates.short(DateTime.now())} ${DateTime.now().year}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _title(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _violet)),
      );

  static pw.Widget _row(String a, String b) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5))),
        child: pw.Row(
          children: [
            pw.Expanded(child: pw.Text(a, style: const pw.TextStyle(fontSize: 10, color: _ink))),
            pw.Text(b, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
          ],
        ),
      );

  static pw.Widget _empty(String text) =>
      pw.Text(text, style: const pw.TextStyle(fontSize: 10, color: _muted));

  static List<pw.Widget> _doses(ReportData r) => [
        _title('Doses (${r.doses.length})'),
        if (r.doses.isEmpty) _empty('No doses logged in this period.'),
        for (final d in r.doses)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5))),
            child: pw.Text(r.doseLine(d).replaceAll('·', '-'), style: const pw.TextStyle(fontSize: 10, color: _ink)),
          ),
      ];

  static List<pw.Widget> _weight(ReportData r) => [
        _title('Weight'),
        if (r.weights.isEmpty) _empty('No weigh-ins in this period.'),
        if (r.weights.isNotEmpty) ...[
          _row('First (${Dates.short(r.weights.first.date)})', '${r.weight(r.weights.first.kg)} ${r.unit}'),
          _row('Latest (${Dates.short(r.weights.last.date)})', '${r.weight(r.weights.last.kg)} ${r.unit}'),
          if (r.weightChange != null) _row('Change', r.weightChange!),
          _row('Weigh-ins', '${r.weights.length}'),
        ],
      ];

  static List<pw.Widget> _sideEffects(ReportData r) => [
        _title('Side effects'),
        _row('Days with a check-in', '${r.checkInDays}'),
        if (r.symptoms.isEmpty) _empty('No symptoms logged.'),
        for (final s in r.symptoms) _row(s.label, '${s.days} ${s.days == 1 ? 'day' : 'days'}'),
      ];

  static List<pw.Widget> _nutrition(ReportData r) => [
        _title('Protein & water'),
        if (r.loggedDays == 0) _empty('No food or water logged.'),
        if (r.loggedDays > 0) ...[
          _row('Average protein (days logged)', '${r.avgProtein} g'),
          _row('Days at protein goal', '${r.proteinDaysHit} of ${r.loggedDays}'),
          _row('Average water', '${(r.avgWaterMl / 1000).toStringAsFixed(1)} L'),
        ],
      ];

  static List<pw.Widget> _notes(ReportData r) => [
        _title('My notes'),
        for (final n in r.notes)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(n, style: const pw.TextStyle(fontSize: 10, color: _ink)),
          ),
      ];
}
