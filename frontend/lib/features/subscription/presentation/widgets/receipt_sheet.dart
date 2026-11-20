import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/utils/currency_utils.dart';
import 'package:basketball_academy/features/subscription/domain/entities/receipt_entity.dart';
import 'package:basketball_academy/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:basketball_academy/features/subscription/services/receipt_pdf_service.dart';
import 'package:basketball_academy/features/subscription/services/whatsapp_image_share.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

/// نافذة الإيصال: ملخص + مشاركة PDF + طباعة + رسالة واتساب لولي الأمر.
/// [load] يجلب بيانات الإيصال (من السيرفر أو جاهزة).
Future<void> showReceiptSheet(
  BuildContext context, {
  required Future<ReceiptEntity> Function() load,
  bool allowWhatsApp = true,
  String title = 'تم تسجيل الدفعة',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => _ReceiptSheet(load: load, allowWhatsApp: allowWhatsApp, title: title),
  );
}

class _ReceiptSheet extends StatefulWidget {
  final Future<ReceiptEntity> Function() load;
  final bool allowWhatsApp;
  final String title;

  const _ReceiptSheet({required this.load, required this.allowWhatsApp, required this.title});

  @override
  State<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<_ReceiptSheet> {
  late Future<ReceiptEntity> _future = widget.load();
  bool _busy = false;

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('تعذّر تنفيذ العملية: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(ReceiptEntity r) => _run(() async {
        final bytes = await ReceiptPdfService.build(r);
        await Printing.sharePdf(bytes: bytes, filename: ReceiptPdfService.fileName(r));
      });

  Future<void> _print(ReceiptEntity r) => _run(() async {
        final bytes = await ReceiptPdfService.build(r);
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: ReceiptPdfService.fileName(r),
        );
      });

  /// إرسال الإيصال على واتساب كصورة:
  ///  - أندرويد: الصورة جاهزة في محادثة ولي الأمر مباشرة (أو قائمة المشاركة لو فشل).
  ///  - ويب/ويندوز: رسالة فيها رابط صورة الإيصال (واتساب يعرض معاينة الصورة).
  Future<void> _whatsApp(ReceiptEntity r) async {
    final phone = r.contactPhone;
    if (phone == null) {
      _snack('لا يوجد رقم هاتف لولي الأمر أو اللاعب', error: true);
      return;
    }
    String? webMessage;
    await _run(() async {
      final png = await ReceiptPdfService.png(r);
      final summary = ReceiptPdfService.textSummary(r);

      if (WhatsAppImageShare.isSupported) {
        final sent = await WhatsAppImageShare.send(png: png, phone: phone, text: summary);
        if (!sent) {
          await Share.shareXFiles(
            [XFile.fromData(png, name: 'receipt_${r.receiptNoLabel}.png', mimeType: 'image/png')],
            text: summary,
          );
        }
        return;
      }

      final url = await fetchReceiptShareLink(
        subscriptionId: r.subscriptionId,
        paymentId: r.paymentId,
        png: png,
      );
      final message = '$summary\n\nصورة الإيصال: $url';
      if (kIsWeb) {
        // المتصفح يمنع فتح نافذة بعد انتظار الرفع ⇒ زر بضغطة جديدة.
        webMessage = message;
        return;
      }
      final ok = await WhatsAppUtils.open(phone, message: message);
      if (!ok) _snack('تعذّر فتح واتساب', error: true);
    });

    if (webMessage != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('رابط الإيصال جاهز'),
          content: const Text('هيتفتح واتساب برسالة فيها صورة الإيصال (معاينة) لولي الأمر.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                WhatsAppUtils.open(phone, message: webMessage);
              },
              icon: const Icon(Icons.chat_outlined),
              label: const Text('فتح واتساب'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: FutureBuilder<ReceiptEntity>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              height: 160.h,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 40.sp),
                Gap(8.h),
                Text(
                  'تعذّر تحميل الإيصال\n${snap.error ?? ''}'.trim(),
                  textAlign: TextAlign.center,
                ),
                Gap(12.h),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _future = widget.load()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            );
          }
          final r = snap.data!;
          final currency = CurrencyUtils.label(r.currencyCode);
          final df = DateFormat('dd/MM/yyyy', 'ar');
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: AppColors.primary, size: 26.sp),
                  Gap(10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
                        if (r.receiptNoLabel.isNotEmpty)
                          Text('إيصال رقم ${r.receiptNoLabel}',
                              style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
              Gap(14.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _line('اللاعب', r.playerName),
                    _line('المبلغ', '${ReceiptPdfService.money(r.amount)} $currency • ${r.methodLabel}'),
                    _line('التاريخ', df.format(r.date)),
                    _line(
                      'المتبقي',
                      r.fullyPaid
                          ? 'مدفوع بالكامل'
                          : '${ReceiptPdfService.money(r.remainingAfter)} $currency',
                      color: r.fullyPaid ? AppColors.success : const Color(0xFFB45309),
                    ),
                  ],
                ),
              ),
              Gap(14.h),
              ElevatedButton.icon(
                onPressed: _busy ? null : () => _share(r),
                icon: _busy
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.share_outlined),
                label: const Text('مشاركة الإيصال PDF'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 46.h)),
              ),
              Gap(8.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _print(r),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('طباعة'),
                    ),
                  ),
                  if (widget.allowWhatsApp) ...[
                    Gap(8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _whatsApp(r),
                        icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                        label: const Text('إرسال واتساب'),
                      ),
                    ),
                  ],
                ],
              ),
              Gap(4.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(String label, String value, {Color? color}) => Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.grey800,
                ),
              ),
            ),
          ],
        ),
      );
}
