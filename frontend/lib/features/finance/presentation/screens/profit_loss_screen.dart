import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/currency_provider.dart';
import 'package:basketball_academy/features/finance/domain/profit_loss_entity.dart';
import 'package:basketball_academy/features/finance/presentation/providers/profit_loss_provider.dart';
import 'package:basketball_academy/features/finance/services/profit_loss_export_service.dart';
import 'package:basketball_academy/features/reports/services/excel_report_service.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:printing/printing.dart';

/// بطاقة الدخول لتقرير الأرباح والخسائر (في شاشة التقارير).
class ProfitLossEntryCard extends StatelessWidget {
  final String academyId;
  final String academyName;

  const ProfitLossEntryCard({super.key, required this.academyId, required this.academyName});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProfitLossScreen(academyId: academyId, academyName: academyName),
        )),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF1A2B4A), Color(0xFF2D9748)]),
          ),
          child: const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الأرباح والخسائر',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('صافي الربح، المقارنة بالفترة السابقة، الخزنة وآخر 12 شهر',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Preset { thisMonth, lastMonth, last3Months, thisYear, custom }

const _presetLabels = {
  _Preset.thisMonth: 'هذا الشهر',
  _Preset.lastMonth: 'الشهر الماضي',
  _Preset.last3Months: 'آخر 3 شهور',
  _Preset.thisYear: 'هذه السنة',
  _Preset.custom: 'فترة مخصصة',
};

const _green = Color(0xFF2D9748);
const _red = Color(0xFFDC2626);
const _amber = Color(0xFFB45309);

/// تقرير الأرباح والخسائر: الإيرادات − (المصروفات + الرواتب المصروفة) لفترة،
/// مع المقارنة بالفترة السابقة، الخزنة حسب طريقة الدفع، ورسم آخر 12 شهر.
class ProfitLossScreen extends ConsumerStatefulWidget {
  final String academyId;
  final String academyName;

  const ProfitLossScreen({super.key, required this.academyId, required this.academyName});

  @override
  ConsumerState<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends ConsumerState<ProfitLossScreen> {
  _Preset _preset = _Preset.thisMonth;
  DateTimeRange? _custom;
  bool _exporting = false;

  static String _ymd(DateTime d) => DateFormat('yyyy-MM-dd', 'en').format(d);

  ProfitLossQuery get _query {
    final now = DateTime.now();
    late DateTime from;
    late DateTime to;
    switch (_preset) {
      case _Preset.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0);
      case _Preset.lastMonth:
        from = DateTime(now.year, now.month - 1, 1);
        to = DateTime(now.year, now.month, 0);
      case _Preset.last3Months:
        from = DateTime(now.year, now.month - 2, 1);
        to = DateTime(now.year, now.month + 1, 0);
      case _Preset.thisYear:
        from = DateTime(now.year, 1, 1);
        to = DateTime(now.year, 12, 31);
      case _Preset.custom:
        from = _custom?.start ?? DateTime(now.year, now.month, 1);
        to = _custom?.end ?? now;
    }
    return (academyId: widget.academyId, from: _ymd(from), to: _ymd(to));
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _custom ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _custom = picked;
        _preset = _Preset.custom;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _export(ProfitLossEntity d, {required bool pdf}) async {
    final currency = ref.read(academyCurrencyLabelProvider(widget.academyId));
    final name = 'profit_loss_${d.from}_${d.to}';
    setState(() => _exporting = true);
    try {
      if (pdf) {
        final bytes = await ProfitLossExportService.pdf(d,
            academyName: widget.academyName, currencyLabel: currency);
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      } else {
        final bytes = ProfitLossExportService.excel(d,
            academyName: widget.academyName, currencyLabel: currency);
        await ExcelReportService.shareExcel(bytes, '$name.xlsx');
      }
    } catch (e) {
      _snack('تعذّر التصدير: $e', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final async = ref.watch(profitLossProvider(query));
    final currency = ref.watch(academyCurrencyLabelProvider(widget.academyId));
    final data = async.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأرباح والخسائر'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تصدير PDF',
            onPressed: data == null || _exporting ? null : () => _export(data, pdf: true),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'تصدير Excel',
            onPressed: data == null || _exporting ? null : () => _export(data, pdf: false),
            icon: const Icon(Icons.table_view_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(profitLossProvider(query).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          children: [
            _periodChips(),
            Gap(4.h),
            Text(
              ProfitLossExportService.range(query.from, query.to),
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey600),
            ),
            Gap(12.h),
            async.when(
              loading: () => Padding(
                padding: EdgeInsets.symmetric(vertical: 80.h),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: EdgeInsets.symmetric(vertical: 60.h),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
                    Gap(8.h),
                    Text(e.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
                    Gap(8.h),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(profitLossProvider(query)),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (d) => _content(d, currency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChips() {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: [
        for (final p in _Preset.values)
          ChoiceChip(
            label: Text(_presetLabels[p]!, style: TextStyle(fontSize: 12.sp)),
            selected: _preset == p,
            onSelected: (_) {
              if (p == _Preset.custom) {
                _pickCustom();
              } else {
                setState(() => _preset = p);
              }
            },
          ),
      ],
    );
  }

  Widget _content(ProfitLossEntity d, String currency) {
    String cur(double v) => '${ProfitLossExportService.money(v)} $currency';
    final netColor = d.isProfit ? _green : _red;
    final rows = ProfitLossExportService.rows(d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // صافي الربح
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: netColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: netColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(d.isProfit ? 'صافي الربح' : 'صافي الخسارة',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.grey700)),
              Gap(2.h),
              Text(cur(d.netProfit),
                  style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w900, color: netColor)),
              Gap(4.h),
              Text(
                [
                  if (d.margin != null) 'هامش الربح ${d.margin!.toStringAsFixed(1)}%',
                  'مقارنة بـ ${ProfitLossExportService.range(d.prevFrom, d.prevTo)}: '
                      '${ProfitLossExportService.pct(d.changeNet)}',
                ].join('  •  '),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey600),
              ),
            ],
          ),
        ),
        Gap(10.h),
        Row(
          children: [
            Expanded(child: _stat('الإيرادات', cur(d.revenueTotal), d.changeRevenue, _green, higherIsGood: true)),
            Gap(10.w),
            Expanded(child: _stat('التكاليف', cur(d.costsTotal), d.changeCosts, _red, higherIsGood: false)),
          ],
        ),
        if (d.salariesMaybeDoubleCounted) ...[
          Gap(10.h),
          _note(
            Icons.warning_amber_rounded,
            'فيه مصروف بتصنيف "مرتبات" ورواتب مصروفة من كشف المرتبات في نفس الفترة — اتأكد إنها مش متسجلة مرتين.',
            _red,
          ),
        ],
        if (d.payrollPendingDue > 0) ...[
          Gap(10.h),
          _note(
            Icons.info_outline,
            'رواتب مستحقة لم تُصرف بعد: ${cur(d.payrollPendingDue)} (مش محسوبة في التكاليف لحد ما تتصرف).',
            _amber,
          ),
        ],
        Gap(14.h),
        _section('التفاصيل', [
          for (final r in rows)
            _line(r.label, cur(r.value),
                bold: r.total, color: r.net ? netColor : null, highlight: r.total),
        ]),
        if (d.cashbox.isNotEmpty) ...[
          Gap(14.h),
          _section('الخزنة — تحصيلات الاشتراكات حسب طريقة الدفع', [
            for (final e in (d.cashbox.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
              _line(PaymentMethods.label(e.key), cur(e.value)),
          ]),
        ],
        Gap(14.h),
        _section('آخر 12 شهر', [
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend('الإيرادات', _green),
                Gap(16.w),
                _legend('التكاليف', _red),
              ],
            ),
          ),
          Gap(8.h),
          SizedBox(height: 200.h, child: _chart(d.monthly)),
          Gap(8.h),
          for (final p in d.monthly.reversed.where((p) => p.revenue > 0 || p.costs > 0))
            _line(p.month, '${ProfitLossExportService.money(p.profit)} $currency',
                color: p.profit >= 0 ? _green : _red),
        ]),
        Gap(24.h),
      ],
    );
  }

  Widget _stat(String label, String value, double? change, Color color, {required bool higherIsGood}) {
    Color? changeColor;
    if (change != null && change != 0) {
      final good = higherIsGood ? change > 0 : change < 0;
      changeColor = good ? _green : _red;
    }
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
          Gap(2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: color)),
          ),
          Text(
            'عن الفترة السابقة ${ProfitLossExportService.pct(change)}',
            style: TextStyle(fontSize: 11.sp, color: changeColor ?? AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _note(IconData icon, String text, Color color) => Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18.sp),
            Gap(8.w),
            Expanded(child: Text(text, style: TextStyle(fontSize: 12.sp, color: AppColors.grey800))),
          ],
        ),
      );

  Widget _section(String title, List<Widget> children) => Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
            Gap(6.h),
            ...children,
          ],
        ),
      );

  Widget _line(String label, String value, {bool bold = false, Color? color, bool highlight = false}) =>
      Container(
        margin: EdgeInsets.only(top: 2.h),
        padding: EdgeInsets.symmetric(horizontal: highlight ? 8.w : 0, vertical: 6.h),
        decoration: highlight
            ? BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8.r))
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    color: AppColors.grey800,
                  )),
            ),
            Text(value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? AppColors.grey800,
                )),
          ],
        ),
      );

  Widget _legend(String label, Color color) => Row(
        children: [
          Container(width: 10.r, height: 10.r, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Gap(4.w),
          Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.grey700)),
        ],
      );

  Widget _chart(List<MonthlyProfitPoint> points) {
    if (points.isEmpty) return const SizedBox.shrink();
    final maxY = points.fold<double>(0, (m, p) => [m, p.revenue, p.costs].reduce((a, b) => a > b ? a : b));
    // الرسم من اليسار لليمين (الأقدم ← الأحدث) بغض النظر عن اتجاه الواجهة.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${points[i].monthNumber}',
                        style: TextStyle(fontSize: 10.sp, color: AppColors.grey600)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  BarChartRodData(toY: points[i].revenue, color: _green, width: 6),
                  BarChartRodData(toY: points[i].costs, color: _red, width: 6),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
