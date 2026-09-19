import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/features/player/data/player_account_service.dart';
import 'package:basketball_academy/features/player/presentation/widgets/account_credentials_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// حالة حساب اللاعب — تُجلب عند فتح صفحة اللاعب.
/// { portalEnabled, hasAccount, account: {username, isActive}? }
final playerAccountInfoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, playerId) async {
  return sl<PlayerAccountService>().getAccount(playerId);
});

/// بطاقة "حساب اللاعب" داخل صفحة اللاعب — نفس الـ Widget لكل المنصات
/// (Android / Windows / Flutter Web).
///
/// - لا حساب → «لا يوجد حساب لهذا اللاعب» + زر إنشاء حساب.
/// - يوجد حساب → اسم المستخدم + الحالة (Active/Disabled) + أزرار الإدارة.
/// - الميزة معطّلة للأكاديمية → البطاقة لا تظهر إطلاقاً.
class PlayerAccountSection extends ConsumerWidget {
  final String playerId;
  final String playerName;
  final bool canEdit;
  /// أرقام إرسال بيانات الدخول على واتساب (اختيارية).
  final String? parentPhone;
  final String? playerPhone;
  final String academyName;

  const PlayerAccountSection({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.canEdit,
    this.parentPhone,
    this.playerPhone,
    this.academyName = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canEdit) return const SizedBox.shrink();

    final infoAsync = ref.watch(playerAccountInfoProvider(playerId));
    return infoAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final portalEnabled = info['portalEnabled'] == true;
        if (!portalEnabled) return const SizedBox.shrink();

        final hasAccount = info['hasAccount'] == true;
        final account = info['account'] as Map<String, dynamic>?;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 0.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_circle_outlined,
                        size: 20.sp, color: AppColors.primary),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        'حساب اللاعب',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                      ),
                    ),
                    if (hasAccount && account != null)
                      _StatusChip(isActive: account['isActive'] == true),
                  ],
                ),
                Gap(12.h),
                if (!hasAccount)
                  _NoAccountBody(
                    playerId: playerId,
                    playerName: playerName,
                    parentPhone: parentPhone,
                    playerPhone: playerPhone,
                    academyName: academyName,
                  )
                else if (account != null)
                  _AccountBody(
                    playerId: playerId,
                    playerName: playerName,
                    username: account['username'] as String? ?? '',
                    isActive: account['isActive'] == true,
                    parentPhone: parentPhone,
                    playerPhone: playerPhone,
                    academyName: academyName,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── لا يوجد حساب ────────────────────────────────────────────────────────────

class _NoAccountBody extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;
  final String? parentPhone;
  final String? playerPhone;
  final String academyName;
  const _NoAccountBody({
    required this.playerId,
    required this.playerName,
    this.parentPhone,
    this.playerPhone,
    this.academyName = '',
  });

  @override
  ConsumerState<_NoAccountBody> createState() => _NoAccountBodyState();
}

class _NoAccountBodyState extends ConsumerState<_NoAccountBody> {
  bool _busy = false;

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final created =
          await sl<PlayerAccountService>().createAccount(widget.playerId);
      if (!mounted) return;
      ref.invalidate(playerAccountInfoProvider(widget.playerId));
      await AccountCredentialsDialog.show(
        context,
        title: 'تم إنشاء الحساب بنجاح',
        username: created['username'] as String? ?? '',
        password: created['password'] as String? ?? '',
        playerName: widget.playerName,
        academyName: widget.academyName,
        parentPhone: widget.parentPhone,
        playerPhone: widget.playerPhone,
      );
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'لا يوجد حساب لهذا اللاعب.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.grey500),
        ),
        Gap(12.h),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          onPressed: _busy ? null : _create,
          icon: _busy
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white),
                )
              : const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('إنشاء حساب'),
        ),
      ],
    );
  }
}

// ─── يوجد حساب ───────────────────────────────────────────────────────────────

class _AccountBody extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;
  final String username;
  final bool isActive;
  final String? parentPhone;
  final String? playerPhone;
  final String academyName;

  const _AccountBody({
    required this.playerId,
    required this.playerName,
    required this.username,
    required this.isActive,
    this.parentPhone,
    this.playerPhone,
    this.academyName = '',
  });

  @override
  ConsumerState<_AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends ConsumerState<_AccountBody> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ref.invalidate(playerAccountInfoProvider(widget.playerId));
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final password = await _ChangePasswordDialog.show(context);
    if (password == null) return;
    await _run(() async {
      await sl<PlayerAccountService>()
          .changePassword(widget.playerId, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  Future<void> _resetPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('إعادة إنشاء كلمة المرور'),
        content: const Text(
            'سيتم توليد كلمة مرور عشوائية جديدة وإلغاء كلمة المرور الحالية. متابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('متابعة')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      final data =
          await sl<PlayerAccountService>().resetPassword(widget.playerId);
      if (mounted) {
        await AccountCredentialsDialog.show(
          context,
          title: 'تم إعادة إنشاء كلمة المرور',
          username: data['username'] as String? ?? widget.username,
          password: data['password'] as String? ?? '',
          playerName: widget.playerName,
          academyName: widget.academyName,
          parentPhone: widget.parentPhone,
          playerPhone: widget.playerPhone,
        );
      }
    });
  }

  Future<void> _toggle() async {
    final disabling = widget.isActive;
    if (disabling) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text('تعطيل الحساب'),
          content: const Text(
              'لن يستطيع اللاعب تسجيل الدخول بعد التعطيل. متابعة؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تعطيل'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _run(() async {
      await sl<PlayerAccountService>()
          .toggleAccount(widget.playerId, isActive: !widget.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disabling ? 'تم تعطيل الحساب' : 'تم تفعيل الحساب'),
            backgroundColor:
                disabling ? AppColors.grey700 : AppColors.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // اسم المستخدم
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اسم المستخدم',
                  style:
                      TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
              Gap(4.h),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.username,
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w800),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  IconButton(
                    tooltip: 'نسخ اسم المستخدم',
                    icon: Icon(Icons.copy, size: 18.sp),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: widget.username));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم نسخ اسم المستخدم')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Gap(12.h),
        if (_busy)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('تغيير كلمة المرور'),
                ),
              ),
              Gap(8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetPassword,
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: const Text('إعادة إنشاء كلمة مرور'),
                ),
              ),
            ],
          ),
          Gap(8.h),
          widget.isActive
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  onPressed: _toggle,
                  icon: const Icon(Icons.block_outlined, size: 18),
                  label: const Text('تعطيل الحساب'),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: _toggle,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('تفعيل الحساب'),
                ),
        ],
      ],
    );
  }
}

// ─── شارة الحالة ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isActive ? 'Active' : 'Disabled',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 12.sp),
      ),
    );
  }
}

// ─── نافذة تغيير كلمة المرور ─────────────────────────────────────────────────

class _ChangePasswordDialog {
  static Future<String?> show(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('تغيير كلمة المرور'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'كلمة المرور 6 أحرف على الأقل'
                    : null,
              ),
              Gap(8.h),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                validator: (v) => v != passwordController.text
                    ? 'كلمتا المرور غير متطابقتين'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, passwordController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}


// ─── مساعد عرض الأخطاء ───────────────────────────────────────────────────────

void _showError(BuildContext context, Object e) {
  final msg = e is AppException ? e.message : 'حدث خطأ غير متوقع';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error),
  );
}
