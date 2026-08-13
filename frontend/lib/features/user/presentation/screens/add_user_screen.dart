import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/user/presentation/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

// المفاتيح المتاحة لصلاحيات حساب "مشرف" (role='admin') — مطابقة لقائمة
// ADMIN_PERMISSIONS في الباك إند (backend/src/constants/permissions.js).
const _kPermissionOptions = <String, String>{
  'register_players': 'تسجيل لاعبين',
  'record_subscriptions': 'تسجيل اشتراكات',
  'record_evaluations': 'تسجيل تقييمات',
  'add_matches': 'إضافة مباريات',
  'use_album': 'استخدام الألبوم',
  'use_store': 'استخدام المتجر',
  'view_reports': 'رؤية التقارير',
  'view_dashboard_revenue': 'رؤية الداشبورد والإحصائيات والإيرادات',
};

// ─── بطاقة اختيار الدور — بديل موثوق عن SegmentedButton ───────────────────
class _RoleCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final String selectedValue;
  final void Function(String) onTap;

  const _RoleCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.grey500,
              size: 24.sp,
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.grey700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AddUserScreen extends ConsumerStatefulWidget {
  final String academyId;

  const AddUserScreen({super.key, required this.academyId});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'academy_admin';
  final Set<String> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    // مدير الأكاديمية يقدر يُنشئ حسابات "مشرف" (admin) فقط — أبداً حساب
    // مدير أكاديمية آخر مكافئ له في الصلاحيات.
    final callerIsAcademyAdmin =
        ref.read(authStateProvider).valueOrNull?.user?.isAcademyAdmin ?? false;
    if (callerIsAcademyAdmin) {
      _selectedRole = 'admin';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ── تأكيد نهائي من القيمة قبل الإرسال ──
    final roleToSend = _selectedRole;
    assert(() {
      // ignore: avoid_print
      print('[AddUserScreen] _submit called — roleToSend="$roleToSend"');
      return true;
    }());

    setState(() => _isLoading = true);

    final error = await ref.read(usersProvider.notifier).createUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          academyId: widget.academyId,
          role: roleToSend,
          permissions:
              roleToSend == 'admin' ? _selectedPermissions.toList() : null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المستخدم بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callerIsAcademyAdmin =
        ref.watch(authStateProvider).valueOrNull?.user?.isAcademyAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مستخدم'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header icon
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      color: AppColors.primary,
                      size: 40.sp,
                    ),
                  ),
                ),
                Gap(28.h),

                // Name field
                Text(
                  'الاسم الكامل',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _nameController,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'أدخل الاسم الكامل',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Email field
                Text(
                  'البريد الإلكتروني',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'أدخل البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Password field
                Text(
                  'كلمة المرور',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _passwordController,
                  validator: _validatePassword,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'أدخل كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.grey500,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Role selector — بطاقات مخصصة بدلاً من SegmentedButton.
                // مدير الأكاديمية يُنشئ حسابات "مشرف" فقط — الاختيار مخفي وثابت.
                if (!callerIsAcademyAdmin) ...[
                  Text(
                    'الدور الوظيفي',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(8.h),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          value: 'academy_admin',
                          label: 'مدير أكاديمية',
                          icon: Icons.admin_panel_settings_outlined,
                          selectedValue: _selectedRole,
                          onTap: (v) => setState(() {
                            _selectedRole = v;
                            // ignore: avoid_print
                            assert(() { print('[RoleCard] selected="$_selectedRole"'); return true; }());
                          }),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _RoleCard(
                          value: 'admin',
                          label: 'مشرف',
                          icon: Icons.manage_accounts_outlined,
                          selectedValue: _selectedRole,
                          onTap: (v) => setState(() {
                            _selectedRole = v;
                            // ignore: avoid_print
                            assert(() { print('[RoleCard] selected="$_selectedRole"'); return true; }());
                          }),
                        ),
                      ),
                    ],
                  ),
                  Gap(20.h),
                ],

                // قسم الصلاحيات — يظهر فقط لحساب "مشرف" (admin).
                if (_selectedRole == 'admin') ...[
                  Text(
                    'صلاحيات الحساب',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(8.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _selectedPermissions
                              ..clear()
                              ..addAll(_kPermissionOptions.keys);
                          }),
                          child: const Text('مدير (كل الصلاحيات)'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _selectedPermissions.clear()),
                          child: const Text('مشرف (اختيار يدوي)'),
                        ),
                      ),
                    ],
                  ),
                  Gap(4.h),
                  ..._kPermissionOptions.entries.map(
                    (entry) => CheckboxListTile(
                      value: _selectedPermissions.contains(entry.key),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selectedPermissions.add(entry.key);
                        } else {
                          _selectedPermissions.remove(entry.key);
                        }
                      }),
                      title: Text(entry.value, style: TextStyle(fontSize: 14.sp)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Gap(12.h),
                ],
                Gap(20.h),

                // Submit button
                SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            'إضافة المستخدم',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                Gap(16.h),

                // Cancel button
                SizedBox(
                  height: 52.h,
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey700,
                      side: const BorderSide(color: AppColors.grey300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
