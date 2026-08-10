import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/presentation/widgets/player_card_widget.dart';
import 'package:basketball_academy/features/player/services/player_card_export_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// بطاقة تعريف دائمة للاعب — تُطبع مرة واحدة. تحتوي: شعار واسم الأكاديمية،
/// الرياضة، صورة اللاعب، اسمه، الكود، المجموعة، ورمز QR.
///
/// [PlayerCardWidget] هو مصدر التصميم الوحيد (Single Source of Truth) —
/// نفس الـ Widget المعروض هنا هو الذي يُلتقط كصورة PNG عالية الدقة عبر
/// RepaintBoundary عند الحفظ/المشاركة/الطباعة — بلا أي هامش شفاف حولها، فالصورة
/// الناتجة تُقص عند حدود البطاقة تماماً. لا يوجد PDF ولا رسم ثانٍ للبطاقة في
/// أي مكان — راجع [PlayerCardExportService].
class PlayerCardScreen extends ConsumerStatefulWidget {
  final PlayerEntity player;
  const PlayerCardScreen({super.key, required this.player});

  @override
  ConsumerState<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends ConsumerState<PlayerCardScreen> {
  /// مفتاح الـ RepaintBoundary الذي يغلّف البطاقة المعروضة — هو مصدر الالتقاط.
  final GlobalKey _cardKey = GlobalKey();

  /// محتوى الـ QR — معرّف ثابت مشتق من كود اللاعب (لا يتغيّر مدى الحياة).
  String get _qrData => 'PLAYER:${widget.player.playerCode}';

  String get _fileName => 'player_card_${widget.player.playerCode}.png';

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final academy = ref.watch(academyByIdProvider(player.academyId)).valueOrNull;
    final academyName = academy?.name ?? 'الأكاديمية';
    final academyLogoUrl = academy?.logoUrl;

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
            Padding(
              // هامش مرئي فقط حول البطاقة على الشاشة (خارج RepaintBoundary)
              // كي يظهر الظل أثناء العرض — لا يُلتقط ضمن الصورة المُصدَّرة.
              padding: EdgeInsets.all(28.w),
              child: Center(
                // RepaintBoundary يغلّف البطاقة نفسها فقط بلا أي هامش شفاف
                // حولها — الصورة المُصدَّرة تُقص عند حدود البطاقة تماماً.
                child: RepaintBoundary(
                  key: _cardKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 560.w),
                    child: AspectRatio(
                      aspectRatio: 1.586,
                      child: PlayerCardWidget(
                        academyName: academyName,
                        academyLogoUrl: academyLogoUrl,
                        fullName: player.fullName,
                        playerCode: player.playerCode,
                        sport: player.sport ?? '',
                        imageUrl: player.imageUrl,
                        qrData: _qrData,
                        birthDate: player.birthDate,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Gap(28.h),
            _ActionButtons(cardKey: _cardKey, fileName: _fileName),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// تُولَّد الصورة مرة واحدة فقط عند الضغط على "إنشاء صورة البطاقة" (وليس عند
// فتح الصفحة) — بعدها تظهر أزرار: حفظ في الهاتف / مشاركة / فتح الصورة، مع
// إمكانية "إعادة إنشاء الصورة" في أي وقت. زر الطباعة إضافي يستخدم نفس الصورة
// المولَّدة (راجع التوثيق في PlayerCardExportService لسبب استثناء الطباعة).
// ---------------------------------------------------------------------------

class _ActionButtons extends StatefulWidget {
  final GlobalKey cardKey;
  final String fileName;
  const _ActionButtons({required this.cardKey, required this.fileName});

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _busy = false;
  Uint8List? _png;
  String? _tempPath;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تعذّرت العملية: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// يُنشئ صورة البطاقة (وإعادة الإنشاء تعيد نفس الخطوة من جديد).
  Future<void> _generate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final png = await PlayerCardExportService.capturePng(widget.cardKey);
      final path = await PlayerCardExportService.writeTempFile(png, widget.fileName);
      if (!mounted) return;
      setState(() {
        _png = png;
        _tempPath = path;
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final png = _png;
    if (png == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        throw UnsupportedError('الحفظ المباشر غير مدعوم على الويب — استخدم زر المشاركة');
      }
      final result = await PlayerCardExportService.saveToDevice(png, widget.fileName);
      _showSuccess(
        result.savedToGallery ? 'تم حفظ البطاقة في معرض الصور' : 'تم حفظ البطاقة في: ${result.filePath}',
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final png = _png;
    if (png == null || _busy) return;
    setState(() => _busy = true);
    try {
      await PlayerCardExportService.shareImage(png, widget.fileName);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    final path = _tempPath;
    if (path == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        throw UnsupportedError('فتح الصورة كملف غير مدعوم على الويب — استخدم زر المشاركة');
      }
      await PlayerCardExportService.openImage(path);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    final png = _png;
    if (png == null || _busy) return;
    setState(() => _busy = true);
    try {
      await PlayerCardExportService.printImage(png);
    } catch (e) {
      _showError(e);
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

    if (_png == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          onPressed: _generate,
          icon: const Icon(Icons.image_outlined),
          label: const Text('إنشاء صورة البطاقة'),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.download_outlined),
                label: const Text('حفظ في الهاتف'),
              ),
            ),
            Gap(8.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share_outlined),
                label: const Text('مشاركة'),
              ),
            ),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('فتح الصورة'),
              ),
            ),
            Gap(8.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('إعادة إنشاء الصورة'),
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
            onPressed: _print,
            icon: const Icon(Icons.print_outlined),
            label: const Text('طباعة البطاقة'),
          ),
        ),
      ],
    );
  }
}
