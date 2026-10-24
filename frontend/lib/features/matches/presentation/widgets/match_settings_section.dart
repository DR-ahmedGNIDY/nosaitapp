import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// إعدادات المباراة الثلاثة التي تُسأل عند الإنشاء (وتُعدَّل لاحقاً):
/// احتساب الحضور ضمن الحصص، وجود اشتراك يدفعه اللاعب (وقيمته)، وإضافته للإيرادات.
class MatchSettings {
  final bool countsAsSession;
  final bool hasFee;
  final bool addToRevenue;

  const MatchSettings({
    this.countsAsSession = false,
    this.hasFee = false,
    this.addToRevenue = false,
  });

  MatchSettings copyWith({bool? countsAsSession, bool? hasFee, bool? addToRevenue}) =>
      MatchSettings(
        countsAsSession: countsAsSession ?? this.countsAsSession,
        hasFee: hasFee ?? this.hasFee,
        addToRevenue: addToRevenue ?? this.addToRevenue,
      );

  /// جسم الطلب للسيرفر. القيمة فارغة ⇒ null (تُكتب بعد إنشاء المباراة).
  Map<String, dynamic> toBody(String feeText) {
    final fee = double.tryParse(feeText.trim());
    return {
      'countsAsSession': countsAsSession,
      'hasFee': hasFee,
      'feeAmount': hasFee ? fee : null,
      'addToRevenue': hasFee && addToRevenue,
    };
  }
}

class MatchSettingsSection extends StatelessWidget {
  final MatchSettings value;
  final TextEditingController feeController;
  final ValueChanged<MatchSettings> onChanged;

  const MatchSettingsSection({
    super.key,
    required this.value,
    required this.feeController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إعدادات المباراة',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
          Gap(8.h),
          _YesNo(
            question: 'هل يُحسب حضور المباراة ضمن حصص اشتراك اللاعب؟',
            value: value.countsAsSession,
            onChanged: (v) => onChanged(value.copyWith(countsAsSession: v)),
          ),
          const Divider(height: 20),
          _YesNo(
            question: 'هل يوجد اشتراك للمباراة يدفعه اللاعب؟',
            value: value.hasFee,
            onChanged: (v) => onChanged(value.copyWith(hasFee: v, addToRevenue: v ? value.addToRevenue : false)),
          ),
          if (value.hasFee) ...[
            Gap(10.h),
            TextField(
              controller: feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: 'قيمة اشتراك المباراة',
                hintText: 'يمكن كتابتها لاحقاً من تفاصيل المباراة',
                filled: true,
                fillColor: AppColors.grey50,
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            const Divider(height: 24),
            _YesNo(
              question: 'هل يُضاف اشتراك المباراة إلى الإيرادات؟',
              value: value.addToRevenue,
              onChanged: (v) => onChanged(value.copyWith(addToRevenue: v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _YesNo extends StatelessWidget {
  final String question;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _YesNo({required this.question, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: TextStyle(fontSize: 13.sp, color: AppColors.grey800)),
        Gap(6.h),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('نعم')),
            ButtonSegment(value: false, label: Text('لا')),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}
