import 'dart:io';

import 'package:basketball_academy/features/finance/domain/profit_loss_entity.dart';
import 'package:basketball_academy/features/finance/services/profit_loss_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// رد السيرفر الحقيقي من فحص قاعدة البيانات المؤقتة (نوفمبر 2026).
final _json = <String, dynamic>{
  'period': {'from': '2026-11-01', 'to': '2026-11-30', 'days': 30},
  'revenue': {'subscriptions': 1000, 'matches': 150, 'store': 250, 'total': 1400},
  'expenses': {'byCategory': {'rent': 600, 'salaries': 100}, 'total': 700},
  'payroll': {'paid': 400, 'pendingDue': 350},
  'costsTotal': 1100,
  'netProfit': 300,
  'margin': 21.43,
  'cashbox': {'vodafone_cash': 300, 'cash': 500, 'instapay': 200},
  'previous': {
    'period': {'from': '2026-10-01', 'to': '2026-10-31'},
    'revenueTotal': 400,
    'costsTotal': 80,
    'netProfit': 320,
  },
  'change': {'revenue': 250, 'costs': 1275, 'netProfit': -6.25},
  'monthly': [
    {'month': '2026-10', 'revenue': 400, 'costs': 80, 'profit': 320},
    {'month': '2026-11', 'revenue': 1400, 'costs': 1100, 'profit': 300},
  ],
  'warnings': ['salaries_double_count'],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('ar'));

  test('profit & loss response parses', () {
    final d = ProfitLossEntity.fromJson(_json);
    expect(d.revenueTotal, 1400);
    expect(d.netProfit, 300);
    expect(d.isProfit, isTrue);
    expect(d.margin, 21.43);
    expect(d.expensesByCategory['rent'], 600);
    expect(d.payrollPendingDue, 350);
    expect(d.cashbox['cash'], 500);
    expect(d.changeNet, -6.25);
    expect(d.prevFrom, '2026-10-01');
    expect(d.monthly.last.monthNumber, 11);
    expect(d.salariesMaybeDoubleCounted, isTrue);
  });

  test('detail rows: revenue, expenses by size, payroll, totals, net', () {
    final rows = ProfitLossExportService.rows(ProfitLossEntity.fromJson(_json));
    expect(rows.map((r) => r.label).toList(), [
      'اشتراكات اللاعبين',
      'رسوم المباريات',
      'مبيعات المتجر',
      'إجمالي الإيرادات',
      'مصروفات: إيجار',
      'مصروفات: مرتبات',
      'الرواتب المصروفة',
      'إجمالي التكاليف',
      'صافي الربح',
    ]);
    expect(rows.last.net, isTrue);
    expect(ProfitLossExportService.pct(12.345), '+12.3%');
    expect(ProfitLossExportService.pct(null), '—');
    expect(ProfitLossExportService.money(1234.5), '1,234.50');
  });

  test('loss is labelled as a loss', () {
    final d = ProfitLossEntity.fromJson({..._json, 'netProfit': -50});
    expect(d.isProfit, isFalse);
    expect(ProfitLossExportService.rows(d).last.label, 'صافي الخسارة');
  });

  test('PDF and Excel build', () async {
    final d = ProfitLossEntity.fromJson(_json);
    final pdf = await ProfitLossExportService.pdf(d, academyName: 'أكاديمية النجوم', currencyLabel: 'جنيه');
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    final xlsx = ProfitLossExportService.excel(d, academyName: 'أكاديمية النجوم', currencyLabel: 'جنيه');
    expect(xlsx.length, greaterThan(1000));
    final out = Platform.environment['PL_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(pdf);
  });
}
