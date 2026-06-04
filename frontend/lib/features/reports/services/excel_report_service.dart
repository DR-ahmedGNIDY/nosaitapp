import 'dart:io';
import 'dart:typed_data';

import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player/domain/usecases/get_players_usecase.dart';
import 'package:basketball_academy/features/reports/domain/models/report_filter.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_revenue_summary_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_subscriptions_by_academy_usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/get_evaluations_by_academy_usecase.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelReportService {
  ExcelReportService._();

  // ── style helpers ──────────────────────────────────────────────────────────

  static CellStyle _headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1A2B4A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

  static CellStyle _altRowStyle() => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F9FAFB'),
      );

  static CellStyle _totalStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E85D04'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

  static void _setCell(Sheet sheet, int row, int col, Object? value,
      {CellStyle? style}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: col,
      rowIndex: row,
    ));
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else {
      cell.value = TextCellValue(value?.toString() ?? '');
    }
    if (style != null) cell.cellStyle = style;
  }

  static void _setHeaders(Sheet sheet, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 0, i, headers[i], style: _headerStyle());
      sheet.setColumnWidth(i, 22);
    }
  }

  static String _fmtDate(DateTime d) =>
      DateFormat('dd/MM/yyyy', 'ar').format(d);

  // ── share ──────────────────────────────────────────────────────────────────

  static Future<void> shareExcel(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: fileName,
    );
  }

  // ── 1. Players Report ──────────────────────────────────────────────────────

  static Future<Uint8List> generatePlayersExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    final getPlayers = sl<GetPlayersUsecase>();
    final getSubs = sl<GetSubscriptionsByAcademyUsecase>();

    final playersResult = await getPlayers(
      GetPlayersParams(academyId: filter.academyId, page: 1, limit: 200),
    );
    final players = playersResult.fold((_) => [], (v) => v.players);

    final subsResult = await getSubs(
      GetSubscriptionsByAcademyParams(
        academyId: filter.academyId!,
        page: 1,
        limit: 500,
      ),
    );
    final subs = subsResult.fold((_) => [], (v) => v.subscriptions);
    final activePlayerIds = subs
        .where((s) => s.isActive)
        .map((s) => s.playerId)
        .toSet();

    final excel = Excel.createExcel();
    final sheet = excel['اللاعبون'];
    excel.delete('Sheet1');

    _setHeaders(sheet, [
      'الكود',
      'الاسم',
      'تاريخ الميلاد',
      'اسم ولي الأمر',
      'مهنة ولي الأمر',
      'رقم الهاتف',
      'حالة الاشتراك',
    ]);

    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      final status = activePlayerIds.contains(p.id) ? 'نشط' : 'منتهي / لا يوجد';

      _setCell(sheet, row, 0, p.playerCode, style: style);
      _setCell(sheet, row, 1, p.fullName, style: style);
      _setCell(sheet, row, 2, _fmtDate(p.birthDate), style: style);
      _setCell(sheet, row, 3, p.parentName, style: style);
      _setCell(sheet, row, 4, p.parentJob ?? '-', style: style);
      _setCell(sheet, row, 5, p.parentPhone, style: style);
      _setCell(sheet, row, 6, status, style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 2. Subscriptions Report ────────────────────────────────────────────────

  static Future<Uint8List> generateSubscriptionsExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    final getSubs = sl<GetSubscriptionsByAcademyUsecase>();

    final result = await getSubs(
      GetSubscriptionsByAcademyParams(
        academyId: filter.academyId!,
        status: filter.subscriptionStatus,
        page: 1,
        limit: 500,
      ),
    );
    final subs = result.fold((_) => [], (v) => v.subscriptions);

    final excel = Excel.createExcel();
    final sheet = excel['الاشتراكات'];
    excel.delete('Sheet1');

    _setHeaders(sheet, [
      'اسم اللاعب',
      'نوع العملية',
      'المبلغ (ريال)',
      'تاريخ البداية',
      'تاريخ الانتهاء',
      'الحالة',
    ]);

    double total = 0;
    for (var i = 0; i < subs.length; i++) {
      final s = subs[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      total += s.amount;

      _setCell(sheet, row, 0, s.playerId, style: style);
      _setCell(sheet, row, 1, s.typeLabel, style: style);
      _setCell(sheet, row, 2, s.amount, style: style);
      _setCell(sheet, row, 3, _fmtDate(s.startDate), style: style);
      _setCell(sheet, row, 4, _fmtDate(s.endDate), style: style);
      _setCell(sheet, row, 5, s.statusLabel, style: style);
    }

    // Total row
    if (subs.isNotEmpty) {
      final totalRow = subs.length + 1;
      _setCell(sheet, totalRow, 0, 'الإجمالي', style: _totalStyle());
      _setCell(sheet, totalRow, 2, total, style: _totalStyle());
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 3. Revenue Report ──────────────────────────────────────────────────────

  static Future<Uint8List> generateRevenueExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    final getRevenue = sl<GetRevenueSummaryUsecase>();
    final result = await getRevenue(
      GetRevenueSummaryParams(academyId: filter.academyId!),
    );
    final data = result.fold((_) => <String, dynamic>{}, (v) => v);

    final excel = Excel.createExcel();
    final sheet = excel['الإيرادات'];
    excel.delete('Sheet1');

    _setHeaders(sheet, ['البيان', 'القيمة']);
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 20);

    final rows = [
      ['إجمالي الإيرادات (ريال)', (data['totalRevenue'] ?? 0).toDouble()],
      ['إيرادات الشهر الحالي (ريال)', (data['monthlyRevenue'] ?? 0).toDouble()],
      ['عدد الاشتراكات الجديدة', data['newSubscriptionsCount'] ?? 0],
      ['عدد التجديدات', data['renewalsCount'] ?? 0],
      ['الاشتراكات النشطة', data['activeCount'] ?? 0],
      ['الاشتراكات المنتهية', data['expiredCount'] ?? 0],
    ];

    for (var i = 0; i < rows.length; i++) {
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      _setCell(sheet, row, 0, rows[i][0], style: style);
      _setCell(sheet, row, 1, rows[i][1], style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 4. Evaluations Report ──────────────────────────────────────────────────

  static Future<Uint8List> generateEvaluationsExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    final getEvals = sl<GetEvaluationsByAcademyUsecase>();
    final result = await getEvals(
      GetEvaluationsByAcademyParams(
        academyId: filter.academyId!,
        startDate: filter.startDate,
        endDate: filter.endDate,
        limit: 200,
      ),
    );
    final evals = result.fold((_) => [], (v) => v.evaluations);

    final excel = Excel.createExcel();
    final sheet = excel['التقييمات'];
    excel.delete('Sheet1');

    _setHeaders(sheet, [
      'اسم اللاعب',
      'تاريخ التقييم',
      'اللياقة',
      'المهارات الأساسية',
      'الهجوم',
      'الدفاع',
      'الالتزام',
      'المتوسط',
      'التقدير',
    ]);

    for (var i = 0; i < evals.length; i++) {
      final e = evals[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();

      _setCell(sheet, row, 0, e.evaluatorName ?? e.playerId, style: style);
      _setCell(sheet, row, 1, _fmtDate(e.evaluationDate), style: style);
      _setCell(sheet, row, 2, e.fitness, style: style);
      _setCell(sheet, row, 3, e.basicSkills, style: style);
      _setCell(sheet, row, 4, e.attack, style: style);
      _setCell(sheet, row, 5, e.defense, style: style);
      _setCell(sheet, row, 6, e.commitment, style: style);
      _setCell(sheet, row, 7, e.average, style: style);
      _setCell(sheet, row, 8, e.gradeLabel, style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }
}
