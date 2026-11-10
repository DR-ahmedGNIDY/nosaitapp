import 'dart:async';

import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:basketball_academy/features/notification/domain/entities/notification_entity.dart';
import 'package:basketball_academy/features/player/data/datasources/player_remote_datasource.dart';
import 'package:basketball_academy/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:basketball_academy/features/subscription/data/models/subscription_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مركز إشعارات الإدارة = مصدران:
/// 1. **السيرفر** (`/notifications`): رسائل اللاعبين، تعليقات الألبوم… طلب خفيف
///    يُعاد عند فتح الشاشة، عودة التطبيق للمقدمة، ووصول Push والتطبيق مفتوح.
/// 2. **محلي** (أعياد الميلاد وانتهاء الاشتراكات): حساب ثقيل (لاعبين + اشتراكات)
///    يُحسب في الخلفية ويُخزَّن [_localTtl]، فلا يؤخّر فتح الشاشة.
class NotificationNotifier extends AsyncNotifier<List<NotificationEntity>> {
  static const _readKey = 'notification_read_ids';
  static const _deletedKey = 'notification_deleted_ids';
  static const _localTtl = Duration(minutes: 2);
  static const _serverMinGap = Duration(seconds: 3);

  List<NotificationEntity> _server = const [];
  List<NotificationEntity>? _local;
  DateTime? _localTime;
  DateTime? _serverTime;
  String? _userId;
  Future<void>? _localJob;

  @override
  Future<List<NotificationEntity>> build() async {
    final userId = ref.watch(
      authStateProvider.select((s) => s.valueOrNull?.user?.id),
    );
    if (userId != _userId) {
      _server = const [];
      _local = null;
      _localTime = null;
      _serverTime = null;
      _userId = userId;
    }
    if (userId == null) return [];
    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null || user.academyId == null) return [];

    _server = await _fetchServer();
    _serverTime = DateTime.now();
    if (!_localFresh) _computeLocalInBackground(user);
    return _merged();
  }

  bool get _localFresh =>
      _local != null &&
      _localTime != null &&
      DateTime.now().difference(_localTime!) < _localTtl;

  List<NotificationEntity> _merged() {
    final all = [..._server, ...?_local];
    all.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return all;
  }

  Future<List<NotificationEntity>> _fetchServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = Set<String>.from(prefs.getStringList(_deletedKey) ?? []);
      final res = await sl<ApiClient>().get<Map<String, dynamic>>('/notifications');
      final data = (res.data?['data'] as Map?) ?? const {};
      final items = (data['items'] as List?) ?? const [];
      return items
          .whereType<Map>()
          .map((m) => NotificationEntity.fromServerJson(Map<String, dynamic>.from(m)))
          .where((n) => !deletedIds.contains(n.id))
          .toList();
    } catch (_) {
      return _server; // نُبقي آخر نسخة عند فشل الشبكة
    }
  }

  void _computeLocalInBackground(UserEntity user) {
    _localJob ??= () async {
      try {
        final list = await _loadLocal(user);
        if (_userId != user.id) return; // تغيّر المستخدم أثناء الحساب
        _local = list;
        _localTime = DateTime.now();
        state = AsyncValue.data(_merged());
      } finally {
        _localJob = null;
      }
    }();
  }

  /// تحديث خفيف لإشعارات السيرفر فقط (بدون مؤشر تحميل).
  Future<void> refreshServer() async {
    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null || user.academyId == null) return;
    if (_serverTime != null &&
        DateTime.now().difference(_serverTime!) < _serverMinGap) {
      return;
    }
    _serverTime = DateTime.now();
    _server = await _fetchServer();
    if (!_localFresh) _computeLocalInBackground(user);
    state = AsyncValue.data(_merged());
  }

  Future<List<NotificationEntity>> _loadLocal(UserEntity user) async {
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
    return notifications;
  }

  /// إعادة تحميل كاملة (سحب للتحديث / زر التحديث).
  Future<void> refresh() async {
    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null || user.academyId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final results = await Future.wait([_fetchServer(), _loadLocal(user)]);
      _server = results[0];
      _local = results[1];
      _serverTime = _localTime = DateTime.now();
      return _merged();
    });
  }

  void _apply(NotificationEntity Function(NotificationEntity) f) {
    _server = _server.map(f).toList();
    _local = _local?.map(f).toList();
    state = AsyncValue.data(_merged());
  }

  Future<void> markAsRead(String id) async {
    final target = (state.valueOrNull ?? const <NotificationEntity>[])
        .where((n) => n.id == id)
        .firstOrNull;
    if (target == null || target.isRead) return;
    _apply((n) => n.id == id ? n.copyWith(isRead: true) : n);
    if (target.fromServer) {
      try {
        await sl<ApiClient>().patch('/notifications/$id/read');
      } catch (_) {}
    } else {
      final prefs = await SharedPreferences.getInstance();
      final readIds = Set<String>.from(prefs.getStringList(_readKey) ?? []);
      readIds.add(id);
      await prefs.setStringList(_readKey, readIds.toList());
    }
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = Set<String>.from(prefs.getStringList(_readKey) ?? []);
    readIds.addAll((_local ?? const []).map((n) => n.id));
    await prefs.setStringList(_readKey, readIds.toList());
    final hadServerUnread = _server.any((n) => !n.isRead);
    _apply((n) => n.copyWith(isRead: true));
    if (hadServerUnread) {
      try {
        await sl<ApiClient>().patch('/notifications/read-all');
      } catch (_) {}
    }
  }

  Future<void> _addDeleted(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = Set<String>.from(prefs.getStringList(_deletedKey) ?? []);
    deletedIds.addAll(ids);
    await prefs.setStringList(_deletedKey, deletedIds.toList());
  }

  Future<void> deleteNotification(String id) async {
    await _addDeleted([id]);
    _server = _server.where((n) => n.id != id).toList();
    _local = _local?.where((n) => n.id != id).toList();
    state = AsyncValue.data(_merged());
  }

  Future<void> deleteAll() async {
    await _addDeleted((state.valueOrNull ?? const []).map((n) => n.id));
    _server = const [];
    _local = const [];
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
