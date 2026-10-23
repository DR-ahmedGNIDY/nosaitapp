import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/features/player_portal/data/player_api_service.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// تقييم اللاعب لتمرين حضره: 5 نجوم + ملاحظات اختيارية.
/// يُفتح من إشعار "قيّم تمرينك" (attendanceId من الإشعار) أو من الإجراء السريع.
class PlayerTrainingRatingScreen extends ConsumerStatefulWidget {
  final String attendanceId;
  final String? date; // 'YYYY-MM-DD'

  const PlayerTrainingRatingScreen({
    super.key,
    required this.attendanceId,
    this.date,
  });

  @override
  ConsumerState<PlayerTrainingRatingScreen> createState() =>
      _PlayerTrainingRatingScreenState();
}

class _PlayerTrainingRatingScreenState
    extends ConsumerState<PlayerTrainingRatingScreen> {
  final _notesController = TextEditingController();
  int _stars = 0;
  bool _saving = false;

  static const _labels = ['', 'سيئ', 'مقبول', 'جيد', 'جيد جداً', 'ممتاز'];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String get _dateLabel {
    final d = DateTime.tryParse(widget.date ?? '');
    return d == null ? '' : DateFormat('EEEE dd/MM/yyyy', 'ar').format(d);
  }

  Future<void> _submit() async {
    if (_stars == 0 || _saving) return;
    setState(() => _saving = true);
    String? error;
    try {
      await sl<PlayerApiService>().submitTrainingRating(
        attendanceId: widget.attendanceId,
        stars: _stars,
        notes: _notesController.text.trim(),
      );
    } on AppException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'تعذّر تسجيل التقييم، حاول مرة أخرى';
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ref.invalidate(playerPendingTrainingRatingsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم تسجيل التقييم، شكراً لك'),
      backgroundColor: error == null ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
    if (error == null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تقييم التمرين'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          Icon(Icons.sports_basketball, size: 56.sp, color: AppColors.primary),
          Gap(12.h),
          Text(
            'كيف كان تمرينك؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
          ),
          if (_dateLabel.isNotEmpty) ...[
            Gap(4.h),
            Text(_dateLabel,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.grey500)),
          ],
          Gap(24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 44.sp,
                  onPressed: _saving ? null : () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i <= _stars ? AppColors.warning : AppColors.grey300,
                  ),
                ),
            ],
          ),
          Text(
            _stars == 0 ? 'اختر عدد النجوم' : _labels[_stars],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _stars == 0 ? AppColors.grey500 : AppColors.grey800,
            ),
          ),
          Gap(24.h),
          TextField(
            controller: _notesController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'ملاحظاتك (اختياري)',
              hintText: 'اكتب أي ملاحظة عن التمرين...',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          Gap(16.h),
          ElevatedButton.icon(
            onPressed: _stars == 0 || _saving ? null : _submit,
            icon: _saving
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white),
                  )
                : const Icon(Icons.check),
            label: Text('تسجيل التقييم',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 52.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
