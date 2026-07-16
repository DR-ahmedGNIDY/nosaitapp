import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player_portal/data/player_api_service.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// إشعارات اللاعب.
class PlayerNotificationsScreen extends ConsumerWidget {
  const PlayerNotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'NEW_MESSAGE':
        return Icons.chat_bubble_outline;
      case 'ATTENDANCE_PRESENT':
        return Icons.how_to_reg_outlined;
      case 'EVALUATION_ADDED':
        return Icons.star_outline;
      case 'SUBSCRIPTION_RENEWED':
        return Icons.card_membership_outlined;
      case 'SUBSCRIPTION_EXPIRING':
        return Icons.timer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            tooltip: 'تعليم الكل كمقروء',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await sl<PlayerApiService>().markAllNotificationsRead();
              ref.invalidate(playerNotificationsProvider);
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(playerNotificationsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (data) {
          final items = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
          if (items.isEmpty) {
            return Center(
              child: Text('لا توجد إشعارات',
                  style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(playerNotificationsProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(12.r),
              itemCount: items.length,
              separatorBuilder: (_, __) => Gap(8.h),
              itemBuilder: (context, i) {
                final n = items[i];
                final isRead = n['isRead'] == true;
                final createdAt = DateTime.tryParse(n['createdAt'] as String? ?? '');
                return ListTile(
                  tileColor: isRead ? AppColors.white : AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  leading: Icon(_iconFor(n['type'] as String? ?? ''), color: AppColors.primary),
                  title: Text(n['title'] as String? ?? '',
                      style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w800)),
                  subtitle: Text(n['body'] as String? ?? ''),
                  trailing: createdAt != null
                      ? Text(DateFormat('MM/dd HH:mm').format(createdAt),
                          style: TextStyle(fontSize: 11.sp, color: AppColors.grey500))
                      : null,
                  onTap: isRead
                      ? null
                      : () async {
                          await sl<PlayerApiService>()
                              .markNotificationRead(n['_id'] as String);
                          ref.invalidate(playerNotificationsProvider);
                        },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
