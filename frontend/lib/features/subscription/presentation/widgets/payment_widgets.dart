import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:basketball_academy/features/subscription/presentation/screens/debts_screen.dart';
import 'package:basketball_academy/features/subscription/presentation/widgets/receipt_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// تنسيق مبلغ بدون كسور غير لازمة (500 / 250.5).
String formatMoney(double value) {
  final rounded = (value * 100).roundToDouble() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(2);
}

Color paymentStatusColor(PaymentStatus s) => switch (s) {
      PaymentStatus.paid => AppColors.success,
      PaymentStatus.partial => const Color(0xFFE08A00),
      PaymentStatus.unpaid => AppColors.error,
    };

// ---------------------------------------------------------------------------
// Initial payment (add / renew subscription forms)
// ---------------------------------------------------------------------------

/// حالة قسم "الدفع" في نموذج إضافة/تجديد الاشتراك.
class InitialPaymentController {
  bool fullyPaid = true;
  String method = 'cash';
  final TextEditingController paidController = TextEditingController();

  /// المدفوع المُرسل للسيرفر: null ⇒ المبلغ كاملاً.
  double? paidAmountFor(double total) {
    if (fullyPaid) return null;
    final v = double.tryParse(paidController.text.trim()) ?? 0;
    return v.clamp(0, total).toDouble();
  }

  void dispose() => paidController.dispose();
}

/// قسم الدفع: "مدفوع بالكامل" أو مبلغ مدفوع جزئياً + طريقة الدفع.
class InitialPaymentSection extends StatefulWidget {
  final InitialPaymentController controller;
  final TextEditingController amountController;
  final String currencyLabel;

  const InitialPaymentSection({
    super.key,
    required this.controller,
    required this.amountController,
    required this.currencyLabel,
  });

  @override
  State<InitialPaymentSection> createState() => _InitialPaymentSectionState();
}

class _InitialPaymentSectionState extends State<InitialPaymentSection> {
  InitialPaymentController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    widget.amountController.addListener(_onChanged);
    c.paidController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.amountController.removeListener(_onChanged);
    c.paidController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  double get _total => double.tryParse(widget.amountController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = double.tryParse(c.paidController.text.trim()) ?? 0;
    final remaining = (_total - paid).clamp(0, double.infinity).toDouble();

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.primary, size: 20.sp),
              Gap(8.w),
              Expanded(
                child: Text(
                  'الدفع',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('مدفوع بالكامل',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
              Switch(
                value: c.fullyPaid,
                onChanged: (v) => setState(() => c.fullyPaid = v),
              ),
            ],
          ),
          if (!c.fullyPaid) ...[
            Gap(8.h),
            TextFormField(
              controller: c.paidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'المدفوع الآن',
                hintText: '0 = لم يدفع بعد',
                suffixText: widget.currencyLabel,
                prefixIcon: const Icon(Icons.price_check_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              validator: (v) {
                if (c.fullyPaid) return null;
                final t = v?.trim() ?? '';
                final value = t.isEmpty ? 0 : double.tryParse(t);
                if (value == null || value < 0) return 'مبلغ غير صحيح';
                if (value > _total + 0.005) {
                  return 'المدفوع أكبر من مبلغ الاشتراك';
                }
                return null;
              },
            ),
            Gap(6.h),
            Text(
              'المتبقي على اللاعب: ${formatMoney(remaining)} ${widget.currencyLabel}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: remaining > 0 ? paymentStatusColor(PaymentStatus.partial) : AppColors.success,
              ),
            ),
          ],
          Gap(10.h),
          PaymentMethodChips(
            value: c.method,
            onChanged: (m) => setState(() => c.method = m),
          ),
        ],
      ),
    );
  }
}

/// اختيار طريقة الدفع.
class PaymentMethodChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PaymentMethodChips({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: [
        for (final m in PaymentMethods.all)
          ChoiceChip(
            label: Text(PaymentMethods.label(m), style: TextStyle(fontSize: 12.sp)),
            selected: value == m,
            onSelected: (_) => onChanged(m),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge + progress
// ---------------------------------------------------------------------------

class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final String label;

  const PaymentStatusBadge({super.key, required this.status, required this.label});

  factory PaymentStatusBadge.of(SubscriptionEntity s) =>
      PaymentStatusBadge(status: s.paymentStatus, label: s.paymentStatusLabel);

  @override
  Widget build(BuildContext context) {
    final color = paymentStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// شريط المدفوع/المتبقي لاشتراك.
class PaymentProgress extends StatelessWidget {
  final SubscriptionEntity subscription;
  final String currencyLabel;

  const PaymentProgress({super.key, required this.subscription, required this.currencyLabel});

  @override
  Widget build(BuildContext context) {
    final s = subscription;
    final ratio = s.amount <= 0 ? 1.0 : (s.paidAmount / s.amount).clamp(0.0, 1.0);
    final color = paymentStatusColor(s.paymentStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6.h,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        Gap(6.h),
        Row(
          children: [
            Text(
              'المدفوع: ${formatMoney(s.paidAmount)} $currencyLabel',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey700),
            ),
            const Spacer(),
            if (s.hasDebt)
              Text(
                'المتبقي: ${formatMoney(s.remainingAmount)} $currencyLabel',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color),
              ),
          ],
        ),
      ],
    );
  }
}

/// سجل الدفعات قابل للطي مع حذف الدفعة.
class PaymentsHistoryTile extends ConsumerWidget {
  final SubscriptionEntity subscription;
  final String currencyLabel;
  final bool canEdit;

  const PaymentsHistoryTile({
    super.key,
    required this.subscription,
    required this.currencyLabel,
    required this.canEdit,
  });

  Future<void> _delete(BuildContext context, WidgetRef ref, SubscriptionPaymentEntity p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الدفعة'),
        content: Text('حذف دفعة ${formatMoney(p.amount)} $currencyLabel؟ سيرجع المبلغ للمتبقي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await deleteSubscriptionPayment(
      ref,
      subscriptionId: subscription.id,
      paymentId: p.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم حذف الدفعة'),
      backgroundColor: error != null ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = subscription.payments;
    // اشتراك قديم بلا سجل دفعات لكنه مدفوع ⇒ زر إيصال (يُرقَّم عند أول طلب).
    if (payments.isEmpty) {
      if (subscription.paidAmount <= 0) return const SizedBox.shrink();
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => showReceiptSheet(
            context,
            title: 'إيصال دفع',
            load: () => fetchPaymentReceipt(
              subscriptionId: subscription.id,
              paymentId: 'legacy',
            ),
          ),
          icon: Icon(Icons.receipt_outlined, size: 18.sp),
          label: const Text('إيصال الدفع'),
        ),
      );
    }
    final df = DateFormat('dd/MM/yyyy', 'ar');
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          'سجل الدفعات (${payments.length})',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.grey700),
        ),
        children: [
          for (final p in payments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.receipt_long_outlined, size: 18.sp, color: AppColors.primary),
              title: Text(
                '${formatMoney(p.amount)} $currencyLabel • ${p.methodLabel}'
                '${p.receiptNo != null ? ' • #${p.receiptNo.toString().padLeft(6, '0')}' : ''}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  df.format(p.date.toLocal()),
                  if (p.recordedByName.isNotEmpty) p.recordedByName,
                  if (p.note != null && p.note!.isNotEmpty) p.note!,
                ].join(' • '),
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
              ),
              trailing: p.id.isEmpty
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'الإيصال',
                          icon: Icon(Icons.receipt_outlined, size: 18.sp, color: AppColors.primary),
                          onPressed: () => showReceiptSheet(
                            context,
                            title: 'إيصال دفع',
                            load: () => fetchPaymentReceipt(
                              subscriptionId: subscription.id,
                              paymentId: p.id,
                            ),
                          ),
                        ),
                        if (canEdit)
                          IconButton(
                            tooltip: 'حذف الدفعة',
                            icon: Icon(Icons.delete_outline, size: 18.sp, color: AppColors.error),
                            onPressed: () => _delete(context, ref, p),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add payment bottom sheet
// ---------------------------------------------------------------------------

/// يفتح نافذة "تسجيل دفعة"، وبعد النجاح يفتح الإيصال مباشرة.
/// يرجّع true عند تسجيل الدفعة بنجاح.
Future<bool> showAddPaymentSheet(
  BuildContext context, {
  required String subscriptionId,
  required double remaining,
  required String currencyLabel,
  String? playerName,
}) async {
  final paymentId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => _AddPaymentSheet(
      subscriptionId: subscriptionId,
      remaining: remaining,
      currencyLabel: currencyLabel,
      playerName: playerName,
    ),
  );
  if (paymentId == null) return false;
  if (paymentId.isNotEmpty && context.mounted) {
    await showReceiptSheet(
      context,
      load: () => fetchPaymentReceipt(subscriptionId: subscriptionId, paymentId: paymentId),
    );
  }
  return true;
}

class _AddPaymentSheet extends ConsumerStatefulWidget {
  final String subscriptionId;
  final double remaining;
  final String currencyLabel;
  final String? playerName;

  const _AddPaymentSheet({
    required this.subscriptionId,
    required this.remaining,
    required this.currencyLabel,
    this.playerName,
  });

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
      TextEditingController(text: formatMoney(widget.remaining));
  final _note = TextEditingController();
  String _method = 'cash';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;
    final result = await recordSubscriptionPayment(
      ref,
      subscriptionId: widget.subscriptionId,
      amount: double.parse(_amount.text.trim()),
      method: _method,
      // اليوم ⇒ لحظة التسجيل الفعلية؛ تاريخ سابق ⇒ منتصف ذلك اليوم.
      date: isToday ? null : DateTime(_date.year, _date.month, _date.day, 12),
      note: _note.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error!),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    // الدفعة الجديدة = آخر عنصر في سجل الدفعات ('' ⇒ بدون إيصال).
    final payments = result.subscription?.payments ?? const [];
    Navigator.of(context).pop(payments.isNotEmpty ? payments.last.id : '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd/MM/yyyy', 'ar');
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20.h,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تسجيل دفعة',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (widget.playerName != null) ...[
                Gap(2.h),
                Text(widget.playerName!,
                    style: TextStyle(fontSize: 13.sp, color: AppColors.grey600)),
              ],
              Gap(4.h),
              Text(
                'المتبقي: ${formatMoney(widget.remaining)} ${widget.currencyLabel}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: paymentStatusColor(PaymentStatus.partial),
                ),
              ),
              Gap(14.h),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'مبلغ الدفعة',
                  suffixText: widget.currencyLabel,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (v) {
                  final value = double.tryParse(v?.trim() ?? '');
                  if (value == null || value <= 0) return 'أدخل مبلغاً صحيحاً';
                  if (value > widget.remaining + 0.005) return 'المبلغ أكبر من المتبقي';
                  return null;
                },
              ),
              Gap(8.h),
              Wrap(
                spacing: 6.w,
                children: [
                  ActionChip(
                    label: const Text('كامل المتبقي'),
                    onPressed: () => _amount.text = formatMoney(widget.remaining),
                  ),
                  ActionChip(
                    label: const Text('النصف'),
                    onPressed: () => _amount.text = formatMoney(widget.remaining / 2),
                  ),
                ],
              ),
              Gap(12.h),
              PaymentMethodChips(value: _method, onChanged: (m) => setState(() => _method = m)),
              Gap(12.h),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('تاريخ الدفع: ${df.format(_date)}'),
              ),
              Gap(12.h),
              TextFormField(
                controller: _note,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              Gap(8.h),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.check),
                label: const Text('تسجيل الدفعة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بعد إضافة/تجديد اشتراك: يعرض إيصال الدفعة الأولى (لو اتدفع حاجة).
Future<void> showFirstPaymentReceipt(
  BuildContext context,
  SubscriptionEntity? subscription,
) async {
  if (subscription == null || subscription.payments.isEmpty || !context.mounted) return;
  final paymentId = subscription.payments.first.id;
  await showReceiptSheet(
    context,
    title: 'تم تسجيل الاشتراك',
    load: () => fetchPaymentReceipt(
      subscriptionId: subscription.id,
      paymentId: paymentId,
    ),
  );
}

// ---------------------------------------------------------------------------
// Entry point to the debts screen
// ---------------------------------------------------------------------------

/// زر "المديونيات" في شريط شاشة الاشتراكات.
class DebtsActionButton extends StatelessWidget {
  final String academyId;

  const DebtsActionButton({super.key, required this.academyId});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DebtsScreen(academyId: academyId)),
      ),
      icon: const Icon(Icons.account_balance_wallet_outlined),
      label: const Text('المديونيات'),
    );
  }
}
