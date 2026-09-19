import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// ملخص حضور/غياب اللاعب في اشتراكه الأخير.
/// نشط → منذ بداية الاشتراك. منتهي → شارة "منتهي" + أرقام الاشتراك السابق.
class SubscriptionStatsBanner extends StatelessWidget {
  final AttendanceSubscriptionStats stats;
  final bool compact;

  const SubscriptionStatsBanner({
    super.key,
    required this.stats,
    this.compact = false,
  });

  static String fmtDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '—';
    try {
      return DateFormat('dd/MM/yyyy', 'ar').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!stats.hasSubscription) {
      return _frame(
        color: AppColors.error,
        child: Row(
          children: [
            _badge('منتهي', AppColors.error),
            Gap(8.w),
            Expanded(
              child: Text('لا يوجد اشتراك مسجّل لهذا اللاعب',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
            ),
          ],
        ),
      );
    }

    final active = stats.isActive;
    final color = active ? const Color(0xFF2D9748) : AppColors.error;
    final title = active ? 'منذ بداية الاشتراك الحالي' : 'في الاشتراك السابق';

    return _frame(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!active) ...[
                _badge('منتهي', AppColors.error),
                Gap(8.w),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
              ),
            ],
          ),
          Gap(2.h),
          Text(
            '${fmtDate(stats.startDate)} ← ${fmtDate(stats.endDate)}',
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
          ),
          Gap(compact ? 6.h : 10.h),
          Row(
            children: [
              _stat('حضور', stats.present, const Color(0xFF2D9748)),
              Gap(8.w),
              _stat('غياب', stats.absent, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _frame({required Color color, required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 10.r : 14.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: child,
      );

  Widget _badge(String text, Color color) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _stat(String label, int value, Color color) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 6.h : 8.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: compact ? 16.sp : 20.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(label,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
            ],
          ),
        ),
      );
}
