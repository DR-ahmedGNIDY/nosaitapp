import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:basketball_academy/features/player_portal/presentation/widgets/player_photo_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// لوحة اللاعب — جدول التدريب، الحضور، الاشتراك والأيام المتبقية، التقييمات،
/// مع وصول سريع للمحادثة والإشعارات.
class PlayerDashboardScreen extends ConsumerWidget {
  const PlayerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(playerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة اللاعب'),
        actions: [
          IconButton(
            tooltip: 'الإشعارات',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.playerNotifications),
          ),
          IconButton(
            tooltip: 'المحادثة',
            icon: const Icon(Icons.chat_outlined),
            onPressed: () => context.push(AppRoutes.playerChat),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(playerSessionProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.welcome);
            },
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              Gap(12.h),
              const Text('تعذّر تحميل البيانات'),
              Gap(12.h),
              ElevatedButton(
                onPressed: () => ref.invalidate(playerDashboardProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(playerDashboardProvider),
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              _header(context, ref, data['player'] as Map<String, dynamic>?),
              Gap(16.h),
              _subscriptionCard(data['subscription'] as Map<String, dynamic>?),
              Gap(16.h),
              _scheduleCard(data['schedule'] as Map<String, dynamic>?),
              Gap(16.h),
              _attendanceCard(data['attendance'] as Map<String, dynamic>?),
              Gap(16.h),
              _evaluationCard(data['latestEvaluation'] as Map<String, dynamic>?),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, Map<String, dynamic>? p) {
    final name = p?['fullName'] as String? ?? '';
    final code = p?['playerCode'] as String? ?? '';
    final imageUrl = p?['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => showPlayerPhotoSheet(context, ref, hasImage: hasImage),
            customBorder: const CircleBorder(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: AppColors.white,
                  backgroundImage:
                      hasImage ? CachedNetworkImageProvider(imageUrl) : null,
                  child: hasImage
                      ? null
                      : Icon(Icons.person, color: AppColors.secondary, size: 30.sp),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit,
                        size: 11.sp, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800)),
                Gap(4.h),
                Text(code,
                    style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8), fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22.sp),
              Gap(8.w),
              Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          Gap(12.h),
          child,
        ],
      ),
    );
  }

  Widget _subscriptionCard(Map<String, dynamic>? sub) {
    if (sub == null) {
      return _card(
        title: 'الاشتراك الحالي',
        icon: Icons.card_membership_outlined,
        child: const Text('لا يوجد اشتراك مسجّل'),
      );
    }
    final days = (sub['daysRemaining'] as num?)?.toInt() ?? 0;
    final active = sub['isActive'] == true;
    return _card(
      title: 'الاشتراك الحالي',
      icon: Icons.card_membership_outlined,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: active ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text('$days',
                    style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: active ? AppColors.success : AppColors.error)),
                Text('يوم متبقٍ', style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
          Gap(14.w),
          Text(active ? 'الاشتراك ساري' : 'الاشتراك منتهٍ',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.success : AppColors.error)),
        ],
      ),
    );
  }

  Widget _scheduleCard(Map<String, dynamic>? schedule) {
    final days = (schedule?['attendanceDays'] as List<dynamic>?)?.cast<String>() ?? [];
    return _card(
      title: 'جدول التدريب',
      icon: Icons.calendar_month_outlined,
      child: days.isEmpty
          ? const Text('لم يتم تحديد أيام تدريب')
          : Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: days
                  .map((d) => Chip(
                        label: Text(d),
                        backgroundColor: AppColors.primaryContainer,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _attendanceCard(Map<String, dynamic>? att) {
    final count = (att?['presentCount'] as num?)?.toInt() ?? 0;
    return _card(
      title: 'الحضور',
      icon: Icons.how_to_reg_outlined,
      child: Text('إجمالي مرات الحضور المسجّلة: $count',
          style: TextStyle(fontSize: 14.sp)),
    );
  }

  Widget _evaluationCard(Map<String, dynamic>? ev) {
    return _card(
      title: 'آخر تقييم',
      icon: Icons.star_outline,
      child: ev == null
          ? const Text('لا يوجد تقييم بعد')
          : Text('المتوسط: ${ev['average']} / 10',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
    );
  }
}
