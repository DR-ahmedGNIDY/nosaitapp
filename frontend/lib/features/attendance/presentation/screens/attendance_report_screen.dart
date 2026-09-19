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

class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String academyId;
  const AttendanceReportScreen({super.key, required this.academyId});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  String? _sport;
  String _query = ''; // بحث محلي بالاسم/الكود
  /// يفتح التقرير على "اشتراك نشط" افتراضياً.
  String _subscription = 'active';
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final academyName = academy?.name ?? 'الأكاديمية';
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];

    final filter = AttendanceReportFilter(
      academyId: widget.academyId,
      sport: _sport,
      subscription: _subscription,
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
          // توضيح أساس الحساب
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.sp, color: AppColors.primary),
                Gap(6.w),
                Expanded(
                  child: Text(
                    'الحساب من بداية الاشتراك النشط لكل لاعب حتى نهايته',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // فلتر الاشتراك — "اشتراك نشط" (الافتراضي) أو "الكل"
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: Row(
              children: const [
                ('active', 'اشتراك نشط'),
                ('all', 'الكل'),
              ].map((opt) {
                final isSel = opt.$1 == _subscription;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: ChoiceChip(
                      label: Text(opt.$2),
                      selected: isSel,
                      onSelected: (_) =>
                          setState(() => _subscription = opt.$1),
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
          // بحث بالاسم/الكود
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'بحث باسم اللاعب أو الكود',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.white,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
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
              data: (report) => _ReportBody(report: report, query: _query),
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
  final String query;
  const _ReportBody({required this.report, required this.query});

  @override
  Widget build(BuildContext context) {
    final overallExpected = report.totalPresent + report.totalAbsent;
    final overallRate = overallExpected > 0
        ? ((report.totalPresent / overallExpected) * 100).round()
        : 0;

    final q = query.toLowerCase();
    final rows = q.isEmpty
        ? report.rows
        : report.rows
            .where((r) =>
                r.fullName.toLowerCase().contains(q) ||
                r.playerCode.toLowerCase().contains(q))
            .toList();

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
        if (rows.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Center(
              child: Text(q.isEmpty ? 'لا توجد بيانات' : 'لا يوجد لاعب مطابق',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.grey500)),
            ),
          )
        else
          ...rows.map((r) => _RowTile(row: r)),
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

  static String _fmt(String? ymd) {
    if (ymd == null || ymd.length < 10) return '—';
    return '${ymd.substring(8, 10)}/${ymd.substring(5, 7)}/${ymd.substring(0, 4)}';
  }

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
          // دائرة النسبة (أو "منتهي")
          if (!row.isActive)
            Container(
              width: 48.w,
              height: 48.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.block, color: AppColors.error, size: 20.sp),
            )
          else
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
                if (row.isActive) ...[
                  Gap(2.h),
                  Text(
                    'الاشتراك: ${_fmt(row.subscriptionStart)} ← ${_fmt(row.subscriptionEnd)}',
                    style: TextStyle(fontSize: 10.sp, color: AppColors.grey500),
                  ),
                  if (row.expectedTotal > 0) ...[
                    Gap(6.h),
                    _AttendanceDots(
                      expected: row.expectedTotal,
                      present: row.present,
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (!row.isActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'منتهي',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
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

// دوائر صغيرة تمثّل أيام التدريب المتوقعة على كامل فترة الاشتراك النشط — كل حضور يلوّن دائرة.
class _AttendanceDots extends StatelessWidget {
  final int expected;
  final int present;
  const _AttendanceDots({required this.expected, required this.present});

  @override
  Widget build(BuildContext context) {
    final filled = present > expected ? expected : present;
    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      children: List.generate(expected, (i) {
        final isFilled = i < filled;
        return Container(
          width: 9.w,
          height: 9.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF2D9748) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xFF2D9748) : AppColors.grey300,
              width: 1.2,
            ),
          ),
        );
      }),
    );
  }
}
