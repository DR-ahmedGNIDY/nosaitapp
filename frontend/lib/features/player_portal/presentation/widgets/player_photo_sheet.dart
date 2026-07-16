import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/utils/image_size_validator.dart';
import 'package:basketball_academy/features/player_portal/data/player_api_service.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

/// ورقة خيارات صورة اللاعب: تغيير الصورة (من المعرض فقط) أو حذفها.
/// لا يوجد خيار كاميرا عمداً.
Future<void> showPlayerPhotoSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool hasImage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap(12.h),
          Container(
            width: 42.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Gap(8.h),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('تغيير الصورة'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await _changePhoto(context, ref);
            },
          ),
          ListTile(
            enabled: hasImage,
            leading: Icon(
              Icons.delete_outline,
              color: hasImage ? AppColors.error : AppColors.grey200,
            ),
            title: Text(
              'حذف الصورة',
              style: TextStyle(color: hasImage ? AppColors.error : null),
            ),
            onTap: hasImage
                ? () async {
                    Navigator.pop(sheetContext);
                    await _deletePhoto(context, ref);
                  }
                : null,
          ),
          Gap(8.h),
        ],
      ),
    ),
  );
}

// الـ messenger يُلتقط قبل أي await حتى لا نستخدم BuildContext بعد فجوة async.
void _toast(ScaffoldMessengerState messenger, String message, {bool error = false}) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ),
  );
}

Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);

  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  // الحد نفسه مطبَّق في الخادم؛ الفحص هنا يمنع رفعاً سيُرفض على أي حال.
  final sizeError = await validateImageSize(picked);
  if (sizeError != null) {
    _toast(messenger, sizeError, error: true);
    return;
  }

  try {
    await sl<PlayerApiService>().updatePhoto(picked.path);
    ref.invalidate(playerDashboardProvider);
    _toast(messenger, 'تم تحديث الصورة بنجاح');
  } catch (e) {
    _toast(messenger, 'تعذّر رفع الصورة. حاول مرة أخرى.', error: true);
  }
}

Future<void> _deletePhoto(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف الصورة'),
      content: const Text('هل تريد حذف صورتك الشخصية؟ ستعود الصورة الافتراضية.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('حذف', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await sl<PlayerApiService>().deletePhoto();
    ref.invalidate(playerDashboardProvider);
    _toast(messenger, 'تم حذف الصورة بنجاح');
  } catch (e) {
    _toast(messenger, 'تعذّر حذف الصورة. حاول مرة أخرى.', error: true);
  }
}
