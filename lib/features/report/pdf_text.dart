import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Text for the PDF. Figtree draws most of it; anything Figtree has no
/// glyph for (emoji, Arabic, Hindi, Chinese …) is drawn by Flutter's own
/// text engine, with the phone's fonts, and placed as a sharp picture.
class PdfText {
  PdfText(ByteData regular, ByteData bold)
    : _regular = TtfParser(regular).charToGlyphIndexMap.keys.toSet(),
      _bold = TtfParser(bold).charToGlyphIndexMap.keys.toSet();

  final Set<int> _regular;
  final Set<int> _bold;
  final _pictures = <String, pw.Widget>{};

  /// Drawn 4× larger than placed, so it stays crisp when zoomed or printed.
  static const double _scale = 4;

  static bool _isBold(pw.TextStyle s) => s.fontWeight == pw.FontWeight.bold;

  static String _key(String s, pw.TextStyle st) =>
      '${st.fontSize}|${_isBold(st)}|${st.color?.toInt()}|$s';

  bool fits(String s, pw.TextStyle style) {
    final glyphs = _isBold(style) ? _bold : _regular;
    return s.runes.every((c) => c <= 0x20 || glyphs.contains(c));
  }

  /// Draws [s] ahead of time if Figtree can't, wrapped at [width] points.
  Future<void> prepare(String s, pw.TextStyle style, double width) async {
    if (s.isEmpty || fits(s, style)) return;
    final key = _key(s, style);
    if (_pictures.containsKey(key)) return;
    if (_pictures.length > 200) _pictures.clear();
    try {
      _pictures[key] = await _draw(s, style, width);
    } catch (_) {
      // Leave it to pw.Text, which skips the missing glyphs.
    }
  }

  /// [s] as PDF text, or as its picture when one was prepared.
  pw.Widget text(String s, pw.TextStyle style) =>
      _pictures[_key(s, style)] ?? pw.Text(s, style: style);

  static Future<pw.Widget> _draw(
    String s,
    pw.TextStyle style,
    double width,
  ) async {
    final rtl = _startsRtl(s);
    final painter = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'Figtree',
          fontSize: (style.fontSize ?? 9) * _scale,
          fontWeight: _isBold(style) ? FontWeight.w700 : FontWeight.w400,
          color: Color(style.color?.toInt() ?? 0xFF15142B),
          height: 1.25,
        ),
      ),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout(maxWidth: width * _scale);
    final w = painter.width.ceil().clamp(1, 1 << 14);
    final h = painter.height.ceil().clamp(1, 1 << 14);
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), Offset.zero);
    painter.dispose();
    final image = await recorder.endRecording().toImage(w, h);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return pw.Image(
      pw.MemoryImage(png!.buffer.asUint8List()),
      width: w / _scale,
      height: h / _scale,
    );
  }

  /// True when the first letter is Hebrew or Arabic script.
  static bool _startsRtl(String s) {
    for (final c in s.runes) {
      if ((c >= 0x0590 && c <= 0x08FF) ||
          (c >= 0xFB1D && c <= 0xFDFF) ||
          (c >= 0xFE70 && c <= 0xFEFF)) {
        return true;
      }
      final letter =
          (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c >= 0xC0;
      if (letter) return false;
    }
    return false;
  }
}
