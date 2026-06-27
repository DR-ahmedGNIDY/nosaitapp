import 'dart:io' show Platform;

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/domain/usecases/record_attendance_usecase.dart';
import 'package:basketball_academy/features/attendance/presentation/widgets/web_qr_scanner.dart';
import 'package:basketball_academy/features/attendance/utils/player_qr.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class AttendanceScanScreen extends StatefulWidget {
  final String academyId;
  const AttendanceScanScreen({super.key, required this.academyId});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  // الكاميرا تُستخدم على Android والويب؛ على Windows نعتمد على إدخال يدوي/قارئ USB.
  final bool _canUseCamera = kIsWeb || (!kIsWeb && Platform.isAndroid);

  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocus = FocusNode();

  bool _processing = false;
  String? _lastCode;
  DateTime? _lastAt;
  AttendanceRecordResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!_canUseCamera) {
      // تركيز تلقائي ليستقبل قارئ USB (يكتب الكود + Enter).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _manualFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  String _nowTimeStr() {
    final d = DateTime.now();
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  Future<void> _scanWithCamera() async {
    if (kIsWeb) {
      try {
        final code = await showWebQrScanner(context);
        if (code != null && code.trim().isNotEmpty) {
          await _handleCode(code);
        }
      } catch (e) {
        debugPrint('[ATTENDANCE] web camera scan threw: $e');
        if (!mounted) return;
        setState(() {
          _error = 'تعذّر فتح الكاميرا — استخدم الإدخال اليدوي';
        });
      }
      return;
    }
    try {
      final result = await BarcodeScanner.scan();
      // Log exactly what the camera returned so issues are diagnosable.
      debugPrint(
          '[ATTENDANCE] camera scan returned: type=${result.type} rawContent="${result.rawContent}"');
      if (result.type == ResultType.Barcode &&
          result.rawContent.trim().isNotEmpty) {
        await _handleCode(result.rawContent);
      } else if (result.type == ResultType.Error) {
        if (mounted) {
          setState(() => _error = 'تعذّر قراءة الكود، حاول مرة أخرى');
        }
      }
      // ResultType.Cancelled → المستخدم أغلق الماسح، لا شيء.
    } catch (e) {
      debugPrint('[ATTENDANCE] camera scan threw: $e');
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر فتح الكاميرا — استخدم الإدخال اليدوي';
      });
    }
  }

  Future<void> _handleCode(String raw) async {
    // 1) القيمة المقروءة من الـ QR كما هي.
    debugPrint('[ATTENDANCE] QR raw value: "$raw"');
    // 2) استخراج كود اللاعب (إزالة بادئة PLAYER: إن وُجدت).
    final code = PlayerQr.extractCode(raw);
    debugPrint('[ATTENDANCE] code used for search (playerCode): "$code"');
    if (code.isEmpty || _processing) return;

    // منع تكرار الطلب لنفس الكود خلال 3 ثوانٍ (حماية ضد المسح المتكرر السريع / 429).
    if (_lastCode == code &&
        _lastAt != null &&
        DateTime.now().difference(_lastAt!).inSeconds < 3) {
      return;
    }
    _lastCode = code;
    _lastAt = DateTime.now();

    setState(() {
      _processing = true;
      _error = null;
    });

    final result = await sl<RecordAttendanceUsecase>()(
      RecordAttendanceParams(
        code: code,
        localDate: _todayStr(),
        localTime: _nowTimeStr(),
      ),
    );

    if (!mounted) return;
    result.fold(
      (failure) {
        // 4) نتيجة البحث: فشل / لم يُعثر على اللاعب.
        debugPrint('[ATTENDANCE] search result: FAILED → ${failure.message}');
        setState(() {
          _error = failure.message;
          _result = null;
          _processing = false;
        });
      },
      (res) {
        // 4) نتيجة البحث: تم العثور على اللاعب.
        debugPrint(
            '[ATTENDANCE] search result: FOUND ${res.playerName} (${res.playerCode}) recorded=${res.recorded} alreadyToday=${res.alreadyToday}');
        setState(() {
          _result = res;
          _error = null;
          _processing = false;
        });
      },
    );

    // إعادة تجهيز حقل الإدخال اليدوي للمسحة التالية.
    if (!_canUseCamera) {
      _manualController.clear();
      _manualFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مسح QR'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_canUseCamera)
              _CameraButton(onPressed: _processing ? null : _scanWithCamera)
            else
              _DesktopHint(),

            Gap(16.h),

            // حقل الإدخال اليدوي / قارئ USB (متاح على المنصتين).
            TextField(
              controller: _manualController,
              focusNode: _manualFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: _handleCode,
              decoration: InputDecoration(
                labelText: 'إدخال الكود يدوياً أو عبر قارئ USB',
                hintText: 'مثال: Y-0001',
                filled: true,
                fillColor: AppColors.white,
                prefixIcon: const Icon(Icons.qr_code_2_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _handleCode(_manualController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            Gap(20.h),

            if (_processing)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _ResultCard.error(message: _error!)
            else if (_result != null)
              _ResultCard.fromResult(_result!),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// زر فتح الكاميرا (Android) — يفتح ماسح QR كامل الشاشة
// ---------------------------------------------------------------------------

class _CameraButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _CameraButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner, size: 64.sp, color: AppColors.primary),
            Gap(10.h),
            Text(
              'اضغط لفتح الكاميرا ومسح البطاقة',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// تلميح سطح المكتب (Windows) — لا كاميرا
// ---------------------------------------------------------------------------

class _DesktopHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_scanner, size: 56.sp, color: AppColors.primary),
          Gap(12.h),
          Text(
            'استخدم قارئ QR (USB) أو أدخل كود اللاعب يدوياً في الحقل بالأسفل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// بطاقة النتيجة
// ---------------------------------------------------------------------------

class _ResultCard extends StatelessWidget {
  final bool isError;
  final String message;
  final AttendanceRecordResult? result;

  const _ResultCard._({
    required this.isError,
    required this.message,
    this.result,
  });

  factory _ResultCard.error({required String message}) =>
      _ResultCard._(isError: true, message: message);

  factory _ResultCard.fromResult(AttendanceRecordResult r) =>
      _ResultCard._(isError: false, message: r.message, result: r);

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 28.sp),
            Gap(12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final r = result!;
    // أخضر للنجاح، برتقالي للتكرار اليومي.
    final Color accent =
        r.alreadyToday ? AppColors.primary : const Color(0xFF2D9748);
    final IconData icon =
        r.alreadyToday ? Icons.info_outline : Icons.check_circle_outline;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  border: Border.all(color: accent, width: 2),
                ),
                child: ClipOval(
                  child: r.imageUrl != null && r.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: r.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(Icons.person,
                              color: accent, size: 32.sp),
                        )
                      : Icon(Icons.person, color: accent, size: 32.sp),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.playerName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.grey900,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      r.playerCode,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (r.sport != null && r.sport!.isNotEmpty) ...[
                      Gap(2.h),
                      Text(
                        r.sport!,
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.grey500),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Icon(icon, color: accent, size: 22.sp),
              Gap(8.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
