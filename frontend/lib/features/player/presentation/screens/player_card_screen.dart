import 'dart:typed_data';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/services/player_card_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// بطاقة تعريف دائمة للاعب — تُطبع مرة واحدة. تحتوي فقط: اسم الأكاديمية،
/// الرياضة، اسم اللاعب، الكود، ورمز QR (لا صورة ولا تواريخ متغيّرة).
class PlayerCardScreen extends ConsumerWidget {
  final PlayerEntity player;
  const PlayerCardScreen({super.key, required this.player});

  /// محتوى الـ QR — معرّف ثابت مشتق من كود اللاعب (لا يتغيّر مدى الحياة).
  String get _qrData => 'PLAYER:${player.playerCode}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyName =
        ref.watch(academyByIdProvider(player.academyId)).valueOrNull?.name ??
            'الأكاديمية';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('بطاقة اللاعب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 560.w),
                child: AspectRatio(
                  aspectRatio: 1.586,
                  child: _CardView(
                    academyName: academyName,
                    fullName: player.fullName,
                    playerCode: player.playerCode,
                    sport: player.sport ?? '',
                    qrData: _qrData,
                  ),
                ),
              ),
            ),
            Gap(28.h),
            _ActionButtons(
              buildPdf: () => PlayerCardPdfService.generate(
                academyName: academyName,
                fullName: player.fullName,
                playerCode: player.playerCode,
                sport: player.sport ?? '',
                qrData: _qrData,
              ),
              fileName: 'player_card_${player.playerCode}.pdf',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// بطاقة العرض الأفقية — تصميم "مقسّم" (QR يسار / النصوص يمين)
// ---------------------------------------------------------------------------

class _CardView extends StatelessWidget {
  final String academyName;
  final String fullName;
  final String playerCode;
  final String sport;
  final String qrData;

  const _CardView({
    required this.academyName,
    required this.fullName,
    required this.playerCode,
    required this.sport,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: AppColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(w * 0.035),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // اليمين: الأكاديمية + الرياضة + الاسم + الكود
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                academyName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: w * 0.055,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                  height: 1.1,
                                ),
                              ),
                              if (sport.isNotEmpty) ...[
                                SizedBox(height: w * 0.022),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: w * 0.03, vertical: w * 0.012),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius:
                                        BorderRadius.circular(w * 0.05),
                                    border: Border.all(
                                        color: AppColors.primary, width: 1),
                                  ),
                                  child: Text(
                                    sport,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: w * 0.032,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // اسم اللاعب — أكبر عنصر بصري + الكود تحته
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: w * 0.072,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: w * 0.025),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.04, vertical: w * 0.016),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(w * 0.05),
                                ),
                                child: Text(
                                  playerCode,
                                  style: TextStyle(
                                    fontSize: w * 0.04,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: w * 0.005),
                        ],
                      ),
                    ),
                  ),
                  // اليسار: لوحة QR كبيرة + عبارة المسح
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: AppColors.primaryContainer,
                      padding: EdgeInsets.all(w * 0.04),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  padding: EdgeInsets.all(w * 0.02),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius:
                                        BorderRadius.circular(w * 0.025),
                                    border: Border.all(
                                        color: AppColors.primary, width: 2),
                                  ),
                                  child: QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    backgroundColor: AppColors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: AppColors.secondary,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: AppColors.secondary,
                                    ),
                                    errorStateBuilder: (_, __) => Center(
                                      child: Text(
                                        'تعذّر توليد QR',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: w * 0.03,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: w * 0.025),
                          Text(
                            'امسح الكود لتسجيل الحضور والانصراف',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: w * 0.028,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// أزرار: تحميل PDF / مشاركة / طباعة
// ---------------------------------------------------------------------------

class _ActionButtons extends StatefulWidget {
  final Future<Uint8List> Function() buildPdf;
  final String fileName;
  const _ActionButtons({required this.buildPdf, required this.fileName});

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(Uint8List bytes) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await widget.buildPdf();
      if (bytes.isEmpty) {
        throw StateError('ملف PDF فارغ');
      }
      await action(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذّر إنشاء البطاقة: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _run((bytes) =>
                    Printing.sharePdf(bytes: bytes, filename: widget.fileName)),
                icon: const Icon(Icons.download_outlined),
                label: const Text('تحميل PDF'),
              ),
            ),
            Gap(8.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _run((bytes) =>
                    Printing.sharePdf(bytes: bytes, filename: widget.fileName)),
                icon: const Icon(Icons.share_outlined),
                label: const Text('مشاركة البطاقة'),
              ),
            ),
          ],
        ),
        Gap(8.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () =>
                _run((bytes) => Printing.layoutPdf(onLayout: (_) async => bytes)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('طباعة البطاقة'),
          ),
        ),
      ],
    );
  }
}
