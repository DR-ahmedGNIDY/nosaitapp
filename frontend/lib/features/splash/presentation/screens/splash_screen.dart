import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _navigate();
  }

  void _navigate() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final auth = ref.read(authStateProvider).valueOrNull;
      if (auth?.isAuthenticated == true) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sports_basketball,
                      size: 62.sp,
                      color: AppColors.white,
                    ),
                  ),
                  Gap(24.h),
                  Text(
                    'أكاديمية كرة السلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  Gap(6.h),
                  Text(
                    'نظام الإدارة الاحترافي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      color: AppColors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  Gap(56.h),
                  SizedBox(
                    width: 28.w,
                    height: 28.w,
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
