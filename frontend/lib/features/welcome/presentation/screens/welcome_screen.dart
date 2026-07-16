import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// شاشة الترحيب الرئيسية لمنصة Nosait. مساران:
/// 1) مدير أكاديمية: تسجيل دخول / إنشاء أكاديمية جديدة.
/// 2) لاعب / ولي أمر: تسجيل دخول.
/// تعمل بنفس الكود على Android / Windows / Flutter Web.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, AppColors.secondaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 460.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96.w,
                      height: 96.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(Icons.sports_basketball,
                          size: 52.sp, color: AppColors.white),
                    ),
                    Gap(20.h),
                    Text(
                      'Nosait',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Gap(6.h),
                    Text(
                      'مرحباً بك',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Gap(40.h),

                    // ── بطاقة مدير الأكاديمية ──
                    _RoleCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'دخول مدير أكاديمية',
                      children: [
                        _PrimaryButton(
                          label: 'تسجيل الدخول',
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                        Gap(10.h),
                        _SecondaryButton(
                          label: 'إنشاء أكاديمية جديدة',
                          icon: Icons.add_business_outlined,
                          onPressed: () => context.go(AppRoutes.registerAcademy),
                        ),
                      ],
                    ),
                    Gap(18.h),

                    // ── بطاقة اللاعب / ولي الأمر ──
                    _RoleCard(
                      icon: Icons.person_outline,
                      title: 'دخول اللاعب / ولي الأمر',
                      children: [
                        _PrimaryButton(
                          label: 'تسجيل الدخول',
                          onPressed: () => context.go(AppRoutes.playerLogin),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _RoleCard({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 26.sp),
              Gap(10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          ...children,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _SecondaryButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary),
        label: Text(label,
            style: TextStyle(
                fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
    );
  }
}
