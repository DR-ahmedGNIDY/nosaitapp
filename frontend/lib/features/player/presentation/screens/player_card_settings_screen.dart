import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

const _kCardColorOptions = <String, Color>{
  'navy': Color(0xFF0B2E6B),
  'red': Color(0xFFB91C1C),
  'orange': Color(0xFFC2410C),
  'black': Color(0xFF1A1A1A),
};

/// إعدادات بطاقة اللاعب (لون البطاقة + الشعار في أسفلها) — منقولة من شاشة
/// "تعديل الأكاديمية" إلى شاشة مستقلة يصل إليها مدير الأكاديمية من صفحة
/// اللاعبين مباشرة.
class PlayerCardSettingsScreen extends ConsumerWidget {
  final String academyId;
  const PlayerCardSettingsScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyAsync = ref.watch(academyByIdProvider(academyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات بطاقة اللاعب'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث إعدادات بطاقة اللاعب بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
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
