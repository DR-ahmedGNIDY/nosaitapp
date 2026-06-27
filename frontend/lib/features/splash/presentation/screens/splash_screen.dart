import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('[SPLASH] initState() → SplashScreen built, starting navigation timer');
    _navigate();
  }

  void _navigate() {
    debugPrint('[SPLASH] _navigate() → waiting 2 seconds...');
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final authAsync = ref.read(authStateProvider);
      debugPrint('[SPLASH] _navigate() → authAsync: isLoading=${authAsync.isLoading} isAuthenticated=${authAsync.valueOrNull?.isAuthenticated}');
      final auth = authAsync.valueOrNull;
      if (auth?.isAuthenticated == true) {
        final user = auth?.user;
        if (user?.isAdmin == true && user?.academyId != null) {
          debugPrint('[SPLASH] → admin detected, going to playersList academyId=${user?.academyId}');
          context.go(AppRoutes.playersList.replaceFirst(':id', user!.academyId!));
        } else {
          debugPrint('[SPLASH] → regular user, going to home');
          context.go(AppRoutes.home);
        }
      } else {
        debugPrint('[SPLASH] → not authenticated, going to login');
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
        color: AppColors.primary,
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_basketball,
                        size: 80.sp,
                        color: AppColors.white,
                      ),
                      Gap(20.h),
                      Text(
                        'Basketball Academy Manager',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Gap(8.h),
                      Text(
                        'نظام إدارة الأكاديمية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: AppColors.white.withValues(alpha: 0.70),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    color: AppColors.white.withValues(alpha: 0.50),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
