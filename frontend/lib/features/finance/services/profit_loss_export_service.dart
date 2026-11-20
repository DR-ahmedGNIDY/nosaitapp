import 'dart:typed_data';

import 'package:basketball_academy/features/expenses/domain/entities/expense_entity.dart';
import 'package:basketball_academy/features/finance/domain/profit_loss_entity.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// سطر في تفاصيل التقرير.
class PlRow {
  final String label;
  final double value;
  final bool total;
  final bool net;

  const PlRow(this.label, this.value, {this.total = false, this.net = false});
}

/// تصدير تقرير الأرباح والخسائر (PDF / Excel) + أدوات تنسيق مشتركة.
class ProfitLossExportService {
  ProfitLossExportService._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static final _navy = PdfColor.fromHex('#1A2B4A');
  static final _orange = PdfColor.fromHex('#E85D04');
  static final _green = PdfColor.fromHex('#2D9748');
  static final _red = PdfColor.fromHex('#DC2626');
  static final _grey = PdfColor.fromHex('#6B7280');
  static final _light = PdfColor.fromHex('#F3F4F6');

  static String money(double v) {
    final r = (v * 100).roundToDouble() / 100;
    final f = NumberFormat(r == r.roundToDouble() ? '#,##0' : '#,##0.00', 'en');
    return f.format(r);
  }

  static String fmtDay(String ymd) {
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : DateFormat('dd/MM/yyyy', 'ar').format(d);
  }

  static String range(String from, String to) => '${fmtDay(from)} - ${fmtDay(to)}';

  static String pct(double? v) {
    if (v == null) return '—';
    final sign = v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}%';
  }

  /// تفاصيل التقرير (مشتركة بين الشاشة و PDF و Excel).
  static List<PlRow> rows(ProfitLossEntity d) {
    final cats = d.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      PlRow('اشتراكات اللاعبين', d.revSubscriptions),
      PlRow('رسوم المباريات', d.revMatches),
      PlRow('مبيعات المتجر', d.revStore),
      PlRow('إجمالي الإيرادات', d.revenueTotal, total: true),
      for (final e in cats) PlRow('مصروفات: ${expenseCategoryLabels[e.key] ?? e.key}', e.value),
      PlRow('الرواتب المصروفة', d.payrollPaid),
      PlRow('إجمالي التكاليف', d.costsTotal, total: true),
      PlRow(d.isProfit ? 'صافي الربح' : 'صافي الخسارة', d.netProfit, total: true, net: true),
    ];
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  static Future<Uint8List> pdf(
    ProfitLossEntity d, {
    required String academyName,
    required String currencyLabel,
  }) async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));

    pw.Widget t(String s, {double size = 10, bool bold = false, PdfColor? color}) => pw.Text(
          s,
          style: pw.TextStyle(font: bold ? _bold : _regular, fontSize: size, color: color ?? _navy),
        );
    pw.Widget cell(String s, {bool bold = false, PdfColor? color}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: t(s, bold: bold, color: color),
        );

    String cur(double v) => '${money(v)} $currencyLabel';
    final netColor = d.isProfit ? _green : _red;

    pw.Widget statBox(String label, double value, PdfColor color) => pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.symmetric(horizontal: 3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: color, width: 1.2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(children: [
              t(label, color: _grey),
              t(cur(value), size: 14, bold: true, color: color),
            ]),
          ),
        );

    final doc = pw.Document(theme: pw.ThemeData.withFont(base: _regular, bold: _bold));
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  t('تقرير الأرباح والخسائر', size: 16, bold: true),
                  t(academyName, size: 11, color: _grey),
                ],
              ),
              t(range(d.from, d.to), size: 11, bold: true, color: _orange),
            ],
          ),
          pw.Divider(color: _orange, thickness: 1.5),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            statBox('الإيرادات', d.revenueTotal, _green),
            statBox('التكاليف', d.costsTotal, _red),
            statBox(d.isProfit ? 'صافي الربح' : 'صافي الخسارة', d.netProfit, netColor),
          ]),
          pw.SizedBox(height: 6),
          t(
            'هامش الربح: ${d.margin == null ? '—' : '${d.margin!.toStringAsFixed(1)}%'}'
            '   •   مقارنة بالفترة السابقة (${range(d.prevFrom, d.prevTo)}): '
            'الإيرادات ${pct(d.changeRevenue)} • التكاليف ${pct(d.changeCosts)} • الربح ${pct(d.changeNet)}',
            size: 9,
            color: _grey,
          ),
          pw.SizedBox(height: 12),
          t('التفاصيل', size: 12, bold: true),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: _light, width: 0.6),
            columnWidths: const {0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(2.5)},
            children: [
              for (final r in rows(d))
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: r.total ? _light : PdfColors.white),
                  children: [
                    cell(cur(r.value), bold: r.total, color: r.net ? netColor : null),
                    cell(r.label, bold: r.total),
                  ],
                ),
            ],
          ),
          if (d.payrollPendingDue > 0) ...[
            pw.SizedBox(height: 6),
            t('رواتب مستحقة لم تُصرف بعد (غير محسوبة): ${cur(d.payrollPendingDue)}', size: 9, color: _grey),
          ],
          if (d.salariesMaybeDoubleCounted) ...[
            pw.SizedBox(height: 4),
            t('تنبيه: يوجد مصروف بتصنيف "مرتبات" ورواتب مصروفة من كشف المرتبات في نفس الفترة — تأكد من عدم تكرارها.',
                size: 9, color: _red),
          ],
          if (d.cashbox.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            t('تحصيلات الاشتراكات حسب طريقة الدفع', size: 12, bold: true),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: _light, width: 0.6),
              columnWidths: const {0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(2.5)},
              children: [
                for (final e in d.cashbox.entries)
                  pw.TableRow(children: [cell(cur(e.value)), cell(PaymentMethods.label(e.key))]),
              ],
            ),
          ],
          pw.SizedBox(height: 12),
          t('آخر 12 شهر', size: 12, bold: true),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: _light, width: 0.6),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _navy),
                children: [
                  for (final h in ['الربح', 'التكاليف', 'الإيرادات', 'الشهر'])
                    cell(h, bold: true, color: PdfColors.white),
                ],
              ),
              for (final p in d.monthly)
                pw.TableRow(children: [
                  cell(money(p.profit), color: p.profit >= 0 ? _green : _red),
                  cell(money(p.costs)),
                  cell(money(p.revenue)),
                  cell(p.month),
                ]),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  // ── Excel ──────────────────────────────────────────────────────────────────

  static Uint8List excel(
    ProfitLossEntity d, {
    required String academyName,
    required String currencyLabel,
  }) {
    final book = Excel.createExcel();
    final sheet = book['الأرباح والخسائر'];
    book.delete('Sheet1');
    sheet.isRTL = true;
    sheet.setColumnWidth(0, 34);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);

    final header = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A2B4A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final totalStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'));
    var row = 0;
    void set(int col, Object? v, {CellStyle? style}) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      c.value = v is num ? DoubleCellValue(v.toDouble()) : TextCellValue(v?.toString() ?? '');
      if (style != null) c.cellStyle = style;
    }

    set(0, 'تقرير الأرباح والخسائر — $academyName', style: header);
    set(1, range(d.from, d.to), style: header);
    row += 2;
    set(0, 'البيان', style: header);
    set(1, 'القيمة ($currencyLabel)', style: header);
    row++;
    for (final r in rows(d)) {
      set(0, r.label, style: r.total ? totalStyle : null);
      set(1, r.value, style: r.total ? totalStyle : null);
      row++;
    }
    set(0, 'هامش الربح %');
    set(1, d.margin ?? 0);
    row++;
    set(0, 'رواتب مستحقة لم تُصرف (غير محسوبة)');
    set(1, d.payrollPendingDue);
    row += 2;

    set(0, 'المقارنة بالفترة السابقة (${range(d.prevFrom, d.prevTo)})', style: header);
    set(1, 'الحالية', style: header);
    set(2, 'السابقة', style: header);
    set(3, 'التغيّر %', style: header);
    row++;
    for (final (label, current, previous, change) in [
      ('الإيرادات', d.revenueTotal, d.prevRevenue, d.changeRevenue),
      ('التكاليف', d.costsTotal, d.prevCosts, d.changeCosts),
      ('صافي الربح', d.netProfit, d.prevNet, d.changeNet),
    ]) {
      set(0, label);
      set(1, current);
      set(2, previous);
      set(3, change ?? '—');
      row++;
    }
    row++;

    if (d.cashbox.isNotEmpty) {
      set(0, 'تحصيلات الاشتراكات حسب طريقة الدفع', style: header);
      set(1, 'المبلغ', style: header);
      row++;
      for (final e in d.cashbox.entries) {
        set(0, PaymentMethods.label(e.key));
        set(1, e.value);
        row++;
      }
      row++;
    }

    set(0, 'الشهر', style: header);
    set(1, 'الإيرادات', style: header);
    set(2, 'التكاليف', style: header);
    set(3, 'الربح', style: header);
    row++;
    for (final p in d.monthly) {
      set(0, p.month);
      set(1, p.revenue);
      set(2, p.costs);
      set(3, p.profit);
      row++;
    }

    final bytes = book.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }
}
