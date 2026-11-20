import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

const _freezeBlue = Color(0xFF0E7490);

/// قسم التجميد في بطاقة الاشتراك: حالة التجميد + زر تجميد / فك التجميد.
class FreezeSection extends ConsumerWidget {
  final SubscriptionEntity subscription;
  final bool canEdit;

  const FreezeSection({super.key, required this.subscription, required this.canEdit});

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final s = subscription;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.isFrozen ? 'فك التجميد' : 'إلغاء التجميد المجدول'),
        content: Text(s.isFrozen
            ? 'اللاعب رجع؟ هيتحسب عدد الأيام اللي عدّت من التجميد بس، والباقي يرجع لنهاية الاشتراك.'
            : 'التجميد لسه مابدأش — هيتلغي بالكامل وترجع نهاية الاشتراك زي ما كانت.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final r = await resumePlayerSubscription(ref, s.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.error ?? r.message ?? 'تم'),
      backgroundColor: r.error != null ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = subscription;
    final df = DateFormat('dd/MM/yyyy', 'ar');

    if (s.hasOpenFreeze) {
      final label = s.isFrozen
          ? 'مجمّد حتى ${df.format(s.freezeLastDay!)}'
          : 'تجميد مجدول من ${df.format(s.freezeStart!)} (${s.freezeDays} يوم)';
      return Container(
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: _freezeBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(Icons.ac_unit, size: 18.sp, color: _freezeBlue),
            Gap(6.w),
            Expanded(
              child: Text(
                '$label • ${SubscriptionEntity.freezeReasonLabel(s.freezeReason)}',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: _freezeBlue),
              ),
            ),
            if (canEdit)
              TextButton(
                onPressed: () => _resume(context, ref),
                child: Text(s.isFrozen ? 'فك التجميد' : 'إلغاء'),
              ),
          ],
        ),
      );
    }

    if (!canEdit || !s.isActive) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => showFreezeSheet(context, subscription: s),
        icon: Icon(Icons.ac_unit, size: 18.sp, color: _freezeBlue),
        label: const Text('تجميد الاشتراك', style: TextStyle(color: _freezeBlue)),
      ),
    );
  }
}

/// نافذة تجميد الاشتراك: عدد الأيام + تاريخ البداية + السبب.
Future<void> showFreezeSheet(BuildContext context, {required SubscriptionEntity subscription}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
    builder: (_) => _FreezeSheet(subscription: subscription),
  );
}

class _FreezeSheet extends ConsumerStatefulWidget {
  final SubscriptionEntity subscription;

  const _FreezeSheet({required this.subscription});

  @override
  ConsumerState<_FreezeSheet> createState() => _FreezeSheetState();
}

class _FreezeSheetState extends ConsumerState<_FreezeSheet> {
  final _days = TextEditingController(text: '14');
  final _note = TextEditingController();
  DateTime _start = DateTime.now();
  String _reason = 'injury';
  bool _saving = false;

  static const _reasons = ['injury', 'travel', 'exams', 'illness', 'other'];

  @override
  void dispose() {
    _days.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _dayCount => int.tryParse(_days.text.trim()) ?? 0;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final last = widget.subscription.endDate.subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: last.isBefore(now) ? now : last,
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _submit() async {
    final days = _dayCount;
    if (days < 1 || days > 365) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('عدد الأيام لازم يكون من 1 لـ 365'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    final error = await freezePlayerSubscription(
      ref,
      subscriptionId: widget.subscription.id,
      days: days,
      startDate: DateFormat('yyyy-MM-dd', 'en').format(_start),
      reason: _reason,
      note: _note.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم تجميد الاشتراك $days يوم'),
      backgroundColor: error != null ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy', 'ar');
    final newEnd = widget.subscription.endDate.add(Duration(days: _dayCount.clamp(0, 365)));
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.ac_unit, color: _freezeBlue, size: 24.sp),
                Gap(8.w),
                Text('تجميد الاشتراك',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
              ],
            ),
            Gap(4.h),
            Text(
              'أيام التجميد مش هتتحسب غياب، ونهاية الاشتراك هتتمد بنفس عدد الأيام.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey600),
            ),
            Gap(14.h),
            Wrap(
              spacing: 6.w,
              children: [
                for (final n in [7, 14, 30])
                  ChoiceChip(
                    label: Text('$n يوم'),
                    selected: _dayCount == n,
                    onSelected: (_) => setState(() => _days.text = '$n'),
                  ),
              ],
            ),
            Gap(8.h),
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'عدد الأيام',
                prefixIcon: const Icon(Icons.timelapse),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            Gap(10.h),
            OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('يبدأ من: ${df.format(_start)}'),
            ),
            Gap(10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final r in _reasons)
                  ChoiceChip(
                    label: Text(SubscriptionEntity.freezeReasonLabel(r)),
                    selected: _reason == r,
                    onSelected: (_) => setState(() => _reason = r),
                  ),
              ],
            ),
            Gap(10.h),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: _freezeBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'نهاية الاشتراك: ${df.format(widget.subscription.endDate)} ← ${df.format(newEnd)}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _freezeBlue),
              ),
            ),
            Gap(12.h),
            ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.ac_unit),
              label: const Text('تجميد'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                backgroundColor: _freezeBlue,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
