import 'dart:async';

import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player_portal/data/player_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// لوحة اللاعب المجمّعة (جدول/حضور/اشتراك/تقييمات/إشعارات).
/// تحديث تلقائي كل دقيقة أثناء فتح الشاشة — ليظهر عدّاد الإشعارات الجديدة
/// (مثل "تم تسجيل حضورك") بدون أن يعيد اللاعب فتح التطبيق.
const _kPlayerAutoRefresh = Duration(seconds: 60);

void _autoRefresh(Ref ref) {
  final timer = Timer(_kPlayerAutoRefresh, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}

final playerDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  _autoRefresh(ref);
  return sl<PlayerApiService>().dashboard();
});

/// إشعارات اللاعب (قائمة + عدد غير مقروء).
final playerNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  _autoRefresh(ref);
  return sl<PlayerApiService>().notifications();
});
