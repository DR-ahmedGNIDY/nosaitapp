import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_session_provider.dart';
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

  // بدل انتظار ثابت 2 ثانية: ننتقل فور جاهزية فحص الجلسة (المدير واللاعب)،
  // مع حد أدنى قصير لإكمال أنيميشن الشعار وحد أقصى لو تأخّر الفحص.
  Future<void> _navigate() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 800));
    try {
      await Future.wait([
        ref.read(authStateProvider.future),
        ref.read(playerSessionProvider.future),
      ]).timeout(const Duration(seconds: 5));
    } catch (_) {
      // فشل/تأخّر الفحص ⇒ نكمل بالحالة المتاحة (غير مسجّل → شاشة الترحيب).
    }
    await minDelay;
    if (!mounted) return;
    // جلسة اللاعب لها الأولوية إن كانت فعّالة.
    final player = ref.read(playerSessionProvider).valueOrNull;
    if (player?.isAuthenticated == true) {
      context.go(AppRoutes.playerDashboard);
      return;
    }

    final authAsync = ref.read(authStateProvider);
    debugPrint('[SPLASH] _navigate() → authAsync: isLoading=${authAsync.isLoading} isAuthenticated=${authAsync.valueOrNull?.isAuthenticated}');
    final auth = authAsync.valueOrNull;
    if (auth?.isAuthenticated == true) {
      final user = auth?.user;
      if (user?.isAdmin == true &&
          user?.academyId != null &&
          !user!.hasPermission('view_dashboard_revenue')) {
        context.go(AppRoutes.playersList.replaceFirst(':id', user.academyId!));
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      // غير مسجّل → شاشة الترحيب (Nosait).
      context.go(AppRoutes.welcome);
    }
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
                      Image.asset(
                        'assets/images/logo1.jpg',
                        width: 180.w,
                        height: 180.w,
                        fit: BoxFit.contain,
                      ),
                      Gap(16.h),
                      Text(
                        'نظام إدارة الأكاديميات الرياضية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.white,
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
                  'v1.1.3',
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
