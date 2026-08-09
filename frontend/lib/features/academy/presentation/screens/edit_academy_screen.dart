import 'dart:io';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/core/constants/sports_constants.dart';
import 'package:basketball_academy/core/utils/currency_utils.dart';
import 'package:basketball_academy/core/utils/image_size_validator.dart';
import 'package:basketball_academy/core/widgets/multi_select_chips.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class EditAcademyScreen extends ConsumerStatefulWidget {
  final AcademyEntity academy;

  const EditAcademyScreen({super.key, required this.academy});

  @override
  ConsumerState<EditAcademyScreen> createState() => _EditAcademyScreenState();
}

class _EditAcademyScreenState extends ConsumerState<EditAcademyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _facebookController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _instagramController;

  late String _selectedCurrency;
  late List<String> _selectedSports;
  bool _isLoading = false;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.academy.name);
    _phoneController = TextEditingController(text: widget.academy.phone);
    _addressController = TextEditingController(text: widget.academy.address);
    _websiteController = TextEditingController(text: widget.academy.websiteUrl ?? '');
    _facebookController = TextEditingController(text: widget.academy.facebookUrl ?? '');
    _tiktokController = TextEditingController(text: widget.academy.tiktokUrl ?? '');
    _instagramController = TextEditingController(text: widget.academy.instagramUrl ?? '');
    _selectedCurrency = CurrencyUtils.codes.contains(widget.academy.currency)
        ? widget.academy.currency
        : CurrencyUtils.defaultCode;
    _selectedSports = widget.academy.sports.isNotEmpty
        ? List<String>.from(widget.academy.sports)
        : const [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.required;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.required;
    }
    if (value.trim().length < 7) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار رياضة واحدة على الأقل'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(academiesProvider.notifier).updateAcademy(
          id: widget.academy.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          currency: _selectedCurrency,
          sports: _selectedSports,
          websiteUrl: _websiteController.text.trim(),
          facebookUrl: _facebookController.text.trim(),
          tiktokUrl: _tiktokController.text.trim(),
          instagramUrl: _instagramController.text.trim(),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الأكاديمية بنجاح'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الأكاديمية'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header — tap to change the academy logo
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: _logoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20.r),
                                  child: kIsWeb
                                      ? Image.network(_logoPath!, fit: BoxFit.cover)
                                      : Image.file(File(_logoPath!), fit: BoxFit.cover),
                                )
                              : widget.academy.logoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20.r),
                                      child: Image.network(
                                        widget.academy.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.sports_basketball,
                                          color: AppColors.primary,
                                          size: 40.sp,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.sports_basketball,
                                      color: AppColors.primary,
                                      size: 40.sp,
                                    ),
                        ),
                        Positioned(
                          bottom: -4.h,
                          right: -4.w,
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 2),
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
                Gap(8.h),
                Center(
                  child: Text(
                    'اضغط لتغيير شعار الأكاديمية',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ),
                Gap(28.h),

                // Name field
                Text(
                  AppStrings.academyName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _nameController,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'أدخل اسم الأكاديمية',
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Phone field
                Text(
                  AppStrings.academyPhone,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _phoneController,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'أدخل رقم الهاتف',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Address field
                Text(
                  AppStrings.academyAddress,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _addressController,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'أدخل عنوان الأكاديمية',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Currency field
                Text(
                  AppStrings.currencyField,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  items: CurrencyUtils.codes
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(CurrencyUtils.labelWithCode(c)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(
                      () => _selectedCurrency = val ?? CurrencyUtils.defaultCode),
                ),
                Gap(20.h),

                // Sports multi-select
                Text(
                  'الرياضات الموجودة بالأكاديمية',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                MultiSelectChips(
                  options: SportsConstants.defaultSports,
                  selected: _selectedSports,
                  allowCustom: true,
                  customHint: 'إضافة رياضة أخرى',
                  onChanged: (sports) =>
                      setState(() => _selectedSports = sports),
                ),
                Gap(20.h),

                // Social media links (optional)
                Text(
                  'روابط التواصل الاجتماعي (اختياري)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'الموقع الإلكتروني',
                    prefixIcon: const Icon(Icons.language_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(12.h),
                TextFormField(
                  controller: _facebookController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'فيسبوك',
                    prefixIcon: const Icon(Icons.facebook_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(12.h),
                TextFormField(
                  controller: _tiktokController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'تيك توك',
                    prefixIcon: const Icon(Icons.music_note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(12.h),
                TextFormField(
                  controller: _instagramController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'إنستقرام',
                    prefixIcon: const Icon(Icons.camera_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(32.h),

                // Save button
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            AppStrings.save,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                Gap(16.h),

                // Cancel button
                SizedBox(
                  height: 52.h,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey700,
                      side: const BorderSide(color: AppColors.grey300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
