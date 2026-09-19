import 'dart:io';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/utils/image_size_validator.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

const _kCardColorOptions = <String, Color>{
  'navy': Color(0xFF0B2E6B),
  'red': Color(0xFFB91C1C),
  'orange': Color(0xFFC2410C),
  'black': Color(0xFF1A1A1A),
};

/// إعدادات الأكاديمية والبطاقة (شعار الأكاديمية + لون البطاقة + شعارها النصي)
/// — منقولة من شاشة "تعديل الأكاديمية" إلى شاشة مستقلة يصل إليها مدير
/// الأكاديمية من صفحة اللاعبين مباشرة. الشعار المحفوظ هنا هو نفسه الظاهر في
/// بطاقة اللاعب (player_card_screen.dart يقرأه من academyByIdProvider).
class PlayerCardSettingsScreen extends ConsumerWidget {
  final String academyId;
  const PlayerCardSettingsScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyAsync = ref.watch(academyByIdProvider(academyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات الأكاديمية والبطاقة'),
        centerTitle: true,
      ),
      body: academyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('تعذّر تحميل بيانات الأكاديمية',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey700)),
        ),
        data: (academy) => _PlayerCardSettingsForm(academy: academy),
      ),
    );
  }
}

class _PlayerCardSettingsForm extends ConsumerStatefulWidget {
  final AcademyEntity academy;
  const _PlayerCardSettingsForm({required this.academy});

  @override
  ConsumerState<_PlayerCardSettingsForm> createState() =>
      _PlayerCardSettingsFormState();
}

class _PlayerCardSettingsFormState
    extends ConsumerState<_PlayerCardSettingsForm> {
  late final TextEditingController _sloganController;
  late String _selectedCardColor;
  bool _isLoading = false;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _sloganController = TextEditingController(
      text: (widget.academy.cardSlogan != null &&
              widget.academy.cardSlogan!.isNotEmpty)
          ? widget.academy.cardSlogan!
          : 'معًا نحو القمة',
    );
    _selectedCardColor = _kCardColorOptions.containsKey(widget.academy.cardColor)
        ? widget.academy.cardColor
        : 'navy';
  }

  @override
  void dispose() {
    _sloganController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final img =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img == null) return;
      final sizeError = await validateImageSize(img);
      if (sizeError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sizeError), backgroundColor: AppColors.error),
        );
        return;
      }
      setState(() => _logoPath = img.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر اختيار الشعار')),
        );
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final academy = widget.academy;
    final error = await ref.read(academiesProvider.notifier).updateAcademy(
          id: academy.id,
          name: academy.name,
          phone: academy.phone,
          address: academy.address,
          currency: academy.currency,
          sports: academy.sports,
          websiteUrl: academy.websiteUrl,
          facebookUrl: academy.facebookUrl,
          tiktokUrl: academy.tiktokUrl,
          instagramUrl: academy.instagramUrl,
          cardColor: _selectedCardColor,
          cardSlogan: _sloganController.text.trim(),
          logoPath: _logoPath,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // بطاقة اللاعب تقرأ الشعار من هذا الـ provider — إبطاله يجعل الشعار
    // الجديد يظهر فوراً دون إعادة تشغيل التطبيق.
    ref.invalidate(academyByIdProvider(academy.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعدادات بنجاح'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  /// الصورة المعروضة: المختارة حديثاً إن وُجدت، وإلا الشعار المحفوظ، وإلا أيقونة.
  Widget _buildLogoPreview() {
    if (_logoPath != null) {
      return kIsWeb
          ? Image.network(_logoPath!, fit: BoxFit.cover)
          : Image.file(File(_logoPath!), fit: BoxFit.cover);
    }
    final logoUrl = widget.academy.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.sports_basketball,
          color: AppColors.primary,
          size: 44.sp,
        ),
      );
    }
    return Icon(Icons.sports_basketball, color: AppColors.primary, size: 44.sp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'شعار الأكاديمية',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(4.h),
            Text(
              'يظهر في بطاقة اللاعب وفي بيانات الأكاديمية.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
            ),
            Gap(12.h),
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: _buildLogoPreview(),
                      ),
                    ),
                    Positioned(
                      bottom: -4.h,
                      right: -4.w,
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.white, width: 2),
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.white,
                          size: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Gap(10.h),
            Center(
              child: TextButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  _logoPath != null ? 'تغيير الصورة المختارة' : 'اختيار شعار جديد',
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
            ),
            if (_logoPath != null)
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _logoPath = null),
                  icon: const Icon(Icons.undo, color: AppColors.error),
                  label: Text(
                    'التراجع عن الاختيار',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.error),
                  ),
                ),
              ),
            Gap(20.h),
            Text(
              'لون البطاقة',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.h),
            Wrap(
              spacing: 14.w,
              children: _kCardColorOptions.entries.map((entry) {
                final isSelected = _selectedCardColor == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCardColor = entry.key),
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.value,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: entry.value.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: AppColors.white, size: 18.sp)
                        : null,
                  ),
                );
              }).toList(),
            ),
            Gap(24.h),
            Text(
              'شعار البطاقة',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.h),
            TextFormField(
              controller: _sloganController,
              maxLength: 40,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'معًا نحو القمة',
                prefixIcon: const Icon(Icons.short_text_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            Gap(20.h),

            SizedBox(
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'حفظ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
