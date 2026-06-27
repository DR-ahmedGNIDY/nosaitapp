import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_entity.dart';
import 'package:basketball_academy/features/staff/presentation/providers/staff_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  final StaffEntity staff;
  const StaffAttendanceScreen({super.key, required this.staff});

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    ref.read(staffAttendanceProvider.notifier).loadHistory(
          staffId: widget.staff.id,
          startDate: DateFormat('yyyy-MM-dd').format(start),
          endDate: DateFormat('yyyy-MM-dd').format(now),
        );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _mark(String status) async {
    setState(() => _isSubmitting = true);
    final error = await ref.read(staffAttendanceProvider.notifier).markAttendance(
          staffId: widget.staff.id,
          date: _dateStr,
          status: status,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم تسجيل ${status == 'present' ? 'الحضور' : 'الغياب'} بنجاح'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (error == null) _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(staffAttendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('حضور: ${widget.staff.fullName}'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy', 'ar').format(_selectedDate), style: TextStyle(fontSize: 14.sp)),
                        Icon(Icons.calendar_today_outlined, color: AppColors.grey400, size: 18.r),
                      ],
                    ),
                  ),
                ),
                Gap(16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _mark('present'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        icon: const Icon(Icons.check),
                        label: const Text('حضور'),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _mark('absent'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        icon: const Icon(Icons.close),
                        label: const Text('غياب'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حدث خطأ: $err')),
              data: (records) {
                if (records.isEmpty) return const Center(child: Text('لا يوجد سجل حضور هذا الشهر'));
                return ListView.separated(
                  padding: EdgeInsets.all(12.r),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => Gap(6.h),
                  itemBuilder: (_, i) {
                    final r = records[i];
                    final isPresent = r.status == 'present';
                    return ListTile(
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      leading: Icon(
                        isPresent ? Icons.check_circle : Icons.cancel,
                        color: isPresent ? AppColors.success : AppColors.error,
                      ),
                      title: Text(r.date),
                      trailing: Text(isPresent ? 'حضور' : 'غياب', style: TextStyle(color: isPresent ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
