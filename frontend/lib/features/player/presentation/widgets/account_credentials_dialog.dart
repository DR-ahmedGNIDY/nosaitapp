import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

/// نافذة بيانات دخول اللاعب (username/password) — تُعرض مرة واحدة بعد
/// إنشاء الحساب أو إعادة إنشاء كلمة المرور، مع نسخ/مشاركة/إرسال واتساب.
///
/// إرسال واتساب: لو الرقمان متاحان (ولي الأمر واللاعب) نسأل عن الوجهة في كل
/// مرة؛ ولو رقم واحد فقط نفتح واتساب مباشرة؛ ولو لا رقم فالزر معطّل.
class AccountCredentialsDialog {
  AccountCredentialsDialog._();

  /// نص الرسالة — بلا روابط عمداً (طلب المستخدم).
  static String buildMessage({
    required String username,
    required String password,
    String playerName = '',
    String academyName = '',
  }) {
    final who = playerName.isNotEmpty ? ' $playerName' : '';
    final where = academyName.isNotEmpty ? academyName : 'الأكاديمية';
    return 'مرحباً، بيانات الدخول الخاصة باللاعب$who على تطبيق $where:\n'
        'اسم المستخدم: $username\n'
        'كلمة المرور: $password';
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String username,
    required String password,
    String playerName = '',
    String academyName = '',
    String? parentPhone,
    String? playerPhone,
  }) async {
    final message = buildMessage(
      username: username,
      password: password,
      playerName: playerName,
      academyName: academyName,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            Gap(8.w),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _credRow('اسم المستخدم', username),
              Gap(10.h),
              _credRow('كلمة المرور', password),
              Gap(12.h),
              Text('احفظ هذه البيانات — لن تظهر كلمة المرور مرة أخرى.',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
              Gap(12.h),
              _WhatsAppButton(
                message: message,
                parentPhone: parentPhone,
                playerPhone: playerPhone,
              ),
              Gap(8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: [
                  _actionChip(ctx,
                      icon: Icons.copy,
                      label: 'نسخ اسم المستخدم',
                      onTap: () => _copy(ctx, username, 'تم نسخ اسم المستخدم')),
                  _actionChip(ctx,
                      icon: Icons.copy,
                      label: 'نسخ كلمة المرور',
                      onTap: () => _copy(ctx, password, 'تم نسخ كلمة المرور')),
                  _actionChip(ctx,
                      icon: Icons.share,
                      label: 'مشاركة',
                      onTap: () => Share.share(message)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  static Future<void> _copy(
      BuildContext context, String value, String done) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(done)));
    }
  }

  static Widget _actionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16.sp, color: AppColors.primary),
      label: Text(label, style: TextStyle(fontSize: 11.sp)),
      onPressed: onTap,
    );
  }

  static Widget _credRow(String label, String value) {
    return Container(
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
          Text(label,
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
          Gap(4.h),
          SelectableText(value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
              textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}

/// زر "إرسال على واتساب" + اختيار الرقم عند توفّر رقمين.
class _WhatsAppButton extends StatelessWidget {
  final String message;
  final String? parentPhone;
  final String? playerPhone;

  const _WhatsAppButton({
    required this.message,
    this.parentPhone,
    this.playerPhone,
  });

  static const _green = Color(0xFF25D366);

  List<({String label, String phone})> get _targets => [
        if ((parentPhone ?? '').trim().isNotEmpty)
          (label: 'رقم ولي الأمر', phone: parentPhone!.trim()),
        if ((playerPhone ?? '').trim().isNotEmpty)
          (label: 'رقم اللاعب', phone: playerPhone!.trim()),
      ];

  Future<void> _send(BuildContext context, String phone) async {
    final ok = await WhatsAppUtils.open(phone, message: message);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح واتساب — انسخ البيانات وأرسلها يدوياً'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onPressed(BuildContext context) async {
    final targets = _targets;
    if (targets.length == 1) return _send(context, targets.first.phone);

    // رقمان ⇒ نسأل عن الوجهة في كل مرة.
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('إرسال البيانات إلى'),
        children: [
          for (final t in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(t.phone),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat, color: _green),
                title: Text(t.label, style: TextStyle(fontSize: 13.sp)),
                subtitle: Text(t.phone,
                    textDirection: TextDirection.ltr,
                    style:
                        TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text('إلغاء'),
            ),
          ),
        ],
      ),
    );
    if (picked != null && context.mounted) await _send(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _targets.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 10.h),
            ),
            onPressed: enabled ? () => _onPressed(context) : null,
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('إرسال على واتساب'),
          ),
        ),
        if (!enabled)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text('لا يوجد رقم مسجّل لهذا اللاعب',
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
          ),
      ],
    );
  }
}
