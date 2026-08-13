import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// شاشة دخول اللاعب / ولي الأمر (username = nosait00001).
class PlayerLoginScreen extends ConsumerStatefulWidget {
  const PlayerLoginScreen({super.key});

  @override
  ConsumerState<PlayerLoginScreen> createState() => _PlayerLoginScreenState();
}

class _PlayerLoginScreenState extends ConsumerState<PlayerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _submitted = true);
      ref.read(playerSessionProvider.notifier).login(
            username: _username.text.trim(),
            password: _password.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(playerSessionProvider, (_, next) {
      final st = next.valueOrNull;
      if (st?.isAuthenticated == true) {
        context.go(AppRoutes.playerDashboard);
      } else if (!next.isLoading) {
        if (_submitted) setState(() => _submitted = false);
        if (st?.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(st!.errorMessage!), backgroundColor: AppColors.error),
          );
          ref.read(playerSessionProvider.notifier).clearError();
        }
      }
    });

    final isLoading = _submitted && ref.watch(playerSessionProvider).isLoading;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440.w),
                child: Column(
                  children: [
                    IconButton(
                      alignment: Alignment.centerRight,
                      onPressed: () => context.go(AppRoutes.welcome),
                      icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    ),
                    Gap(10.h),
                    Icon(Icons.person, size: 64.sp, color: AppColors.white),
                    Gap(10.h),
                    Text('دخول اللاعب',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.white, fontWeight: FontWeight.w800)),
                    Gap(28.h),
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _username,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'اسم المستخدم',
                                hintText: 'nosait00001',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                            ),
                            Gap(14.h),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              onFieldSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'مطلوب' : null,
                            ),
                            Gap(22.h),
                            ConstrainedBox(
                              constraints: BoxConstraints(minHeight: 50.h),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                child: isLoading
                                    ? SizedBox(
                                        height: 20.h,
                                        width: 20.h,
                                        child: const CircularProgressIndicator(
                                            strokeWidth: 2.5, color: AppColors.white),
                                      )
                                    : Text('تسجيل الدخول',
                                        style: TextStyle(
                                            fontSize: 16.sp, fontWeight: FontWeight.w700)),
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
