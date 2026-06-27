import 'dart:typed_data';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:basketball_academy/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:basketball_academy/features/attendance/services/attendance_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:printing/printing.dart';

enum _Period { thisMonth, last3Months, thisYear }

extension _PeriodExt on _Period {
  String get label {
    switch (this) {
      case _Period.thisMonth:
        return 'هذا الشهر';
      case _Period.last3Months:
        return 'آخر 3 أشهر';
      case _Period.thisYear:
        return 'هذه السنة';
    }
  }

  ({String start, String end}) range() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    String fmt(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
    final end = fmt(now);
    switch (this) {
      case _Period.thisMonth:
        return (start: fmt(DateTime(now.year, now.month, 1)), end: end);
      case _Period.last3Months:
        return (start: fmt(DateTime(now.year, now.month - 2, 1)), end: end);
      case _Period.thisYear:
        return (start: fmt(DateTime(now.year, 1, 1)), end: end);
    }
  }
}

class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String academyId;
  const AttendanceReportScreen({super.key, required this.academyId});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  _Period _period = _Period.thisMonth;
  String? _sport;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final academyName = academy?.name ?? 'الأكاديمية';
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];

    final range = _period.range();
    final filter = AttendanceReportFilter(
      academyId: widget.academyId,
      startDate: range.start,
      endDate: range.end,
      sport: _sport,
    );
    final reportAsync = ref.watch(attendanceReportProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقرير الحضور والغياب'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // فلتر الفترة
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Row(
              children: _Period.values.map((p) {
                final isSel = p == _period;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: ChoiceChip(
                      label: Text(p.label),
                      selected: isSel,
                      onSelected: (_) => setState(() => _period = p),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.white : AppColors.grey700,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // فلتر الرياضة
          if (isMultiSport)
            SizedBox(
              height: 44.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                itemCount: sports.length + 1,
                separatorBuilder: (_, __) => Gap(8.w),
                itemBuilder: (_, i) {
                  final value = i == 0 ? null : sports[i - 1];
                  final isSel = value == _sport;
                  return ChoiceChip(
                    label: Text(value ?? 'الكل'),
                    selected: isSel,
                    onSelected: (_) => setState(() => _sport = value),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.white : AppColors.grey700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppColors.white,
                  );
                },
              ),
            ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 56.sp, color: AppColors.error),
                    Gap(12.h),
                    Text('تعذّر تحميل التقرير',
                        style: TextStyle(
                            fontSize: 14.sp, color: AppColors.grey700)),
                    Gap(12.h),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(attendanceReportProvider(filter)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (report) => _ReportBody(report: report),
            ),
          ),
        ],
      ),
      floatingActionButton: reportAsync.maybeWhen(
        data: (report) => FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          onPressed: _exporting
              ? null
              : () => _exportPdf(report, academyName, _sport),
          icon: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('تصدير PDF'),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _exportPdf(
      AttendanceReport report, String academyName, String? sport) async {
    setState(() => _exporting = true);
    try {
      final bytes = await AttendancePdfService.generate(
        report: report,
        academyName: academyName,
        sportLabel: sport,
      );
      if (!mounted) return;
      _showExportSheet(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر إنشاء التقرير: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportSheet(Uint8List bytes) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(12.h),
            ListTile(
              leading: const Icon(Icons.print_outlined,
                  color: AppColors.secondary),
              title: const Text('معاينة / طباعة'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(onLayout: (_) async => bytes);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.share_outlined, color: AppColors.primary),
              title: const Text('مشاركة'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.sharePdf(
                    bytes: bytes, filename: 'attendance_report.pdf');
              },
            ),
            Gap(8.h),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final AttendanceReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final overallExpected = report.totalPresent + report.totalAbsent;
    final overallRate = overallExpected > 0
        ? ((report.totalPresent / overallExpected) * 100).round()
        : 0;

    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        // بطاقات الملخص
        Row(
          children: [
            _SummaryCard(
                label: 'اللاعبون',
                value: '${report.playersCount}',
                color: AppColors.secondary),
            Gap(8.w),
            _SummaryCard(
                label: 'الحضور',
                value: '${report.totalPresent}',
                color: const Color(0xFF2D9748)),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            _SummaryCard(
                label: 'الغياب',
                value: '${report.totalAbsent}',
                color: AppColors.error),
            Gap(8.w),
            _SummaryCard(
                label: 'نسبة الالتزام',
                value: '$overallRate%',
                color: AppColors.primary),
          ],
        ),
        Gap(16.h),
        if (report.rows.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Center(
              child: Text('لا توجد بيانات لهذه الفترة',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.grey500)),
            ),
          )
        else
          ...report.rows.map((r) => _RowTile(row: r)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white)),
            Gap(2.h),
            Text(label,
                style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final AttendanceReportRow row;
  const _RowTile({required this.row});

  Color get _rateColor {
    if (row.rate >= 75) return const Color(0xFF2D9748);
    if (row.rate >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // دائرة النسبة
          Container(
            width: 48.w,
            height: 48.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rateColor.withValues(alpha: 0.12),
            ),
            child: Text(
              '${row.rate}%',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: _rateColor,
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.fullName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                Gap(2.h),
                Text(
                  [
                    row.playerCode,
                    if (row.sport != null && row.sport!.isNotEmpty) row.sport!,
                  ].join(' • '),
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _miniStat('حضور', '${row.present}', const Color(0xFF2D9748)),
              Gap(2.h),
              _miniStat('غياب', '${row.absent}', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
        Text(value,
            style: TextStyle(
                fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
