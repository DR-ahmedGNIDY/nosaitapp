import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class AcademyDetailScreen extends ConsumerWidget {
  final String academyId;

  const AcademyDetailScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.academy),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_basketball,
                size: 72.sp,
                color: AppColors.primary,
              ),
              Gap(16.h),
              Text(
                'تفاصيل الأكاديمية',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gap(8.h),
              Text(
                'ID: $academyId',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey400,
                  fontFamily: 'monospace',
                ),
              ),
              Gap(8.h),
              Text(
                'سيتم تطوير هذه الشاشة في Phase 2',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
