import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(authStateProvider, (_, next) {
      final st = next.valueOrNull;
      if (st?.isAuthenticated == true) {
        context.go(AppRoutes.home);
      } else if (st?.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(st!.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authStateProvider.notifier).clearError();
      }
    });

    final isLoading = ref.watch(authStateProvider).isLoading;

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                child: Column(
                  children: [
                    Gap(40.h),
                    // Logo
                    Container(
                      width: 96.w,
                      height: 96.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_basketball,
                        size: 52.sp,
                        color: AppColors.white,
                      ),
                    ),
                    Gap(20.h),
                    Text(
                      AppStrings.appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(6.h),
                    Text(
                      'نظام الإدارة الاحترافي',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Gap(48.h),
                    // Card
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.welcomeBack,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Gap(4.h),
                            Text(
                              AppStrings.loginSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.grey500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Gap(28.h),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: AppStrings.email,
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'example@academy.com',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.required;
                                if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) {
                                  return AppStrings.invalidEmail;
                                }
                                return null;
                              },
                            ),
                            Gap(14.h),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: AppStrings.password,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.required;
                                if (v.length < 8) return AppStrings.passwordTooShort;
                                return null;
                              },
                            ),
                            Gap(28.h),
                            SizedBox(
                              height: 50.h,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                child: isLoading
                                    ? SizedBox(
                                        height: 20.h,
                                        width: 20.h,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(
                                        AppStrings.loginButton,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
