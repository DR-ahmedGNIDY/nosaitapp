import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_entity.dart';
import 'package:basketball_academy/features/staff/presentation/providers/staff_provider.dart';
import 'package:basketball_academy/features/staff/presentation/screens/add_edit_staff_screen.dart';
import 'package:basketball_academy/features/staff/presentation/screens/staff_attendance_screen.dart';
import 'package:basketball_academy/features/staff/presentation/screens/staff_attendance_report_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  final String academyId;
  const StaffListScreen({super.key, required this.academyId});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffProvider.notifier).load();
    });
  }

  Future<void> _confirmDelete(StaffEntity staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الموظف'),
        content: Text('هل تريد حذف الموظف "${staff.fullName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      final error = await ref.read(staffProvider.notifier).deleteStaff(staff.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'تم حذف الموظف بنجاح'),
          backgroundColor: error != null ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإدارة والموظفين'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'تقرير الحضور',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StaffAttendanceReportScreen(academyId: widget.academyId)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddEditStaffScreen(academyId: widget.academyId)),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حدث خطأ: $err')),
        data: (state) {
          if (state.staff.isEmpty) {
            return const Center(child: Text('لا يوجد موظفون حتى الآن'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(staffProvider.notifier).refresh(),
            child: ListView.separated(
              padding: EdgeInsets.all(12.r),
              itemCount: state.staff.length,
              separatorBuilder: (_, __) => Gap(8.h),
              itemBuilder: (_, i) {
                final s = state.staff[i];
                return _StaffCard(
                  staff: s,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddEditStaffScreen(academyId: widget.academyId, staff: s)),
                  ),
                  onAttendance: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StaffAttendanceScreen(staff: s)),
                  ),
                  onDelete: () => _confirmDelete(s),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffEntity staff;
  final VoidCallback onTap;
  final VoidCallback onAttendance;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onTap,
    required this.onAttendance,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: AppColors.primaryContainer,
          backgroundImage: staff.photoUrl != null ? CachedNetworkImageProvider(staff.photoUrl!) : null,
          child: staff.photoUrl == null ? Icon(Icons.person, color: AppColors.primary, size: 24.r) : null,
        ),
        title: Text(staff.fullName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
        subtitle: Text('${staff.position} • ${staff.phone}', style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.event_available_outlined, color: AppColors.primary, size: 20.r),
              tooltip: 'الحضور',
              onPressed: onAttendance,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20.r),
              tooltip: 'حذف',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
