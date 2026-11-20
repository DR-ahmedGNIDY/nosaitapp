import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// قوالب الإحصائيات تأتي من السيرفر (utils/matchStatsCatalog) — الواجهة تبني
// الحقول منها، فإضافة رياضة/حقل جديد لا تحتاج تعديل التطبيق.

class StatOption {
  final String value;
  final String label;
  const StatOption(this.value, this.label);
}

class StatField {
  final String key;
  final String label;
  final String kind; // count | percent | bool | time | select
  final String agg; // sum | avg | tally | none
  final bool leader;
  final List<StatOption> options;

  const StatField({
    required this.key,
    required this.label,
    required this.kind,
    required this.agg,
    required this.leader,
    required this.options,
  });

  factory StatField.fromJson(Map<String, dynamic> j) => StatField(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        kind: (j['kind'] ?? 'count').toString(),
        agg: (j['agg'] ?? 'none').toString(),
        leader: j['leader'] == true,
        options: (j['options'] as List? ?? const [])
            .whereType<Map>()
            .map((o) => StatOption(o['value'].toString(), o['label'].toString()))
            .toList(),
      );

  String optionLabel(Object? v) =>
      options.where((o) => o.value == v).map((o) => o.label).firstOrNull ?? '';
}

class StatTemplate {
  final String key;
  final String type; // team | individual
  final String label;
  final String sport;
  final List<StatField> fields;

  const StatTemplate({
    required this.key,
    required this.type,
    required this.label,
    required this.sport,
    required this.fields,
  });

  bool get isTeam => type == 'team';

  factory StatTemplate.fromJson(Map<String, dynamic> j) => StatTemplate(
        key: (j['key'] ?? '').toString(),
        type: (j['type'] ?? 'individual').toString(),
        label: (j['label'] ?? '').toString(),
        sport: (j['sport'] ?? '').toString(),
        fields: (j['fields'] as List? ?? const [])
            .whereType<Map>()
            .map((f) => StatField.fromJson(f.cast<String, dynamic>()))
            .toList(),
      );

  /// سطر مختصر لأبرز الأرقام (للقوائم): "24 نقاط • 8 ريباوند".
  String shortLine(Map<String, dynamic> stats, {int max = 3}) {
    final parts = <String>[];
    for (final f in fields) {
      final v = stats[f.key];
      if (v == null) continue;
      if (f.kind == 'count' && v is num && v > 0) {
        parts.add('${v.toInt()} ${f.label}');
      } else if (f.kind == 'percent' && v is num) {
        parts.add('${f.label} ${v.toInt()}%');
      } else if (f.kind == 'select') {
        final l = f.optionLabel(v);
        if (l.isNotEmpty) parts.add(l);
      } else if (f.kind == 'time' && v.toString().isNotEmpty) {
        parts.add('${f.label}: $v');
      } else if (f.kind == 'bool' && v == true) {
        parts.add(f.label);
      }
      if (parts.length >= max) break;
    }
    return parts.join(' • ');
  }
}

num? _num(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

class MatchStatsRow {
  final String playerId;
  final String fullName;
  final String playerCode;
  final String? imageUrl;
  final Map<String, dynamic> stats;
  final double? rating;
  final bool mvp;
  final String notes;
  final bool recorded;

  const MatchStatsRow({
    required this.playerId,
    required this.fullName,
    required this.playerCode,
    required this.imageUrl,
    required this.stats,
    required this.rating,
    required this.mvp,
    required this.notes,
    required this.recorded,
  });

  factory MatchStatsRow.fromJson(Map<String, dynamic> j) => MatchStatsRow(
        playerId: (j['playerId'] ?? '').toString(),
        fullName: (j['fullName'] ?? '').toString(),
        playerCode: (j['playerCode'] ?? '').toString(),
        imageUrl: j['image_url'] as String?,
        stats: ((j['stats'] as Map?) ?? const {}).cast<String, dynamic>(),
        rating: _num(j['rating'])?.toDouble(),
        mvp: j['mvp'] == true,
        notes: (j['notes'] ?? '').toString(),
        recorded: j['recorded'] == true,
      );
}

class MatchStatsData {
  final String matchId;
  final String name;
  final String date;
  final String sport;
  final String opponent;
  final int? ourScore;
  final int? theirScore;
  final bool recorded;
  final StatTemplate template;
  final List<MatchStatsRow> rows;

  const MatchStatsData({
    required this.matchId,
    required this.name,
    required this.date,
    required this.sport,
    required this.opponent,
    required this.ourScore,
    required this.theirScore,
    required this.recorded,
    required this.template,
    required this.rows,
  });

  factory MatchStatsData.fromJson(Map<String, dynamic> j) {
    final m = ((j['match'] as Map?) ?? const {}).cast<String, dynamic>();
    return MatchStatsData(
      matchId: (m['_id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      date: (m['date'] ?? '').toString(),
      sport: (m['sport'] ?? '').toString(),
      opponent: (m['opponent'] ?? '').toString(),
      ourScore: _num(m['ourScore'])?.toInt(),
      theirScore: _num(m['theirScore'])?.toInt(),
      recorded: m['statsRecordedAt'] != null,
      template: StatTemplate.fromJson(((j['template'] as Map?) ?? const {}).cast<String, dynamic>()),
      rows: (j['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((r) => MatchStatsRow.fromJson(r.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class PlayerMatchLine {
  final String matchId;
  final String matchName;
  final String date;
  final String opponent;
  final int? ourScore;
  final int? theirScore;
  final Map<String, dynamic> stats;
  final double? rating;
  final bool mvp;

  const PlayerMatchLine({
    required this.matchId,
    required this.matchName,
    required this.date,
    required this.opponent,
    required this.ourScore,
    required this.theirScore,
    required this.stats,
    required this.rating,
    required this.mvp,
  });

  String? get score => ourScore == null || theirScore == null ? null : '$ourScore - $theirScore';

  factory PlayerMatchLine.fromJson(Map<String, dynamic> j) => PlayerMatchLine(
        matchId: (j['matchId'] ?? '').toString(),
        matchName: (j['matchName'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        opponent: (j['opponent'] ?? '').toString(),
        ourScore: _num(j['ourScore'])?.toInt(),
        theirScore: _num(j['theirScore'])?.toInt(),
        stats: ((j['stats'] as Map?) ?? const {}).cast<String, dynamic>(),
        rating: _num(j['rating'])?.toDouble(),
        mvp: j['mvp'] == true,
      );
}

class PlayerStatsData {
  final String playerId;
  final String playerName;
  final String sport;
  final StatTemplate template;
  final int matches;
  final int mvpCount;
  final double? avgRating;

  /// key → {total, avg} | {avg} | {tally: {value: count}}
  final Map<String, Map<String, dynamic>> fields;
  final List<PlayerMatchLine> recent;
  final PlayerMatchLine? best;

  const PlayerStatsData({
    required this.playerId,
    required this.playerName,
    required this.sport,
    required this.template,
    required this.matches,
    required this.mvpCount,
    required this.avgRating,
    required this.fields,
    required this.recent,
    required this.best,
  });

  factory PlayerStatsData.fromJson(Map<String, dynamic> j) {
    final p = ((j['player'] as Map?) ?? const {}).cast<String, dynamic>();
    final s = ((j['summary'] as Map?) ?? const {}).cast<String, dynamic>();
    final f = ((s['fields'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k.toString(), ((v as Map?) ?? const {}).cast<String, dynamic>()),
    );
    return PlayerStatsData(
      playerId: (p['_id'] ?? '').toString(),
      playerName: (p['fullName'] ?? '').toString(),
      sport: (p['sport'] ?? '').toString(),
      template: StatTemplate.fromJson(((j['template'] as Map?) ?? const {}).cast<String, dynamic>()),
      matches: _num(s['matches'])?.toInt() ?? 0,
      mvpCount: _num(s['mvpCount'])?.toInt() ?? 0,
      avgRating: _num(s['avgRating'])?.toDouble(),
      fields: f,
      recent: (j['recent'] as List? ?? const [])
          .whereType<Map>()
          .map((r) => PlayerMatchLine.fromJson(r.cast<String, dynamic>()))
          .toList(),
      best: j['best'] is Map ? PlayerMatchLine.fromJson((j['best'] as Map).cast<String, dynamic>()) : null,
    );
  }
}

class LeaderRow {
  final String playerId;
  final String fullName;
  final String? imageUrl;
  final double value;
  final int matches;
  const LeaderRow(this.playerId, this.fullName, this.imageUrl, this.value, this.matches);
}

class LeaderboardData {
  final String sport;
  final String fieldKey;
  final String fieldLabel;
  final bool isAverage;
  final List<StatOption> fields; // value = key
  final List<LeaderRow> rows;

  const LeaderboardData({
    required this.sport,
    required this.fieldKey,
    required this.fieldLabel,
    required this.isAverage,
    required this.fields,
    required this.rows,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> j) {
    final f = ((j['field'] as Map?) ?? const {}).cast<String, dynamic>();
    return LeaderboardData(
      sport: (j['sport'] ?? '').toString(),
      fieldKey: (f['key'] ?? '').toString(),
      fieldLabel: (f['label'] ?? '').toString(),
      isAverage: f['agg'] == 'avg',
      fields: (j['fields'] as List? ?? const [])
          .whereType<Map>()
          .map((o) => StatOption(o['key'].toString(), o['label'].toString()))
          .toList(),
      rows: (j['rows'] as List? ?? const []).whereType<Map>().map((r) {
        return LeaderRow(
          (r['playerId'] ?? '').toString(),
          (r['fullName'] ?? '').toString(),
          r['image_url'] as String?,
          _num(r['value'])?.toDouble() ?? 0,
          _num(r['matches'])?.toInt() ?? 0,
        );
      }).toList(),
    );
  }
}

/// تنسيق رقم: 17 بدل 17.0 و 7.5 كما هي.
String fmtStat(num? v) {
  if (v == null) return '—';
  return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
}

class MatchStatsApi {
  MatchStatsApi._();

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

  static Future<MatchStatsData> match(String matchId) => _wrap(() async {
        final res = await _api.get<Map<String, dynamic>>('/match-stats/match/$matchId');
        return MatchStatsData.fromJson(_data(res.data));
      });

  static Future<MatchStatsData> save(String matchId, Map<String, dynamic> body) => _wrap(() async {
        final res = await _api.put<Map<String, dynamic>>('/match-stats/match/$matchId', data: body);
        return MatchStatsData.fromJson(_data(res.data));
      });

  /// playerId == null ⇒ بوابة اللاعب (إحصائياتي).
  static Future<PlayerStatsData> player(String? playerId) => _wrap(() async {
        final res = await _api.get<Map<String, dynamic>>(
            playerId == null ? '/player/stats' : '/match-stats/player/$playerId');
        return PlayerStatsData.fromJson(_data(res.data));
      });

  static Future<LeaderboardData> leaderboard(LeaderboardQuery q) => _wrap(() async {
        final res = await _api.get<Map<String, dynamic>>(
          q.portal ? '/player/leaderboard' : '/match-stats/leaderboard',
          queryParameters: {
            if (!q.portal && q.academyId != null && q.academyId!.isNotEmpty) 'academyId': q.academyId,
            if (!q.portal && q.sport != null && q.sport!.isNotEmpty) 'sport': q.sport,
            if (q.field != null && q.field!.isNotEmpty) 'field': q.field,
          },
        );
        return LeaderboardData.fromJson(_data(res.data));
      });
}

typedef LeaderboardQuery = ({bool portal, String? academyId, String? sport, String? field});

final matchStatsProvider =
    FutureProvider.autoDispose.family<MatchStatsData, String>((ref, id) => MatchStatsApi.match(id));

/// null = إحصائياتي (بوابة اللاعب).
final playerMatchStatsProvider = FutureProvider.autoDispose
    .family<PlayerStatsData, String?>((ref, playerId) => MatchStatsApi.player(playerId));

final leaderboardProvider = FutureProvider.autoDispose
    .family<LeaderboardData, LeaderboardQuery>((ref, q) => MatchStatsApi.leaderboard(q));
