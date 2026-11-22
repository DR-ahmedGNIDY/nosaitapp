import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/platform_subscription/data/platform_subscription_service.dart';
import 'package:basketball_academy/features/platform_subscription/presentation/providers/platform_subscription_provider.dart';
import 'package:basketball_academy/features/platform_subscription/presentation/widgets/subscription_plan_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// لوحة إدارة اشتراكات المنصة (Super Admin): عرض/تفعيل/تعديل.
class PlatformSubscriptionsScreen extends ConsumerWidget {
  const PlatformSubscriptionsScreen({super.key});

  static const _statusLabels = {
    'trial': 'تجريبي',
    'active': 'نشط',
    'expired': 'منتهٍ',
    'suspended': 'معلّق',
  };
  static const _statusColors = {
    'trial': AppColors.warning,
    'active': AppColors.success,
    'expired': AppColors.error,
    'suspended': AppColors.grey500,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformSubscriptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الاشتراكات')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(platformSubscriptionsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('لا توجد أكاديميات'));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(platformSubscriptionsProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(12.r),
              itemCount: rows.length,
              separatorBuilder: (_, __) => Gap(10.h),
              itemBuilder: (context, i) => _card(context, ref, rows[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, Map<String, dynamic> row) {
    final sub = row['subscription'] as Map<String, dynamic>?;
    final status = sub?['status'] as String? ?? 'expired';
    final plan = sub?['plan'] as String?;
    final maxPlayers = (sub?['maxPlayers'] as num?)?.toInt();
    final durationMonths = (sub?['durationMonths'] as num?)?.toInt();
    final playerCount = (row['playerCount'] as num?)?.toInt() ?? 0;
    final endDate = DateTime.tryParse(sub?['endDate'] as String? ?? '');
    final portalEnabled = (sub?['playerPortalEnabled'] as bool?) ?? false;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row['academyName'] as String? ?? '',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (_statusColors[status] ?? AppColors.grey500)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(_statusLabels[status] ?? status,
                    style: TextStyle(
                        color: _statusColors[status] ?? AppColors.grey500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp)),
              ),
            ],
          ),
          Gap(10.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 6.h,
            children: [
              _info('الباقة', _packageLabel(maxPlayers, plan)),
              _info('المدة', _durationLabel(durationMonths, plan)),
              _info('اللاعبون', '$playerCount / ${maxPlayers ?? '-'}'),
              if (endDate != null)
                _info('ينتهي', DateFormat('yyyy/MM/dd').format(endDate)),
            ],
          ),
          if (portalEnabled) ...[
            Gap(10.h),
            _accountsBadge(),
          ],
          Gap(10.h),
          // ── Player Portal: الحالة + تبديل سريع ──────────────────────────
          _PlayerPortalRow(
            enabled: (sub?['playerPortalEnabled'] as bool?) ?? false,
            hasSubscription: sub != null,
            onChanged: (v) => _togglePlayerPortal(context, ref, row, v),
          ),
          Gap(8.h),
          // ── المساعد الذكي (ميزة مدفوعة) + الحد اليومي ─────────────────────
          _AiAssistantRow(
            enabled: (sub?['aiAssistantEnabled'] as bool?) ?? false,
            dailyLimit: (sub?['aiDailyLimit'] as num?)?.toInt() ?? 30,
            onToggle: (v) => _updateAi(context, ref, row, enabled: v),
            onEditLimit: () => _editAiLimit(context, ref, row,
                (sub?['aiDailyLimit'] as num?)?.toInt() ?? 30),
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showActivateDialog(context, ref, row),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('تفعيل اشتراك'),
                ),
              ),
              Gap(10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: sub == null
                      ? null
                      : () => _showEditDialog(context, ref, row),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('تعديل'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayerPortal(BuildContext context, WidgetRef ref,
      Map<String, dynamic> row, bool enabled) async {
    final academyId = row['academyId'] as String;
    try {
      await sl<PlatformSubscriptionService>()
          .setPlayerPortal(academyId: academyId, enabled: enabled);
      ref.invalidate(platformSubscriptionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                enabled ? 'تم تفعيل بوابة اللاعب' : 'تم تعطيل بوابة اللاعب'),
            backgroundColor: enabled ? AppColors.success : AppColors.grey700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) _err(context, e);
    }
  }

  Future<void> _updateAi(BuildContext context, WidgetRef ref,
      Map<String, dynamic> row, {bool? enabled, int? dailyLimit}) async {
    try {
      await sl<PlatformSubscriptionService>().setAiAssistant(
        academyId: row['academyId'] as String,
        enabled: enabled,
        dailyLimit: dailyLimit,
      );
      ref.invalidate(platformSubscriptionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enabled == null
              ? 'تم تعديل الحد اليومي إلى $dailyLimit رسالة'
              : enabled
                  ? 'تم تفعيل المساعد الذكي'
                  : 'تم تعطيل المساعد الذكي'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) _err(context, e);
    }
  }

  Future<void> _editAiLimit(BuildContext context, WidgetRef ref,
      Map<String, dynamic> row, int current) async {
    final ctrl = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الحد اليومي للمساعد الذكي'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'عدد الرسائل في اليوم (1 - 1000)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              if (n != null && n >= 1 && n <= 1000) Navigator.pop(ctx, n);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (value != null && value != current && context.mounted) {
      await _updateAi(context, ref, row, dailyLimit: value);
    }
  }

  // تسمية الباقة اعتماداً على الحد الأقصى للاعبين (100/200/300 = باقة قياسية).
  String _packageLabel(int? maxPlayers, String? plan) {
    if (maxPlayers != null && const [100, 200, 300].contains(maxPlayers)) {
      return 'باقة $maxPlayers لاعب';
    }
    if (plan == 'trial') return 'تجريبي';
    if (plan == 'legacy') return 'قديم';
    return maxPlayers != null ? '$maxPlayers لاعب' : '-';
  }

  // تسمية المدة من durationMonths، مع الرجوع للباقة عند غيابها (اشتراكات قديمة).
  String _durationLabel(int? durationMonths, String? plan) {
    switch (durationMonths) {
      case 1:
        return 'شهرية';
      case 3:
        return '3 أشهر';
      case 6:
        return '6 أشهر';
      case 12:
        return 'سنوية';
    }
    if (plan == 'month') return 'شهرية';
    if (plan == 'year') return 'سنوية';
    return '-';
  }

  Widget _accountsBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14.sp, color: AppColors.success),
          Gap(6.w),
          Text('حسابات اللاعبين مفعّلة',
              style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
        Text(value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Future<void> _showActivateDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> row) async {
    final academyId = row['academyId'] as String;
    final sub = row['subscription'] as Map<String, dynamic>?;

    final currency = await _academyCurrency(ref, academyId);
    if (!context.mounted) return;
    final result = await showSubscriptionPlanDialog(
      context,
      academyName: row['academyName'] as String? ?? '',
      academyCurrency: currency,
      editMode: false,
      currentMaxPlayers: (sub?['maxPlayers'] as num?)?.toInt(),
      currentDurationMonths: _resolveDurationMonths(sub),
      currentPortalEnabled: (sub?['playerPortalEnabled'] as bool?) ?? false,
    );
    if (result == null || !context.mounted) return;

    try {
      await sl<PlatformSubscriptionService>().activate(
        academyId: academyId,
        plan: result.plan,
        maxPlayers: result.maxPlayers ?? 0,
        durationMonths: result.durationMonths,
        playerPortalEnabled: result.playerPortalEnabled,
      );
      ref.invalidate(platformSubscriptionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تفعيل الاشتراك بنجاح'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) _err(context, e);
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> row) async {
    final academyId = row['academyId'] as String;
    final sub = row['subscription'] as Map<String, dynamic>;

    final currency = await _academyCurrency(ref, academyId);
    if (!context.mounted) return;
    final result = await showSubscriptionPlanDialog(
      context,
      academyName: row['academyName'] as String? ?? '',
      academyCurrency: currency,
      editMode: true,
      currentMaxPlayers: (sub['maxPlayers'] as num?)?.toInt(),
      currentDurationMonths: _resolveDurationMonths(sub),
      currentPortalEnabled: (sub['playerPortalEnabled'] as bool?) ?? false,
      currentStatus: sub['status'] as String? ?? 'active',
    );
    if (result == null || !context.mounted) return;

    try {
      await sl<PlatformSubscriptionService>().update(
        academyId: academyId,
        // نُرسل الباقة/الحد/المدة فقط إذا اختار المستخدم باقة قياسية —
        // وإلا نُبقي القيم الحالية (لا نكسر الأكاديميات ذات الحد غير القياسي).
        plan: result.packageChosen ? result.plan : null,
        maxPlayers: result.packageChosen ? result.maxPlayers : null,
        durationMonths: result.packageChosen ? result.durationMonths : null,
        status: result.status,
        playerPortalEnabled: result.playerPortalEnabled,
      );
      ref.invalidate(platformSubscriptionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تعديل الاشتراك بنجاح'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) _err(context, e);
    }
  }

  // مدة الاشتراك بالأشهر — من durationMonths إن وُجد، وإلا تُشتق من الباقة
  // (اشتراكات فُعِّلت قبل إضافة هذا الحقل: شهر→1، سنة→12).
  int? _resolveDurationMonths(Map<String, dynamic>? sub) {
    final dm = (sub?['durationMonths'] as num?)?.toInt();
    if (dm != null) return dm;
    switch (sub?['plan'] as String?) {
      case 'month':
        return 1;
      case 'year':
        return 12;
      default:
        return null;
    }
  }

  void _err(BuildContext ctx, Object e) {
    final msg = e is AppException ? e.message : 'حدث خطأ';
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }
}

/// صف "Player Portal": شارة Enabled/Disabled + مفتاح تبديل سريع.
class _PlayerPortalRow extends StatelessWidget {
  final bool enabled;
  final bool hasSubscription;
  final ValueChanged<bool> onChanged;

  const _PlayerPortalRow({
    required this.enabled,
    required this.hasSubscription,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.success : AppColors.grey500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Icon(Icons.smartphone_outlined, size: 18.sp, color: color),
          Gap(8.w),
          Expanded(
            child: Text('Player Portal',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              enabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11.sp),
            ),
          ),
          Gap(4.w),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

/// صف "المساعد الذكي": شارة مفعّل/معطّل + الحد اليومي (قابل للتعديل) + مفتاح.
class _AiAssistantRow extends StatelessWidget {
  final bool enabled;
  final int dailyLimit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditLimit;

  const _AiAssistantRow({
    required this.enabled,
    required this.dailyLimit,
    required this.onToggle,
    required this.onEditLimit,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primary : AppColors.grey500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18.sp, color: color),
          Gap(8.w),
          Expanded(
            child: Text('المساعد الذكي (مدفوع)',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
          ),
          InkWell(
            onTap: onEditLimit,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$dailyLimit/يوم',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 11.sp)),
                Gap(3.w),
                Icon(Icons.edit, size: 12.sp, color: color),
              ]),
            ),
          ),
          Gap(4.w),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// عملة الأكاديمية لعرض الأسعار بالجنيه (مصر) أو بالدولار (غيرها) في نافذة
/// التفعيل. عند فشل الجلب نرجع null فتُعرض أسعار مصر (الافتراضي).
Future<String?> _academyCurrency(WidgetRef ref, String academyId) async {
  try {
    final academy = await ref.read(academyByIdProvider(academyId).future);
    return academy.currency;
  } catch (_) {
    return null;
  }
}
