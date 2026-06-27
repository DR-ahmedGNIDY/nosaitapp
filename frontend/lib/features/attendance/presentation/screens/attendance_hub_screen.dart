import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/attendance/presentation/screens/attendance_log_screen.dart';
import 'package:basketball_academy/features/attendance/presentation/screens/attendance_report_screen.dart';
import 'package:basketball_academy/features/attendance/presentation/screens/attendance_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class AttendanceHubScreen extends StatelessWidget {
  final String academyId;
  const AttendanceHubScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الحضور والانصراف'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            _HubTile(
              icon: Icons.qr_code_scanner,
              color: AppColors.primary,
              title: 'مسح QR',
              subtitle: 'تسجيل حضور لاعب عبر مسح بطاقته',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceScanScreen(academyId: academyId),
                ),
              ),
            ),
            Gap(14.h),
            _HubTile(
              icon: Icons.list_alt_outlined,
              color: AppColors.secondary,
              title: 'سجل الحضور',
              subtitle: 'عرض سجل الحضور مع الفلاتر',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceLogScreen(academyId: academyId),
                ),
              ),
            ),
            Gap(14.h),
            _HubTile(
              icon: Icons.assessment_outlined,
              color: const Color(0xFF2D9748),
              title: 'تقرير الحضور والغياب',
              subtitle: 'إحصائيات الالتزام و PDF',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceReportScreen(academyId: academyId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: color, size: 26.sp),
            ),
            Gap(14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: AppColors.grey300, size: 22.sp),
          ],
        ),
      ),
    );
  }
}
