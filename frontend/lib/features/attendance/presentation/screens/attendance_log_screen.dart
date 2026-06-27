import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class AttendanceLogScreen extends ConsumerStatefulWidget {
  final String academyId;
  const AttendanceLogScreen({super.key, required this.academyId});

  @override
  ConsumerState<AttendanceLogScreen> createState() =>
      _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends ConsumerState<AttendanceLogScreen> {
  String? _date; // 'YYYY-MM-DD' أو null = كل التواريخ
  String? _sport; // null = الكل
  String _playerQuery = ''; // فلترة محلية بالاسم/الكود (بدون طلب إضافي)

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() =>
          _date = '${picked.year}-${_two(picked.month)}-${_two(picked.day)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];

    final filter = AttendanceLogFilter(
      academyId: widget.academyId,
      date: _date,
      sport: _sport,
    );
    final logAsync = ref.watch(attendanceLogProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سجل الحضور'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // فلتر التاريخ + بحث اللاعب
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(_date ?? 'كل التواريخ'),
                  ),
                ),
                if (_date != null) ...[
                  Gap(8.w),
                  IconButton(
                    tooltip: 'مسح التاريخ',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _date = null),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: TextField(
              onChanged: (v) => setState(() => _playerQuery = v.trim()),
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
          // فلتر الرياضة (للأكاديميات متعددة الرياضات)
          if (isMultiSport)
            _SportChips(
              sports: sports,
              selected: _sport,
              onSelected: (s) => setState(() => _sport = s),
            ),
          Expanded(
            child: logAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                onRetry: () => ref.invalidate(attendanceLogProvider(filter)),
              ),
              data: (data) {
                var records = data.records;
                if (_playerQuery.isNotEmpty) {
                  final q = _playerQuery.toLowerCase();
                  records = records
                      .where((r) =>
                          r.playerName.toLowerCase().contains(q) ||
                          r.playerCode.toLowerCase().contains(q))
                      .toList();
                }
                if (records.isEmpty) {
                  return _EmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(attendanceLogProvider(filter)),
                  child: ListView.separated(
                    padding: EdgeInsets.all(16.r),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => Gap(10.h),
                    itemBuilder: (_, i) => _LogTile(entry: records[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SportChips extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SportChips({
    required this.sports,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...sports];
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        itemCount: options.length,
        separatorBuilder: (_, __) => Gap(8.w),
        itemBuilder: (_, i) {
          final value = options[i];
          final isSel = value == selected;
          return ChoiceChip(
            label: Text(value ?? 'الكل'),
            selected: isSel,
            onSelected: (_) => onSelected(value),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSel ? AppColors.white : AppColors.grey700,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
            backgroundColor: AppColors.white,
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AttendanceLogEntry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
            ),
            child: ClipOval(
              child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: entry.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(Icons.person,
                          color: AppColors.primary, size: 22.sp),
                    )
                  : Icon(Icons.person, color: AppColors.primary, size: 22.sp),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName.isNotEmpty
                      ? entry.playerName
                      : entry.playerCode,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                Gap(2.h),
                Text(
                  [
                    entry.playerCode,
                    if (entry.sport != null && entry.sport!.isNotEmpty)
                      entry.sport!,
                  ].join(' • '),
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtDate(entry.date),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              Gap(2.h),
              Text(
                entry.time,
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(String ymd) {
    try {
      final d = DateTime.parse(ymd);
      return DateFormat('dd/MM/yyyy', 'ar').format(d);
    } catch (_) {
      return ymd;
    }
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 64.sp, color: AppColors.grey300),
          Gap(12.h),
          Text(
            'لا توجد سجلات حضور',
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56.sp, color: AppColors.error),
          Gap(12.h),
          Text('تعذّر تحميل السجل',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey700)),
          Gap(12.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
