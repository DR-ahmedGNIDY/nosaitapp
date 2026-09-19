import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// علامة مميزة لنوع الحضور غير العادي (دفع لاحقاً / تعويض غياب / حصة مجانية).
/// لا تعرض شيئاً للحضور العادي.
class AttendanceKindBadge extends StatelessWidget {
  final String kind;
  const AttendanceKindBadge({super.key, required this.kind});

  static Color colorOf(String kind) {
    switch (kind) {
      case AttendanceKind.payLater:
        return AppColors.warning;
      case AttendanceKind.makeup:
        return AppColors.secondary;
      case AttendanceKind.free:
        return const Color(0xFF2D9748);
      default:
        return AppColors.grey500;
    }
  }

  static IconData iconOf(String kind) {
    switch (kind) {
      case AttendanceKind.payLater:
        return Icons.schedule;
      case AttendanceKind.makeup:
        return Icons.event_repeat;
      case AttendanceKind.free:
        return Icons.card_giftcard;
      default:
        return Icons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = AttendanceKind.label(kind);
    if (label == null) return const SizedBox.shrink();
    final color = colorOf(kind);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconOf(kind), size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
