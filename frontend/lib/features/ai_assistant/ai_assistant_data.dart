import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/network/api_client.dart';

/// حالة المساعد الذكي لأكاديمية المدير (ميزة مدفوعة بحد يومي).
class AiStatus {
  final bool enabled;
  final bool blockedBySubscription;
  final bool configured;
  final int dailyLimit;
  final int usedToday;
  final int remainingToday;

  const AiStatus({
    required this.enabled,
    required this.blockedBySubscription,
    required this.configured,
    required this.dailyLimit,
    required this.usedToday,
    required this.remainingToday,
  });

  factory AiStatus.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return AiStatus(
      enabled: j['enabled'] == true,
      blockedBySubscription: j['blockedBySubscription'] == true,
      configured: j['configured'] == true,
      dailyLimit: n('dailyLimit'),
      usedToday: n('usedToday'),
      remainingToday: n('remainingToday'),
    );
  }

  AiStatus withUsage(int used, int limit, int remaining) => AiStatus(
        enabled: enabled,
        blockedBySubscription: blockedBySubscription,
        configured: configured,
        dailyLimit: limit,
        usedToday: used,
        remainingToday: remaining,
      );
}

class AiMessage {
  final String id;
  final String role; // user | assistant
  final String content;
  final bool reported;

  const AiMessage({required this.id, required this.role, required this.content, this.reported = false});

  bool get isUser => role == 'user';

  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
        id: (j['_id'] ?? '').toString(),
        role: (j['role'] ?? 'assistant').toString(),
        content: (j['content'] ?? '').toString(),
        reported: j['reported'] == true,
      );

  AiMessage copyWith({bool? reported}) =>
      AiMessage(id: id, role: role, content: content, reported: reported ?? this.reported);
}

class AiAssistantApi {
  AiAssistantApi._();

  static ApiClient get _api => sl<ApiClient>();

  static Future<T> _wrap<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AppException catch (e) {
      throw Exception(e.message);
    }
  }

  static Map<String, dynamic> _data(dynamic body) =>
      ((body as Map)['data'] as Map).cast<String, dynamic>();

  static Future<AiStatus> status() => _wrap(() async {
        final res = await _api.get<Map<String, dynamic>>('/assistant/status');
        return AiStatus.fromJson(_data(res.data));
      });

  static Future<List<AiMessage>> conversation() => _wrap(() async {
        final res = await _api.get<Map<String, dynamic>>('/assistant/conversation');
        return (_data(res.data)['messages'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => AiMessage.fromJson(m.cast<String, dynamic>()))
            .toList();
      });

  /// يرجّع رد المساعد + الاستهلاك المحدّث.
  static Future<({AiMessage reply, int used, int limit, int remaining})> send(String text) =>
      _wrap(() async {
        final res = await _api.post<Map<String, dynamic>>('/assistant/chat', data: {'message': text});
        final d = _data(res.data);
        final usage = ((d['usage'] as Map?) ?? const {}).cast<String, dynamic>();
        int n(String k) => (usage[k] as num?)?.toInt() ?? 0;
        return (
          reply: AiMessage.fromJson(((d['reply'] as Map?) ?? const {}).cast<String, dynamic>()),
          used: n('usedToday'),
          limit: n('dailyLimit'),
          remaining: n('remainingToday'),
        );
      });

  static Future<void> reset() => _wrap(() async {
        await _api.delete('/assistant/conversation');
      });

  static Future<void> report(String messageId, String reason) => _wrap(() async {
        await _api.post('/assistant/messages/$messageId/report', data: {'reason': reason});
      });
}
