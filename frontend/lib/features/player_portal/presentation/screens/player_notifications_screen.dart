import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player_portal/data/player_api_service.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:basketball_academy/features/player_portal/presentation/screens/player_matches_screen.dart';
import 'package:basketball_academy/features/player_portal/presentation/screens/player_training_rating_screen.dart';
import 'package:basketball_academy/features/tournaments/presentation/screens/player_tournaments_screen.dart';
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
      case 'TRAINING_RATING_REQUEST':
        return Icons.star_rate_rounded;
      case 'MATCH_ADDED':
        return Icons.sports_basketball;
      case 'TOURNAMENT_SCHEDULED':
      case 'TOURNAMENT_RESULT':
        return Icons.emoji_events_outlined;
      case 'SUBSCRIPTION_RENEWED':
        return Icons.card_membership_outlined;
      case 'SUBSCRIPTION_EXPIRING':
      case 'SESSIONS_EXHAUSTED':
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
                  onTap: n['type'] == 'TRAINING_RATING_REQUEST'
                      ? () => _openRating(context, ref, n)
                      : (n['type'] == 'TOURNAMENT_SCHEDULED' || n['type'] == 'TOURNAMENT_RESULT')
                          ? () async {
                              if (!isRead) {
                                await sl<PlayerApiService>()
                                    .markNotificationRead(n['_id'] as String);
                                ref.invalidate(playerNotificationsProvider);
                              }
                              if (!context.mounted) return;
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const PlayerTournamentsScreen(),
                              ));
                            }
                      : n['type'] == 'MATCH_ADDED'
                          ? () async {
                              if (!isRead) {
                                await sl<PlayerApiService>()
                                    .markNotificationRead(n['_id'] as String);
                                ref.invalidate(playerNotificationsProvider);
                              }
                              if (!context.mounted) return;
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const PlayerMatchesScreen(),
                              ));
                            }
                          : isRead
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

  // إشعار "قيّم تمرينك" يفتح شاشة التقييم — متاحة لحد آخر اليوم التالي للتمرين،
  // والسيرفر يرفض إن انتهت المهلة أو سبق التقييم.
  Future<void> _openRating(
      BuildContext context, WidgetRef ref, Map<String, dynamic> n) async {
    final meta = (n['meta'] as Map?) ?? const {};
    final attendanceId = meta['attendanceId']?.toString();
    if (n['isRead'] != true) {
      await sl<PlayerApiService>().markNotificationRead(n['_id'] as String);
      ref.invalidate(playerNotificationsProvider);
    }
    if (attendanceId == null || !context.mounted) return;
    final pending =
        await ref.read(playerPendingTrainingRatingsProvider.future).catchError((_) => <Map<String, dynamic>>[]);
    if (!context.mounted) return;
    if (!pending.any((p) => p['attendanceId'] == attendanceId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم تقييم هذا التمرين أو انتهت مهلة تقييمه'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerTrainingRatingScreen(
        attendanceId: attendanceId,
        date: meta['date']?.toString(),
      ),
    ));
  }
}
