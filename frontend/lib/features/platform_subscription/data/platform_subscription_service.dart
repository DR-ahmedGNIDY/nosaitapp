import 'package:basketball_academy/core/network/api_client.dart';

/// خدمة إدارة اشتراكات المنصة (Super Admin فقط).
class PlatformSubscriptionService {
  final ApiClient _api;
  PlatformSubscriptionService(this._api);

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get<Map<String, dynamic>>('/platform/subscriptions');
    final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> activate({
    required String academyId,
    required String plan, // 'month' | 'year'
    required int maxPlayers,
    int? durationMonths, // 1 | 3 | 6 | 12 — يحسب منه Backend تاريخ النهاية
    bool? playerPortalEnabled,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/platform/subscriptions/$academyId/activate',
      data: {
        'plan': plan,
        'maxPlayers': maxPlayers,
        if (durationMonths != null) 'durationMonths': durationMonths,
        if (playerPortalEnabled != null) 'playerPortalEnabled': playerPortalEnabled,
      },
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  /// تبديل سريع لميزة بوابة اللاعب دون تغيير الاشتراك.
  Future<Map<String, dynamic>> setPlayerPortal({
    required String academyId,
    required bool enabled,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/platform/subscriptions/$academyId/player-portal',
      data: {'enabled': enabled},
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update({
    required String academyId,
    String? plan,
    int? maxPlayers,
    int? durationMonths, // 1 | 3 | 6 | 12 — يُعاد حساب تاريخ النهاية منه
    String? status,
    bool? playerPortalEnabled,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/platform/subscriptions/$academyId',
      data: {
        if (plan != null) 'plan': plan,
        if (maxPlayers != null) 'maxPlayers': maxPlayers,
        if (durationMonths != null) 'durationMonths': durationMonths,
        if (status != null) 'status': status,
        if (playerPortalEnabled != null) 'playerPortalEnabled': playerPortalEnabled,
      },
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> history(String academyId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/platform/subscriptions/$academyId/history',
    );
    final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
