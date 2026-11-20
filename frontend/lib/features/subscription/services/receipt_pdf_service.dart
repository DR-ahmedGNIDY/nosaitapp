import 'dart:typed_data';

import 'package:basketball_academy/core/utils/currency_utils.dart';
import 'package:basketball_academy/features/subscription/domain/entities/receipt_entity.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// يولّد إيصال دفع PDF (A5) بالعربي — لوجو واسم الأكاديمية، رقم الإيصال،
/// بيانات اللاعب والاشتراك، المبلغ وطريقة الدفع، والمتبقي بعد الدفعة.
class ReceiptPdfService {
  ReceiptPdfService._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static final _orange = PdfColor.fromHex('#E85D04');
  static final _navy = PdfColor.fromHex('#1A2B4A');
  static final _grey = PdfColor.fromHex('#6B7280');
  static final _light = PdfColor.fromHex('#F3F4F6');
  static final _green = PdfColor.fromHex('#2D9748');
  static final _amber = PdfColor.fromHex('#B45309');

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  static String money(double v) {
    final r = (v * 100).roundToDouble() / 100;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(2);
  }

  /// اسم ملف الإيصال (بدون مسافات).
  static String fileName(ReceiptEntity r) =>
      'receipt_${r.receiptNoLabel.isEmpty ? r.paymentId : r.receiptNoLabel}.pdf';

  static Future<pw.ImageProvider?> _logo(String url) async {
    if (url.isEmpty) return null;
    try {
      return await networkImage(url).timeout(const Duration(seconds: 6));
    } catch (_) {
      return null; // الإيصال يطلع بدون لوجو لو فشل التحميل
    }
  }

  static Future<Uint8List> build(ReceiptEntity r) async {
    await _loadFonts();
    final logo = await _logo(r.academyLogoUrl);
    final currency = CurrencyUtils.label(r.currencyCode);
    final df = DateFormat('dd/MM/yyyy', 'ar');
    final dtf = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    pw.Widget text(String s,
            {double size = 10, bool bold = false, PdfColor? color, pw.TextAlign? align}) =>
        pw.Text(s,
            textAlign: align,
            style: pw.TextStyle(
              font: bold ? _bold : _regular,
              fontSize: size,
              color: color ?? _navy,
            ));

    pw.Widget row(String label, String value, {bool bold = false, PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              text(label, color: _grey),
              text(value, bold: bold, color: color),
            ],
          ),
        );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _regular, bold: _bold),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.fromLTRB(22, 18, 22, 16),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // الترويسة: الأكاديمية + رقم الإيصال
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null) ...[
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(logo, width: 48, height: 48, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(width: 10),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      text(r.academyName, size: 15, bold: true),
                      if (r.academyPhone.isNotEmpty) text(r.academyPhone, size: 9, color: _grey),
                      if (r.academyAddress.isNotEmpty) text(r.academyAddress, size: 9, color: _grey),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _orange,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      text('إيصال دفع', size: 11, bold: true, color: PdfColors.white),
                      if (r.receiptNoLabel.isNotEmpty)
                        text('رقم ${r.receiptNoLabel}', size: 9, color: PdfColors.white),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: _orange, thickness: 1.5),
            pw.SizedBox(height: 4),
            row('تاريخ الدفع', dtf.format(r.date)),
            pw.SizedBox(height: 6),

            // اللاعب
            _box(children: [
              text('بيانات اللاعب', bold: true, size: 11),
              pw.SizedBox(height: 4),
              row('الاسم', r.playerName, bold: true),
              if (r.playerCode.isNotEmpty) row('الكود', r.playerCode),
              if (r.parentName.isNotEmpty) row('ولي الأمر', r.parentName),
            ]),
            pw.SizedBox(height: 6),

            // الاشتراك
            _box(children: [
              text('الاشتراك', bold: true, size: 11),
              pw.SizedBox(height: 4),
              row('النوع', r.typeLabel),
              row('الفترة', '${df.format(r.startDate)} - ${df.format(r.endDate)}'),
              row('قيمة الاشتراك', '${money(r.subscriptionAmount)} $currency'),
            ]),
            pw.SizedBox(height: 7),

            // المبلغ المدفوع
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _green, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  text('المبلغ المدفوع', color: _grey),
                  text('${money(r.amount)} $currency', size: 19, bold: true, color: _green),
                  text('طريقة الدفع: ${r.methodLabel}', size: 9, color: _grey),
                  if (r.note.isNotEmpty) text('ملاحظة: ${r.note}', size: 9, color: _grey),
                ],
              ),
            ),
            pw.SizedBox(height: 7),
            row('إجمالي المدفوع حتى الآن', '${money(r.paidToDate)} $currency'),
            row(
              'المتبقي',
              r.fullyPaid ? 'لا يوجد — مدفوع بالكامل' : '${money(r.remainingAfter)} $currency',
              bold: true,
              color: r.fullyPaid ? _green : _amber,
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: _light),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                text(
                  r.recordedByName.isNotEmpty ? 'المستلم: ${r.recordedByName}' : '',
                  size: 9,
                  color: _grey,
                ),
                text('شكراً لثقتكم', size: 9, bold: true, color: _orange),
              ],
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _box({required List<pw.Widget> children}) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: pw.BoxDecoration(
          color: _light,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  /// الإيصال كصورة PNG (الصفحة الأولى من الـ PDF) — للمشاركة على واتساب.
  static Future<Uint8List> png(ReceiptEntity r, {double dpi = 150}) async {
    final pdf = await build(r);
    await for (final page in Printing.raster(pdf, pages: const [0], dpi: dpi)) {
      return page.toPng();
    }
    throw Exception('تعذّر تحويل الإيصال إلى صورة');
  }

  /// ملخص نصي للإيصال (لإرساله على واتساب كرسالة).
  static String textSummary(ReceiptEntity r) {
    final currency = CurrencyUtils.label(r.currencyCode);
    final df = DateFormat('dd/MM/yyyy', 'ar');
    final lines = [
      '🧾 إيصال دفع${r.receiptNoLabel.isNotEmpty ? ' رقم ${r.receiptNoLabel}' : ''} — ${r.academyName}',
      'اللاعب: ${r.playerName}',
      'المبلغ المدفوع: ${money(r.amount)} $currency (${r.methodLabel})',
      'التاريخ: ${df.format(r.date)}',
      'الاشتراك: ${df.format(r.startDate)} - ${df.format(r.endDate)}',
      r.fullyPaid
          ? 'الاشتراك مدفوع بالكامل ✅'
          : 'المتبقي: ${money(r.remainingAfter)} $currency',
      'شكراً لكم 🌹',
    ];
    return lines.join('\n');
  }
}
