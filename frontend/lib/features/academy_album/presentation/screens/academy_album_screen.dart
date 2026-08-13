import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/academy_album/data/academy_album_service.dart';
import 'package:basketball_academy/features/academy_album/data/album_image.dart';
import 'package:basketball_academy/features/academy_album/presentation/dialogs/album_form_dialog.dart';
import 'package:basketball_academy/features/academy_album/presentation/providers/album_providers.dart';
import 'package:basketball_academy/features/academy_album/presentation/screens/album_viewer_screen.dart';
import 'package:basketball_academy/features/academy_album/presentation/widgets/album_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ألبوم الأكاديمية — جهة المدير: عرض + إضافة + تعديل + حذف.
class AcademyAlbumScreen extends ConsumerWidget {
  const AcademyAlbumScreen({super.key});

  AcademyAlbumService get _service => sl<AcademyAlbumService>();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<AlbumFormResult>(
      context: context,
      builder: (_) => const AlbumFormDialog(),
    );
    if (res == null || res.imagePath == null) return;
    try {
      await _service.upload(
        imagePath: res.imagePath!,
        title: res.title,
        description: res.description,
        isVideo: res.isVideo,
      );
      ref.read(academyAlbumProvider.notifier).refresh();
      messenger.showSnackBar(SnackBar(
        content: Text(res.isVideo ? 'تمت إضافة الفيديو بنجاح' : 'تمت إضافة الصورة بنجاح'),
        backgroundColor: AppColors.success,
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّرت الإضافة. حاول مرة أخرى.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AlbumImage img) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<AlbumFormResult>(
      context: context,
      builder: (_) => AlbumFormDialog(existing: img),
    );
    if (res == null) return;
    try {
      await _service.update(id: img.id, title: res.title, description: res.description);
      ref.read(academyAlbumProvider.notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم تحديث الصورة'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر التحديث.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AlbumImage img) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف هذه الصورة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(img.id);
      ref.read(academyAlbumProvider.notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم حذف الصورة'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر الحذف.'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(academyAlbumProvider);
    final notifier = ref.read(academyAlbumProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('ألبوم الأكاديمية')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('إضافة صورة'),
      ),
      body: _AlbumBody(
        state: state,
        onRetry: notifier.refresh,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        onTapImage: (i) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AlbumViewerScreen(images: state.items, initialIndex: i),
        )).then((_) => notifier.refresh()),
        onEdit: (img) => _edit(context, ref, img),
        onDelete: (img) => _delete(context, ref, img),
      ),
    );
  }
}

/// جسم مشترك بين شاشة المدير واللاعب — نفس حالات التحميل/الخطأ/الفراغ.
class _AlbumBody extends StatelessWidget {
  final dynamic state; // AlbumState
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(int) onTapImage;
  final void Function(AlbumImage)? onEdit;
  final void Function(AlbumImage)? onDelete;

  const _AlbumBody({
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTapImage,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            SizedBox(height: 12.h),
            const Text('تعذّر تحميل الألبوم'),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48.sp, color: AppColors.grey500),
            SizedBox(height: 12.h),
            Text('لا توجد صور بعد', style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
          ],
        ),
      );
    }
    return AlbumGrid(
      items: state.items as List<AlbumImage>,
      loadingMore: state.loadingMore as bool,
      onLoadMore: onLoadMore,
      onRefresh: onRefresh,
      onTapImage: onTapImage,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

/// يُعاد تصديره ليستخدمه شاشة اللاعب دون تكرار.
class AlbumBody extends StatelessWidget {
  final dynamic state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(int) onTapImage;

  const AlbumBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTapImage,
  });

  @override
  Widget build(BuildContext context) => _AlbumBody(
        state: state,
        onRetry: onRetry,
        onRefresh: onRefresh,
        onLoadMore: onLoadMore,
        onTapImage: onTapImage,
      );
}
