import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// "تحديد مواعيد التمرين" في فورم اللاعب: عند التفعيل يظهر لكل يوم حضور مختار
/// حقل لاختيار ساعة بداية التمرين. القيم بصيغة 'HH:mm' (تُعرض للاعب في حسابه).
class TrainingTimesSection extends StatelessWidget {
  final List<String> selectedDays;
  final bool enabled;
  final Map<String, String> times;
  final ValueChanged<bool> onEnabledChanged;
  final void Function(String day, String time) onTimeChanged;

  const TrainingTimesSection({
    super.key,
    required this.selectedDays,
    required this.enabled,
    required this.times,
    required this.onEnabledChanged,
    required this.onTimeChanged,
  });

  /// المواعيد المرسلة للسيرفر: فقط للأيام المختارة. مُعطّل ⇒ {} (حذف المواعيد).
  static Map<String, String> payload(bool enabled, List<String> days, Map<String, String> times) {
    if (!enabled) return {};
    return {for (final d in days) if (times[d] != null) d: times[d]!};
  }

  static String display(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${p.length > 1 ? p[1] : '00'} ${h < 12 ? 'ص' : 'م'}';
  }

  Future<void> _pick(BuildContext context, String day) async {
    final cur = times[day]?.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: cur == null
          ? const TimeOfDay(hour: 17, minute: 0)
          : TimeOfDay(hour: int.tryParse(cur[0]) ?? 17, minute: int.tryParse(cur[1]) ?? 0),
    );
    if (picked == null) return;
    onTimeChanged(day,
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: enabled,
          onChanged: onEnabledChanged,
          title: Text('تحديد مواعيد التمرين',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          subtitle: Text('موعد بداية التمرين لكل يوم — يظهر للاعب في حسابه',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
        ),
        if (enabled) ...[
          if (selectedDays.isEmpty)
            Text('اختر أيام الحضور أولاً',
                style: TextStyle(fontSize: 12.sp, color: AppColors.warning))
          else
            for (final day in selectedDays)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: InkWell(
                  onTap: () => _pick(context, day),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(day,
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                        ),
                        Icon(Icons.access_time, size: 18.sp, color: AppColors.grey500),
                        Gap(6.w),
                        Text(
                          times[day] == null ? 'اختر الموعد' : display(times[day]!),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: times[day] == null ? AppColors.grey500 : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}
