import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_constants.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// شريط تنبيه اشتراك الأكاديمية في لوحة التحكم:
/// - برتقالي: باقٍ 7 أيام أو أقل على انتهاء الاشتراك (تجريبي أو مدفوع).
/// - أحمر: الاشتراك منتهٍ/معلّق — التسجيل الجديد مقفول حتى التجديد.
/// لا يظهر لـ super_admin ولا لاشتراك بعيد الانتهاء.
class AcademySubscriptionBanner extends ConsumerWidget {
  const AcademySubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    if (user == null) return const SizedBox.shrink();

    final expired = user.isAcademyReadOnly;
    if (!expired && !user.isAcademySubscriptionExpiringSoon) {
      return const SizedBox.shrink();
    }

    final days = user.academySubscriptionDaysLeft ?? 0;
    final color = expired ? AppColors.error : AppColors.warning;
    final title = expired ? 'انتهى اشتراك الأكاديمية' : 'اشتراك الأكاديمية قرب ينتهي';
    final body = expired
        ? 'لا يمكن تسجيل اشتراكات أو حضور جديد. تواصل مع إدارة Nosait لتجديد الاشتراك.'
        : days <= 1
            ? 'ينتهي الاشتراك خلال يوم. تواصل مع إدارة Nosait للتجديد حتى لا يتوقف التسجيل.'
            : 'باقٍ $days أيام على انتهاء الاشتراك. تواصل مع إدارة Nosait للتجديد.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(expired ? Icons.lock_outline : Icons.timer_outlined, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14, color: color)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.grey700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF25D366)),
            onPressed: () => WhatsAppUtils.open(
              AppConstants.companyWhatsappNumber,
              message: AppConstants.contactDefaultMessage,
            ),
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('واتساب'),
          ),
        ],
      ),
    );
  }
}
