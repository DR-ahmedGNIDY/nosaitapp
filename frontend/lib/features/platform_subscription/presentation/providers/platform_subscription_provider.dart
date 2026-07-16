import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/platform_subscription/data/platform_subscription_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// قائمة كل الأكاديميات وحالات اشتراكاتها (Super Admin).
final platformSubscriptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return sl<PlatformSubscriptionService>().list();
});
