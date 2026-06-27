import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:basketball_academy/features/notification/domain/entities/notification_entity.dart';
import 'package:basketball_academy/features/player/data/datasources/player_remote_datasource.dart';
import 'package:basketball_academy/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:basketball_academy/features/subscription/data/models/subscription_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationNotifier extends AsyncNotifier<List<NotificationEntity>> {
  static const _readKey = 'notification_read_ids';
  static const _deletedKey = 'notification_deleted_ids';
  static const _cacheDuration = Duration(minutes: 30);

  // In-memory cache — shared across rebuilds of the same provider instance
  List<NotificationEntity>? _cache;
  DateTime? _cacheTime;
  String? _cacheUserId;

  @override
  Future<List<NotificationEntity>> build() async {
    // Watch only the user ID — not the full AuthState.
    // This prevents rebuild on isLoading / errorMessage changes.
    final userId = ref.watch(
      authStateProvider.select((s) => s.valueOrNull?.user?.id),
    );

    if (userId == null) {
      _cache = null;
      _cacheTime = null;
      _cacheUserId = null;
      return [];
    }

    // Return cache if it belongs to the same user and is fresh (< 30 min)
    if (_cache != null &&
        _cacheUserId == userId &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null) return [];
    return _loadNotifications(user);
  }

  Future<List<NotificationEntity>> _loadNotifications(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = Set<String>.from(prefs.getStringList(_readKey) ?? []);
    final deletedIds = Set<String>.from(prefs.getStringList(_deletedKey) ?? []);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifications = <NotificationEntity>[];

    try {
      // super_admin has no fixed academy — skip player notifications
      if (user.academyId == null) return [];

      // اسم الأكاديمية (يُجلب مرة واحدة) لاستخدامه في رسائل WhatsApp.
      String academyName = 'الأكاديمية';
      try {
        final acad =
            await sl<AcademyRemoteDatasource>().getAcademyById(user.academyId!);
        if (acad.name.isNotEmpty) academyName = acad.name;
      } catch (_) {}

      final playerDs = sl<PlayerRemoteDatasource>();
      final playerResult = await playerDs.getPlayers(
        academyId: user.academyId,
        limit: 300,
      );

      final playerNameMap = <String, String>{};
      final playerCodeMap = <String, String>{};
      final parentPhoneMap = <String, String>{};
      final tomorrow = today.add(const Duration(days: 1));
      for (final model in playerResult.players) {
        final p = model.toEntity();
        playerNameMap[p.id] = p.fullName;
        playerCodeMap[p.id] = p.playerCode;
        parentPhoneMap[p.id] = p.parentPhone;

        final playerLabel = '${p.playerCode} - ${p.fullName}';

        // إشعار عيد الميلاد اليوم
        if (p.birthDate.month == now.month && p.birthDate.day == now.day) {
          final id = 'birthday_${p.id}_${now.year}';
          if (!deletedIds.contains(id)) {
            notifications.add(NotificationEntity(
              id: id,
              type: NotificationType.birthday,
              title: 'عيد ميلاد سعيد 🎂',
              body: '$playerLabel\nعيد ميلاد اللاعب اليوم',
              createdAt: DateTime(now.year, now.month, now.day, 8, 0),
              isRead: readIds.contains(id),
              playerId: p.id,
              parentPhone: p.parentPhone,
              playerName: p.fullName,
              academyName: academyName,
            ));
          }
        }

        // إشعار عيد الميلاد غداً
        if (p.birthDate.month == tomorrow.month && p.birthDate.day == tomorrow.day) {
          final id = 'birthday_tomorrow_${p.id}_${now.year}';
          if (!deletedIds.contains(id)) {
            notifications.add(NotificationEntity(
              id: id,
              type: NotificationType.birthday,
              title: 'عيد ميلاد قادم 🎂',
              body: '$playerLabel\nعيد ميلاد اللاعب غداً',
              createdAt: DateTime(now.year, now.month, now.day, 8, 0),
              isRead: readIds.contains(id),
              playerId: p.id,
              parentPhone: p.parentPhone,
              playerName: p.fullName,
              academyName: academyName,
            ));
          }
        }
      }

      // إشعارات الاشتراكات — فقط لغير admin (admin لا يملك صلاحية academy endpoint)
      if (!user.isAdmin && user.academyId != null) {
        final subDs = sl<SubscriptionRemoteDatasource>();
        final subResult = await subDs.getSubscriptionsByAcademy(
          academyId: user.academyId!,
          limit: 300,
        );

        // الاشتراك الأحدث لكل لاعب
        final latestByPlayer = <String, SubscriptionModel>{};
        for (final sub in subResult.subscriptions) {
          final existing = latestByPlayer[sub.playerId];
          if (existing == null || sub.endDate.isAfter(existing.endDate)) {
            latestByPlayer[sub.playerId] = sub;
          }
        }

        for (final sub in latestByPlayer.values) {
          final endDay = DateTime(sub.endDate.year, sub.endDate.month, sub.endDate.day);
          final daysLeft = endDay.difference(today).inDays;

          final playerName = sub.playerName.isNotEmpty
              ? sub.playerName
              : (playerNameMap[sub.playerId] ?? 'اللاعب');
          final playerCode = playerCodeMap[sub.playerId] ?? '';
          final playerLabel = playerCode.isNotEmpty
              ? '$playerCode - $playerName'
              : playerName;

          NotificationEntity? notif;

          if (daysLeft > 3 && daysLeft <= 7) {
            final id = 'sub_exp7_${sub.id}';
            if (!deletedIds.contains(id)) {
              notif = NotificationEntity(
                id: id,
                type: NotificationType.subscriptionExpiring,
                title: 'اشتراك يقترب من الانتهاء ⚠️',
                body: '$playerLabel\nالاشتراك سينتهي خلال 7 أيام.',
                createdAt: today,
                isRead: readIds.contains(id),
                playerId: sub.playerId,
                parentPhone: parentPhoneMap[sub.playerId],
                playerName: playerName,
                academyName: academyName,
              );
            }
          } else if (daysLeft >= 1 && daysLeft <= 3) {
            final id = 'sub_exp3_${sub.id}';
            if (!deletedIds.contains(id)) {
              notif = NotificationEntity(
                id: id,
                type: NotificationType.subscriptionExpiring,
                title: 'اشتراك سينتهي قريباً ⚠️',
                body:
                    '$playerLabel\nالاشتراك سينتهي خلال $daysLeft ${daysLeft == 1 ? "يوم" : "أيام"}.',
                createdAt: today,
                isRead: readIds.contains(id),
                playerId: sub.playerId,
                parentPhone: parentPhoneMap[sub.playerId],
                playerName: playerName,
                academyName: academyName,
              );
            }
          } else if (daysLeft == 0) {
            final id = 'sub_exptoday_${sub.id}';
            if (!deletedIds.contains(id)) {
              notif = NotificationEntity(
                id: id,
                type: NotificationType.subscriptionExpired,
                title: 'انتهاء اشتراك اليوم 🚨',
                body: '$playerLabel\nانتهى الاشتراك اليوم.',
                createdAt: today,
                isRead: readIds.contains(id),
                playerId: sub.playerId,
                parentPhone: parentPhoneMap[sub.playerId],
                playerName: playerName,
                academyName: academyName,
              );
            }
          } else if (daysLeft < 0 && daysLeft >= -30) {
            final id = 'sub_expired_${sub.id}';
            if (!deletedIds.contains(id)) {
              notif = NotificationEntity(
                id: id,
                type: NotificationType.subscriptionExpired,
                title: 'اشتراك منتهي ❌',
                body: '$playerLabel\nالاشتراك منتهي.',
                createdAt: endDay,
                isRead: readIds.contains(id),
                playerId: sub.playerId,
                parentPhone: parentPhoneMap[sub.playerId],
                playerName: playerName,
                academyName: academyName,
              );
            }
          }

          if (notif != null) notifications.add(notif);
        }
      }
    } catch (_) {
      // الإشعارات لا تكسر التطبيق
    }

    notifications.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });

    // Store in cache
    _cache = notifications;
    _cacheTime = DateTime.now();
    _cacheUserId = user.id;

    return notifications;
  }

  Future<void> refresh() async {
    // Bypass cache — explicit user-triggered reload
    _cache = null;
    _cacheTime = null;
    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadNotifications(user));
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = Set<String>.from(prefs.getStringList(_readKey) ?? []);
    readIds.add(id);
    await prefs.setStringList(_readKey, readIds.toList());

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.valueOrNull ?? [];
    final allIds = current.map((n) => n.id).toList();
    await prefs.setStringList(_readKey, allIds);

    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = Set<String>.from(prefs.getStringList(_deletedKey) ?? []);
    deletedIds.add(id);
    await prefs.setStringList(_deletedKey, deletedIds.toList());

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((n) => n.id != id).toList());
  }

  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.valueOrNull ?? [];
    final deletedIds = Set<String>.from(prefs.getStringList(_deletedKey) ?? []);
    for (final n in current) {
      deletedIds.add(n.id);
    }
    await prefs.setStringList(_deletedKey, deletedIds.toList());
    state = const AsyncValue.data([]);
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, List<NotificationEntity>>(
  NotificationNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationProvider).valueOrNull ?? [];
  return list.where((n) => !n.isRead).length;
});
