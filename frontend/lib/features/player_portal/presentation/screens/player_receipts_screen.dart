import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/utils/currency_utils.dart';
import 'package:basketball_academy/features/player_portal/data/player_api_service.dart';
import 'package:basketball_academy/features/subscription/domain/entities/receipt_entity.dart';
import 'package:basketball_academy/features/subscription/presentation/widgets/receipt_sheet.dart';
import 'package:basketball_academy/features/subscription/services/receipt_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// إيصالات دفع اللاعب (بوابة اللاعب / ولي الأمر).
final playerReceiptsProvider =
    FutureProvider.autoDispose<List<ReceiptEntity>>((ref) async {
  final list = await sl<PlayerApiService>().receipts();
  return list.map(ReceiptEntity.fromJson).toList();
});

class PlayerReceiptsScreen extends ConsumerWidget {
  const PlayerReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerReceiptsProvider);
    final df = DateFormat('dd/MM/yyyy', 'ar');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('إيصالاتي'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(playerReceiptsProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Gap(100.h),
              Icon(Icons.error_outline, size: 52.sp, color: AppColors.error),
              Gap(10.h),
              const Center(child: Text('تعذّر تحميل الإيصالات')),
              Gap(10.h),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(playerReceiptsProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
          data: (receipts) {
            if (receipts.isEmpty) {
              return ListView(
                children: [
                  Gap(100.h),
                  Icon(Icons.receipt_long_outlined, size: 64.sp, color: AppColors.grey300),
                  Gap(10.h),
                  Center(
                    child: Text('لا توجد إيصالات بعد',
                        style: TextStyle(fontSize: 14.sp, color: AppColors.grey600)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: receipts.length,
              separatorBuilder: (_, __) => Gap(10.h),
              itemBuilder: (context, i) {
                final r = receipts[i];
                final currency = CurrencyUtils.label(r.currencyCode);
                return Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => showReceiptSheet(
                      context,
                      load: () async => r,
                      allowWhatsApp: false,
                      title: 'إيصال دفع',
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14.r),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.receipt_long, color: AppColors.primary, size: 22.sp),
                          ),
                          Gap(12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ReceiptPdfService.money(r.amount)} $currency',
                                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  [
                                    df.format(r.date),
                                    r.methodLabel,
                                    if (r.receiptNoLabel.isNotEmpty) '#${r.receiptNoLabel}',
                                  ].join(' • '),
                                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey600),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left, color: AppColors.grey400, size: 22.sp),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
