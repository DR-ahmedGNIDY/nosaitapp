import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/academy/presentation/providers/currency_provider.dart';
import 'package:basketball_academy/features/subscription/domain/entities/academy_debts_entity.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:basketball_academy/features/subscription/presentation/screens/player_subscription_history_screen.dart';
import 'package:basketball_academy/features/subscription/presentation/widgets/payment_widgets.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// المديونيات: كل اللاعبين الذين عليهم مبالغ متبقية من اشتراكاتهم،
/// مع تسجيل دفعة وتذكير ولي الأمر على واتساب بضغطة.
class DebtsScreen extends ConsumerStatefulWidget {
  final String academyId;

  const DebtsScreen({super.key, required this.academyId});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _academyName() {
    final academies = ref.read(academiesProvider).valueOrNull;
    if (academies == null) return 'الأكاديمية';
    for (final a in academies) {
      if (a.id == widget.academyId) return a.name;
    }
    return 'الأكاديمية';
  }

  /// رسالة التذكير — تُفتح في واتساب ليراجعها المدير قبل الإرسال.
  String _reminderMessage(PlayerDebtEntity p, String currency) {
    return 'السلام عليكم ولي أمر اللاعب ${p.fullName}،\n'
        'نود تذكيركم بأن المتبقي من اشتراك اللاعب في ${_academyName()} '
        'هو ${formatMoney(p.totalDue)} $currency.\n'
        'شكراً لتعاونكم 🌹';
  }

  Future<void> _remind(PlayerDebtEntity p, String currency) async {
    final phone = p.contactPhone;
    if (phone == null) {
      _snack('لا يوجد رقم هاتف لولي الأمر أو اللاعب', error: true);
      return;
    }
    final ok = await WhatsAppUtils.open(phone, message: _reminderMessage(p, currency));
    if (!ok && mounted) _snack('تعذّر فتح واتساب', error: true);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  List<PlayerDebtEntity> _filter(List<PlayerDebtEntity> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((p) =>
            p.fullName.toLowerCase().contains(q) ||
            p.playerCode.toLowerCase().contains(q) ||
            (p.contactPhone ?? '').contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(academyDebtsProvider(widget.academyId));
    final currency = ref.watch(academyCurrencyLabelProvider(widget.academyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المديونيات'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(academyDebtsProvider(widget.academyId).future),
        child: debtsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Gap(80.h),
              Icon(Icons.error_outline, size: 56.sp, color: AppColors.error),
              Gap(12.h),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Gap(12.h),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => ref.invalidate(academyDebtsProvider(widget.academyId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
          data: (debts) {
            final players = _filter(debts.players);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.r),
              children: [
                _SummaryCard(debts: debts, currency: currency),
                Gap(12.h),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الكود أو رقم الهاتف...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.grey200),
                    ),
                  ),
                ),
                Gap(12.h),
                if (debts.players.isEmpty)
                  _EmptyState()
                else if (players.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: const Center(child: Text('لا توجد نتائج مطابقة')),
                  )
                else
                  for (final p in players) ...[
                    _PlayerDebtCard(
                      debt: p,
                      currency: currency,
                      onRemind: () => _remind(p, currency),
                      onPay: (s) => showAddPaymentSheet(
                        context,
                        subscriptionId: s.id,
                        remaining: s.remainingAmount,
                        currencyLabel: currency,
                        playerName: p.fullName,
                      ),
                      onOpenHistory: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PlayerSubscriptionHistoryScreen(
                          playerId: p.playerId,
                          academyId: widget.academyId,
                          playerName: p.fullName,
                        ),
                      )),
                    ),
                    Gap(10.h),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AcademyDebtsEntity debts;
  final String currency;

  const _SummaryCard({required this.debts, required this.currency});

  @override
  Widget build(BuildContext context) {
    final color = paymentStatusColor(PaymentStatus.partial);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined, color: color, size: 26.sp),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إجمالي المتبقي',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
                Text(
                  '${formatMoney(debts.totalOutstanding)} $currency',
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${debts.playersCount}',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
              Text('لاعب', style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerDebtCard extends StatelessWidget {
  final PlayerDebtEntity debt;
  final String currency;
  final VoidCallback onRemind;
  final void Function(DebtSubscriptionEntity) onPay;
  final VoidCallback onOpenHistory;

  const _PlayerDebtCard({
    required this.debt,
    required this.currency,
    required this.onRemind,
    required this.onPay,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy', 'ar');
    final dueColor = paymentStatusColor(PaymentStatus.partial);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpenHistory,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.grey200,
                  backgroundImage: (debt.imageUrl != null && debt.imageUrl!.isNotEmpty)
                      ? NetworkImage(debt.imageUrl!)
                      : null,
                  child: (debt.imageUrl == null || debt.imageUrl!.isEmpty)
                      ? Icon(Icons.person, color: AppColors.grey500, size: 20.sp)
                      : null,
                ),
                Gap(10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.fullName,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        [
                          if (debt.playerCode.isNotEmpty) '#${debt.playerCode}',
                          if (!debt.isActive) 'غير نشط',
                        ].join(' • '),
                        style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${formatMoney(debt.totalDue)} $currency',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: dueColor),
                ),
              ],
            ),
          ),
          Gap(8.h),
          for (final s in debt.subscriptions)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.typeLabel} • ${df.format(s.startDate.toLocal())}\n'
                      'دفع ${formatMoney(s.paidAmount)} من ${formatMoney(s.amount)} — '
                      'متبقي ${formatMoney(s.remainingAmount)}',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey700, height: 1.4),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onPay(s),
                    icon: Icon(Icons.add_card, size: 18.sp),
                    label: const Text('دفعة'),
                  ),
                ],
              ),
            ),
          Gap(6.h),
          OutlinedButton.icon(
            onPressed: onRemind,
            icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
            label: const Text('تذكير على واتساب'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        children: [
          Icon(Icons.verified_outlined, size: 64.sp, color: AppColors.success),
          Gap(12.h),
          Text(
            'لا توجد مديونيات — كل الاشتراكات مدفوعة 👏',
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}
