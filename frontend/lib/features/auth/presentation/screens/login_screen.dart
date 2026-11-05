import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_constants.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/core/utils/privacy_launcher.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/network/token_manager.dart';
import 'package:basketball_academy/features/auth/data/saved_accounts_store.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _rememberMe = false;
  bool _hasSubmitted = false;
  static const _kRememberKey = 'remember_me';
  static const _kSavedEmailKey = 'saved_email';
  // الحسابات المحفوظة للدخول السريع (كروت أعلى النموذج).
  List<SavedAccount> _savedAccounts = [];
  String? _quickLoginId; // الحساب الجاري الدخول به الآن
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
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _loadSavedCredentials();
    _loadSavedAccounts();
  }

  SavedAccountsStore get _accountsStore =>
      SavedAccountsStore(sl<FlutterSecureStorage>());

  Future<void> _loadSavedAccounts() async {
    final list = await _accountsStore.list();
    if (mounted) setState(() => _savedAccounts = list);
  }

  /// بعد دخول ناجح من النموذج: نحفظ الحساب (مع توكن الجلسة) لو "حفظ تسجيل الدخول"
  /// مفعّل، أو نحذفه من الكروت لو أُلغي التفعيل.
  Future<void> _persistAccount(UserEntity user) async {
    try {
      if (!_rememberMe) {
        await _accountsStore.removeByEmail(user.email);
        return;
      }
      final token = await sl<TokenManager>().getToken();
      if (token == null || token.isEmpty) return;
      final refreshToken = await sl<TokenManager>().getRefreshToken();
      await _accountsStore.upsert(SavedAccount(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role.name,
        academyName: user.academyName,
        token: token,
        refreshToken: refreshToken,
        savedAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('[LOGIN] save account failed: $e');
    }
  }

  Future<void> _quickLogin(SavedAccount a) async {
    if (_quickLoginId != null) return;
    setState(() => _quickLoginId = a.id);
    final error = await ref
        .read(authStateProvider.notifier)
        .loginWithSavedToken(a.token, refreshToken: a.refreshToken);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _quickLoginId = null;
        _emailController.text = a.email;
        _passwordController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
    if (error == null) {
      // لو جُدّدت الجلسة أثناء الدخول نحفظ التوكنات الجديدة في الكارت.
      final tm = sl<TokenManager>();
      final token = await tm.getToken();
      if (token != null && token.isNotEmpty) {
        await _accountsStore.upsert(SavedAccount(
          id: a.id,
          name: a.name,
          email: a.email,
          role: a.role,
          academyName: a.academyName,
          token: token,
          refreshToken: await tm.getRefreshToken() ?? a.refreshToken,
          savedAt: DateTime.now(),
        ));
      }
    }
    // النجاح: ref.listen أدناه ينقل المستخدم للصفحة الرئيسية.
  }

  Future<void> _removeSavedAccount(SavedAccount a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة الحساب المحفوظ'),
        content: Text(
            'إزالة "${a.name.isNotEmpty ? a.name : a.email}" من الحسابات المحفوظة على هذا الجهاز؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _accountsStore.remove(a.id);
    await _loadSavedAccounts();
  }

  static String _roleLabel(String role) => switch (role) {
        'superAdmin' => 'مدير النظام',
        'academyAdmin' => 'مدير الأكاديمية',
        'admin' => 'موظف',
        _ => '',
      };

  Widget _savedAccountsSection() {
    if (_savedAccounts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'الحسابات المحفوظة',
          style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.grey700),
        ),
        Gap(8.h),
        for (final a in _savedAccounts) ...[
          _SavedAccountCard(
            account: a,
            subtitle: [
              if (a.academyName != null && a.academyName!.isNotEmpty)
                a.academyName!,
              if (_roleLabel(a.role).isNotEmpty) _roleLabel(a.role),
            ].join(' • '),
            loading: _quickLoginId == a.id,
            enabled: _quickLoginId == null,
            onTap: () => _quickLogin(a),
            onRemove: () => _removeSavedAccount(a),
          ),
          Gap(8.h),
        ],
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text('أو سجّل الدخول بحساب آخر',
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
          ),
          const Expanded(child: Divider()),
        ]),
        Gap(12.h),
      ],
    );
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberKey) ?? false;
    if (remember) {
      final savedEmail = prefs.getString(_kSavedEmailKey) ?? '';
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberKey, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_kSavedEmailKey, _emailController.text.trim());
    } else {
      await prefs.remove(_kSavedEmailKey);
    }
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
      setState(() => _hasSubmitted = true);
      _saveCredentials();
      ref.read(authStateProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  /// Opens WhatsApp to the company number for account creation / inquiry.
  /// This is a contact channel only — it does NOT create an account in-app.
  Future<void> _contactCompany() async {
    final ok = await WhatsAppUtils.open(
      AppConstants.companyWhatsappNumber,
      message: AppConstants.contactDefaultMessage,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح واتساب'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openPrivacyPolicy() => openPrivacyPolicy(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(authStateProvider, (_, next) {
      final st = next.valueOrNull;
      debugPrint(
          '[LOGIN] authState changed: isLoading=${next.isLoading} isAuthenticated=${st?.isAuthenticated} error=${st?.errorMessage}');
      if (st?.isAuthenticated == true) {
        debugPrint('[LOGIN] NAVIGATION START → going to home/players');
        final user = st?.user;
        // دخول من النموذج (وليس من كارت محفوظ): نحدّث الحسابات المحفوظة.
        if (_hasSubmitted && user != null) _persistAccount(user);
        if (user?.isAdmin == true &&
            user?.academyId != null &&
            !user!.hasPermission('view_dashboard_revenue')) {
          context
              .go(AppRoutes.playersList.replaceFirst(':id', user.academyId!));
        } else {
          context.go(AppRoutes.home);
        }
        debugPrint('[LOGIN] NAVIGATION COMPLETE');
      } else if (!next.isLoading) {
        if (_hasSubmitted) setState(() => _hasSubmitted = false);
        if (st?.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(st!.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(authStateProvider.notifier).clearError();
        }
      }
    });

    final authAsync = ref.watch(authStateProvider);
    // يظهر loading فقط لو المستخدم ضغط الزر بالفعل + الـ provider شغال فعلاً
    final isLoading = _hasSubmitted && authAsync.isLoading;

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
                    // زر الرجوع لواجهة البرنامج (شاشة الترحيب)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => context.go(AppRoutes.welcome),
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.white),
                        label: Text(
                          'رجوع',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    Gap(8.h),
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
                            _savedAccountsSection(),
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
                                if (v == null || v.isEmpty) {
                                  return AppStrings.required;
                                }
                                if (!RegExp(
                                        r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                                    .hasMatch(v)) {
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
                                if (v == null || v.isEmpty) {
                                  return AppStrings.required;
                                }
                                if (v.length < 8) {
                                  return AppStrings.passwordTooShort;
                                }
                                return null;
                              },
                            ),
                            Gap(16.h),
                            // Remember me checkbox
                            Row(
                              children: [
                                SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false),
                                  ),
                                ),
                                Gap(8.w),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _rememberMe = !_rememberMe),
                                  child: Text(
                                    'حفظ تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.grey700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Gap(20.h),
                            ConstrainedBox(
                              constraints: BoxConstraints(minHeight: 50.h),
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
                    Gap(20.h),
                    // إنشاء حساب أكاديمية — يفتح شاشة تسجيل أكاديمية جديدة
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 50.h),
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.registerAcademy),
                        icon: const Icon(Icons.add_business_outlined),
                        label: Text(
                          'إنشاء حساب أكاديمية',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                    Gap(12.h),
                    // تواصل مع الدعم — يفتح واتساب الشركة
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 50.h),
                      child: OutlinedButton.icon(
                        onPressed: _contactCompany,
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.white),
                        label: Text(
                          'تواصل مع الدعم',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.white.withValues(alpha: 0.7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                    Gap(12.h),
                    // Privacy policy link
                    TextButton(
                      onPressed: _openPrivacyPolicy,
                      child: Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.white.withValues(alpha: 0.85),
                          decoration: TextDecoration.underline,
                          decorationColor:
                              AppColors.white.withValues(alpha: 0.85),
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

/// كارت حساب محفوظ: الضغط يدخل مباشرة، و× يزيل الحساب من هذا الجهاز.
class _SavedAccountCard extends StatelessWidget {
  final SavedAccount account;
  final String subtitle;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedAccountCard({
    required this.account,
    required this.subtitle,
    required this.loading,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: AppColors.grey200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.primary,
              child: Text(
                account.initial,
                style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp),
              ),
            ),
            Gap(10.w),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name.isNotEmpty ? account.name : account.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle.isNotEmpty ? subtitle : account.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                    ),
                  ]),
            ),
            if (loading)
              Padding(
                padding: EdgeInsets.all(8.r),
                child: SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              Icon(Icons.login_rounded, color: AppColors.primary, size: 20.r),
              IconButton(
                tooltip: 'إزالة',
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onRemove : null,
                icon: Icon(Icons.close, size: 18.r, color: AppColors.grey500),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
