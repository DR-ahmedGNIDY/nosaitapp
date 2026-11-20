import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// طلب تسجيل لاعب من الفورم الأونلاين.
class RegistrationRequestEntity {
  final String id;
  final String playerName;
  final DateTime? birthDate;
  final String sport;
  final String parentName;
  final String parentRelationship;
  final String parentPhone;
  final String playerPhone;
  final String notes;
  final String status; // pending | accepted | rejected
  final String rejectReason;
  final String? playerId;
  final String handledByName;
  final DateTime createdAt;

  const RegistrationRequestEntity({
    required this.id,
    required this.playerName,
    required this.birthDate,
    required this.sport,
    required this.parentName,
    required this.parentRelationship,
    required this.parentPhone,
    required this.playerPhone,
    required this.notes,
    required this.status,
    required this.rejectReason,
    required this.playerId,
    required this.handledByName,
    required this.createdAt,
  });

  int? get age {
    final b = birthDate;
    if (b == null) return null;
    final now = DateTime.now();
    var a = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) a--;
    return a;
  }

  factory RegistrationRequestEntity.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString();
    DateTime? d(String k) => j[k] is String ? DateTime.tryParse(j[k] as String)?.toLocal() : null;
    return RegistrationRequestEntity(
      id: s('_id'),
      playerName: s('playerName'),
      birthDate: d('birthDate'),
      sport: s('sport'),
      parentName: s('parentName'),
      parentRelationship: s('parentRelationship'),
      parentPhone: s('parentPhone'),
      playerPhone: s('playerPhone'),
      notes: s('notes'),
      status: s('status'),
      rejectReason: s('rejectReason'),
      playerId: j['playerId'] as String?,
      handledByName: s('handledByName'),
      createdAt: d('created_at') ?? DateTime.now(),
    );
  }
}

/// إعدادات الفورم الأونلاين للأكاديمية.
class OnlineRegistrationSettings {
  final bool enabled;
  final String? url;
  final List<String> sports;
  final String welcomeMessage;
  final List<String> academySports;
  final int pendingCount;

  const OnlineRegistrationSettings({
    required this.enabled,
    required this.url,
    required this.sports,
    required this.welcomeMessage,
    required this.academySports,
    required this.pendingCount,
  });

  factory OnlineRegistrationSettings.fromJson(Map<String, dynamic> j) {
    List<String> list(String k) => (j[k] as List? ?? const []).map((e) => e.toString()).toList();
    return OnlineRegistrationSettings(
      enabled: j['enabled'] == true,
      url: j['url'] as String?,
      sports: list('sports'),
      welcomeMessage: (j['welcomeMessage'] ?? '').toString(),
      academySports: list('academySports'),
      pendingCount: (j['pendingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// نتيجة قبول طلب: اللاعب الجديد + حساب البوابة (إن أُنشئ).
class AcceptResult {
  final String playerId;
  final String playerName;
  final String? username;
  final String? password;

  const AcceptResult({required this.playerId, required this.playerName, this.username, this.password});
}

class OnlineRegistrationApi {
  OnlineRegistrationApi._();

  static ApiClient get _api => sl<ApiClient>();

  static Future<T> _wrap<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AppException catch (e) {
      throw Exception(e.message);
    }
  }

  static Map<String, dynamic>? _q(String? academyId) =>
      academyId == null ? null : {'academyId': academyId};

  static Future<OnlineRegistrationSettings> settings(String? academyId) => _wrap(() async {
        final res = await _api.get<Map<String, dynamic>>('/registration-requests/settings',
            queryParameters: _q(academyId));
        return OnlineRegistrationSettings.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
      });

  static Future<OnlineRegistrationSettings> updateSettings(
    String? academyId, {
    bool? enabled,
    List<String>? sports,
    String? welcomeMessage,
    bool regenerate = false,
  }) =>
      _wrap(() async {
        final res = await _api.patch<Map<String, dynamic>>(
          '/registration-requests/settings',
          data: {
            if (academyId != null) 'academyId': academyId,
            if (enabled != null) 'enabled': enabled,
            if (sports != null) 'sports': sports,
            if (welcomeMessage != null) 'welcomeMessage': welcomeMessage,
            if (regenerate) 'regenerate': true,
          },
        );
        return OnlineRegistrationSettings.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
      });

  static Future<({List<RegistrationRequestEntity> items, Map<String, int> counts})> list(
          String? academyId, String status) =>
      _wrap(() async {
        final res = await _api.get<Map<String, dynamic>>('/registration-requests',
            queryParameters: {'status': status, ...?_q(academyId)});
        final data = (res.data as Map)['data'] as Map<String, dynamic>;
        final items = (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => RegistrationRequestEntity.fromJson(e.cast<String, dynamic>()))
            .toList();
        final counts = ((data['counts'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
        return (items: items, counts: counts);
      });

  static Future<AcceptResult> accept(String id, {String? academyId}) => _wrap(() async {
        final res = await _api.post<Map<String, dynamic>>('/registration-requests/$id/accept',
            data: {if (academyId != null) 'academyId': academyId}, queryParameters: _q(academyId));
        final body = res.data as Map<String, dynamic>;
        final player = (body['data'] as Map).cast<String, dynamic>();
        final account = (body['account'] as Map?)?.cast<String, dynamic>();
        return AcceptResult(
          playerId: (player['_id'] ?? player['id'] ?? '').toString(),
          playerName: (player['fullName'] ?? '').toString(),
          username: account?['username'] as String?,
          password: account?['password'] as String?,
        );
      });

  static Future<void> reject(String id, {String reason = '', String? academyId}) => _wrap(() async {
        await _api.post('/registration-requests/$id/reject',
            data: {'reason': reason, if (academyId != null) 'academyId': academyId},
            queryParameters: _q(academyId));
      });
}

/// إعدادات الفورم (null academyId = أكاديمية المستخدم).
final onlineRegistrationSettingsProvider =
    FutureProvider.autoDispose.family<OnlineRegistrationSettings, String?>(
        (ref, academyId) => OnlineRegistrationApi.settings(academyId));

/// طلبات حسب الحالة.
final registrationRequestsProvider = FutureProvider.autoDispose.family<
    ({List<RegistrationRequestEntity> items, Map<String, int> counts}),
    ({String? academyId, String status})>(
  (ref, q) => OnlineRegistrationApi.list(q.academyId, q.status),
);
