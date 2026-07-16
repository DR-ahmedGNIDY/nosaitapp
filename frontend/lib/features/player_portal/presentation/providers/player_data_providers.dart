import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player_portal/data/player_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// لوحة اللاعب المجمّعة (جدول/حضور/اشتراك/تقييمات/إشعارات).
final playerDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return sl<PlayerApiService>().dashboard();
});

/// إشعارات اللاعب (قائمة + عدد غير مقروء).
final playerNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return sl<PlayerApiService>().notifications();
});
