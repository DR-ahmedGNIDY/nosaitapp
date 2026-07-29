import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/academy/presentation/providers/currency_provider.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/store/data/store_product.dart';
import 'package:basketball_academy/features/store/data/store_service.dart';
import 'package:basketball_academy/features/store/presentation/dialogs/product_form_dialog.dart';
import 'package:basketball_academy/features/store/presentation/providers/store_providers.dart';
import 'package:basketball_academy/features/store/presentation/screens/store_orders_screen.dart';
import 'package:basketball_academy/features/store/presentation/widgets/product_card.dart';
import 'package:basketball_academy/features/store/presentation/widgets/store_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// متجر الأكاديمية — جهة المدير: إدارة المنتجات (إضافة/تعديل/حذف) + الوصول
/// إلى الطلبات وإعداد رقم واتساب المتجر.
class StoreManagementScreen extends ConsumerWidget {
  const StoreManagementScreen({super.key});

  StoreService get _service => sl<StoreService>();

  String _currencyLabel(WidgetRef ref) {
    final academyId = ref.read(authStateProvider).valueOrNull?.user?.academyId;
    return ref.read(academyCurrencyLabelProvider(academyId));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<ProductFormResult>(
      context: context,
      builder: (_) => ProductFormDialog(currencyLabel: _currencyLabel(ref)),
    );
    if (res == null || res.imagePath == null) return;
    try {
      await _service.createProduct(
        imagePath: res.imagePath!,
        name: res.name,
        price: res.price,
        description: res.description,
        isAvailable: res.isAvailable,
      );
      ref.read(storeProductsProvider.notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تمت إضافة المنتج بنجاح'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّرت الإضافة. حاول مرة أخرى.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, StoreProduct p) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<ProductFormResult>(
      context: context,
      builder: (_) => ProductFormDialog(existing: p, currencyLabel: _currencyLabel(ref)),
    );
    if (res == null) return;
    try {
      // تحديث الحقول النصية/السعر/التوفّر. (تغيير الصورة غير مدعوم في التعديل —
      // يُحذف المنتج ويُعاد إنشاؤه لو لزم استبدال الصورة.)
      await _service.updateProduct(
        id: p.id,
        name: res.name,
        description: res.description,
        price: res.price,
        isAvailable: res.isAvailable,
      );
      ref.read(storeProductsProvider.notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم تحديث المنتج'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر التحديث.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, StoreProduct p) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل تريد حذف "${p.name}" نهائياً؟'),
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
      await _service.deleteProduct(p.id);
      ref.read(storeProductsProvider.notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم حذف المنتج'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر الحذف.'), backgroundColor: AppColors.error));
    }
  }

  void _openSettings(BuildContext context) {
    showDialog(context: context, builder: (_) => const StoreSettingsDialog());
  }

  void _openOrders(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoreOrdersScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeProductsProvider);
    final notifier = ref.read(storeProductsProvider.notifier);
    final currencyCode =
        ref.watch(academyCurrencyCodeProvider(
            ref.read(authStateProvider).valueOrNull?.user?.academyId));
    final pending = ref.watch(storeOrdersProvider).pendingCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المتجر'),
        actions: [
          _OrdersButton(count: pending, onTap: () => _openOrders(context)),
          IconButton(
            tooltip: 'إعدادات المتجر',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
      body: _body(context, ref, state, notifier, currencyCode),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    ProductsState state,
    ProductsNotifier notifier,
    String? currencyCode,
  ) {
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
            const Text('تعذّر تحميل المنتجات'),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: notifier.refresh, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 52.sp, color: AppColors.grey400),
            SizedBox(height: 12.h),
            Text('لا توجد منتجات بعد — أضف أول منتج',
                style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
            notifier.loadMore();
          }
          return false;
        },
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 90.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.68,
          ),
          itemCount: state.items.length + (state.loadingMore ? 2 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final product = state.items[index];
            return ProductCard(
              product: product,
              currencyCode: currencyCode ?? 'EGP',
              onTap: () => _edit(context, ref, product),
              cornerMenu: _CornerMenu(
                onEdit: () => _edit(context, ref, product),
                onDelete: () => _delete(context, ref, product),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrdersButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _OrdersButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'الطلبات',
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _CornerMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CornerMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 20.sp,
        icon: const Icon(Icons.more_vert, color: AppColors.grey700),
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('تعديل')),
          PopupMenuItem(value: 'delete', child: Text('حذف')),
        ],
      ),
    );
  }
}
