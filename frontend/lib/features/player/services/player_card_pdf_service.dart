import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// بطاقة تعريف دائمة للاعب كـ PDF أفقية (Landscape, نسبة 1.586 — 856×540).
/// تصميم "مقسّم": يسار = QR كبير + عبارة المسح، يمين = اسم الأكاديمية والرياضة
/// واسم اللاعب والكود. لا تحتوي أي بيانات متغيّرة (لا صورة/تواريخ).
/// تدعم العربية RTL بخط Cairo، وتضمن عدم إنتاج PDF فارغ.
class PlayerCardPdfService {
  PlayerCardPdfService._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static const PdfColor _orange = PdfColor.fromInt(0xFFE85D04);
  static const PdfColor _orangeDark = PdfColor.fromInt(0xFFC44D00);
  static const PdfColor _navy = PdfColor.fromInt(0xFF1A2B4A);
  static const PdfColor _softBg = PdfColor.fromInt(0xFFFFF3EB);

  static Future<void> _loadFonts() async {
    if (_regular != null && _bold != null) return;
    _regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  static pw.Widget _t(String text,
      {bool bold = false,
      double size = 12,
      PdfColor? color,
      pw.TextAlign align = pw.TextAlign.right,
      int maxLines = 2}) {
    return pw.Text(
      text,
      textDirection: pw.TextDirection.rtl,
      textAlign: align,
      maxLines: maxLines,
      style: pw.TextStyle(
        font: bold ? _bold : _regular,
        fontSize: size,
        color: color ?? _navy,
        lineSpacing: 2,
      ),
    );
  }

  static Future<Uint8List> generate({
    required String academyName,
    required String fullName,
    required String playerCode,
    required String sport,
    required String qrData,
  }) async {
    // ─── 1) تسجيل القيم قبل البناء (تشخيص PDF الفارغ) ──────────────────────
    debugPrint('[CARD-PDF] ===== generating permanent player card =====');
    debugPrint('[CARD-PDF] academyName="$academyName"');
    debugPrint('[CARD-PDF] playerName="$fullName"');
    debugPrint('[CARD-PDF] playerCode="$playerCode"');
    debugPrint('[CARD-PDF] sport="$sport"');
    debugPrint('[CARD-PDF] qrData="$qrData"');

    // ─── 2) التحقق من بيانات الـ QR (منع PDF فارغ) ─────────────────────────
    if (qrData.trim().isEmpty || playerCode.trim().isEmpty) {
      debugPrint('[CARD-PDF] ERROR: qrData/playerCode فارغ — إيقاف التوليد');
      throw StateError('تعذّر توليد رمز QR — بيانات اللاعب غير مكتملة');
    }

    // ─── 3) تحميل خط Cairo ─────────────────────────────────────────────────
    try {
      await _loadFonts();
      debugPrint('[CARD-PDF] fonts loaded OK');
    } catch (e) {
      debugPrint('[CARD-PDF] ERROR loading fonts: $e');
      rethrow;
    }

    // ─── 4) بناء البطاقة (مقسّم: يسار QR / يمين النصوص) ─────────────────────
    final pdf = pw.Document();
    const pageFormat = PdfPageFormat(856, 540, marginAll: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (ctx) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(20),
                border: pw.Border.all(color: _orange, width: 3),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── اليمين: الأكاديمية + الرياضة + اسم اللاعب + الكود ──────
                  pw.Expanded(
                    flex: 6,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(34, 30, 34, 30),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // أعلى: اسم الأكاديمية + الرياضة
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _t(academyName, bold: true, size: 36, color: _navy),
                              pw.SizedBox(height: 8),
                              if (sport.isNotEmpty)
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: pw.BoxDecoration(
                                    color: _softBg,
                                    borderRadius: pw.BorderRadius.circular(20),
                                    border: pw.Border.all(color: _orange, width: 1),
                                  ),
                                  child: _t(sport,
                                      bold: true, size: 16, color: _orangeDark,
                                      maxLines: 1),
                                ),
                            ],
                          ),
                          // وسط: اسم اللاعب (أكبر عنصر) + الكود
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _t(fullName, bold: true, size: 46, color: _navy),
                              pw.SizedBox(height: 12),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 7),
                                decoration: pw.BoxDecoration(
                                  color: _orange,
                                  borderRadius: pw.BorderRadius.circular(22),
                                ),
                                child: _t(playerCode,
                                    bold: true, size: 20, color: PdfColors.white,
                                    maxLines: 1),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  // ── اليسار: لوحة QR كبيرة + عبارة المسح ────────────────────
                  pw.Container(
                    width: 320,
                    decoration: const pw.BoxDecoration(
                      color: _softBg,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(17),
                        bottomLeft: pw.Radius.circular(17),
                      ),
                    ),
                    padding: const pw.EdgeInsets.all(26),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Expanded(
                          child: pw.Center(
                            child: pw.AspectRatio(
                              aspectRatio: 1,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(12),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius: pw.BorderRadius.circular(14),
                                  border: pw.Border.all(color: _orange, width: 2),
                                ),
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: qrData,
                                  color: _navy,
                                  drawText: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        _t('امسح الكود لتسجيل الحضور والانصراف',
                            bold: true,
                            size: 13,
                            color: _navy,
                            align: pw.TextAlign.center,
                            maxLines: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    debugPrint('[CARD-PDF] SUCCESS — pdf bytes=${bytes.length}');
    return bytes;
  }
}
