import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/notification/domain/entities/notification_entity.dart';
import 'package:basketball_academy/features/notification/presentation/providers/notification_provider.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        title: Text(
          'الإشعارات',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          notifAsync.whenOrNull(
            data: (list) => list.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.white),
                    onSelected: (value) async {
                      if (value == 'mark_all') {
                        await notifier.markAllAsRead();
                      } else if (value == 'delete_all') {
                        final confirmed = await _confirmDeleteAll(context);
                        if (confirmed == true) await notifier.deleteAll();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'mark_all',
                        child: Row(
                          children: [
                            Icon(Icons.done_all, size: 20),
                            SizedBox(width: 8),
                            Text('تحديد الكل كمقروء'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_outlined,
                                size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف جميع الإشعارات',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
              Gap(12.h),
              Text('تعذر تحميل الإشعارات'),
              Gap(12.h),
              TextButton(
                onPressed: () => notifier.refresh(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => notifier.refresh(),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: list.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 72.w,
                color: AppColors.grey200,
              ),
              itemBuilder: (context, index) {
                final notif = list[index];
                return _NotificationTile(
                  notification: notif,
                  onTap: () => _handleTap(notifier, notif),
                  onDelete: () => notifier.deleteNotification(notif.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // الضغط على الإشعار: تحديده كمقروء + فتح WhatsApp مباشرةً برسالة جاهزة لرقم ولي الأمر.
  Future<void> _handleTap(
      NotificationNotifier notifier, NotificationEntity n) async {
    notifier.markAsRead(n.id);
    String? message;
    if (n.type == NotificationType.birthday) {
      message = WhatsAppUtils.birthdayTemplate(
        academyName: n.academyName ?? 'الأكاديمية',
        playerName: n.playerName ?? '',
      );
    } else if (n.type == NotificationType.subscriptionExpiring ||
        n.type == NotificationType.subscriptionExpired) {
      message = WhatsAppUtils.subscriptionExpiryTemplate(
        academyName: n.academyName ?? 'الأكاديمية',
        playerName: n.playerName ?? '',
      );
    }
    final phone = n.parentPhone;
    if (message != null && phone != null && phone.isNotEmpty) {
      await WhatsAppUtils.open(phone, message: message);
    }
  }

  Future<bool?> _confirmDeleteAll(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف جميع الإشعارات'),
        content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80.sp,
            color: AppColors.grey300,
          ),
          Gap(16.h),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
          Gap(8.h),
          Text(
            'ستظهر هنا إشعارات أعياد الميلاد\nوانتهاء الاشتراكات',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Tile ───────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: AppColors.error,
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.only(right: 20.w),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead ? null : AppColors.primaryContainer.withValues(alpha: 0.3),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotifIcon(type: notification.type),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppColors.grey900,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Gap(4.h),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.grey600,
                        height: 1.4,
                      ),
                    ),
                    Gap(6.h),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16.sp, color: AppColors.grey400),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.w),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'اليوم ${DateFormat('HH:mm').format(dt)}';
    if (day == today.subtract(const Duration(days: 1))) return 'أمس';
    return DateFormat('dd/MM/yyyy', 'ar').format(dt);
  }
}

class _NotifIcon extends StatelessWidget {
  final NotificationType type;
  const _NotifIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.birthday => (Icons.cake_outlined, AppColors.primary),
      NotificationType.subscriptionExpiring =>
        (Icons.warning_amber_outlined, AppColors.warning),
      NotificationType.subscriptionExpired =>
        (Icons.cancel_outlined, AppColors.error),
      NotificationType.system =>
        (Icons.info_outline, AppColors.secondary),
    };

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22.sp),
    );
  }
}

// ─── Bell Icon Widget (استخدامها في AppBar) ─────────────────────────────────

class NotificationBellIcon extends ConsumerWidget {
  final VoidCallback onTap;
  const NotificationBellIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return IconButton(
      onPressed: onTap,
      tooltip: 'الإشعارات',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(
          unread > 9 ? '9+' : '$unread',
          style: TextStyle(fontSize: 10.sp, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

// ─── Recent Notifications Widget (لـ Dashboard) ─────────────────────────────

class RecentNotificationsWidget extends ConsumerWidget {
  final VoidCallback onViewAll;
  const RecentNotificationsWidget({super.key, required this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return notifAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        final recent = list.take(3).toList();
        final unreadCount = list.where((n) => !n.isRead).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'آخر الإشعارات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      Gap(8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Gap(8.h),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < recent.length; i++) ...[
                    _MiniNotifTile(notification: recent[i]),
                    if (i < recent.length - 1)
                      Divider(
                        height: 1,
                        indent: 56.w,
                        color: AppColors.grey100,
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniNotifTile extends StatelessWidget {
  final NotificationEntity notification;
  const _MiniNotifTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notification.type) {
      NotificationType.birthday => (Icons.cake_outlined, AppColors.primary),
      NotificationType.subscriptionExpiring =>
        (Icons.warning_amber_outlined, AppColors.warning),
      NotificationType.subscriptionExpired =>
        (Icons.cancel_outlined, AppColors.error),
      NotificationType.system => (Icons.info_outline, AppColors.secondary),
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(2.h),
                Text(
                  notification.body.replaceAll('\n', ' '),
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 7.w,
              height: 7.w,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
