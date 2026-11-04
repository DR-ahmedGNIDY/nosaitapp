import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/tournaments/data/tournament_models.dart';

/// لاعب مختصر لشاشة اختيار لاعبي البطولة.
class PickablePlayer {
  final String id;
  final String fullName;
  final String playerCode;
  final String academyId;
  const PickablePlayer(
      {required this.id,
      required this.fullName,
      required this.playerCode,
      required this.academyId});
}

/// حجم صفحة اللاعبين في شاشات اختيار لاعبي البطولة (الحد الأقصى في الخادم 100).
const int playersPageSize = 100;

/// صفحة لاعبين + هل توجد صفحات أخرى.
class PlayersPage {
  final List<PickablePlayer> items;
  final bool hasNext;
  final int? total;
  const PlayersPage({required this.items, required this.hasNext, this.total});
}

/// خدمة البطولات — /api/v1/tournaments (إدارة) و /api/v1/player/tournaments (بوابة اللاعب).
class TournamentsService {
  final ApiClient _api;
  TournamentsService(this._api);

  Map<String, dynamic> _data(dynamic res) =>
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  Future<List<Tournament>> list({String? academyId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/tournaments',
      queryParameters: {
        if (academyId != null && academyId.isNotEmpty) 'academyId': academyId
      },
    );
    return ((res.data as Map<String, dynamic>)['data'] as List? ?? [])
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentDetail> get(String id) async => TournamentDetail.fromJson(
      _data(await _api.get<Map<String, dynamic>>('/tournaments/$id')));

  Future<Tournament> create(Map<String, dynamic> body) async =>
      Tournament.fromJson(_data(
          await _api.post<Map<String, dynamic>>('/tournaments', data: body)));

  Future<Tournament> update(String id, Map<String, dynamic> body) async =>
      Tournament.fromJson(_data(await _api
          .put<Map<String, dynamic>>('/tournaments/$id', data: body)));

  Future<void> delete(String id) => _api.delete('/tournaments/$id');

  Future<void> addParticipant(String id,
          {String? name, required List<String> playerIds, String? captainId}) =>
      _api.post('/tournaments/$id/participants', data: {
        if (name != null) 'name': name,
        'playerIds': playerIds,
        if (captainId != null) 'captainId': captainId,
      });

  Future<void> updateParticipant(String id, String participantId,
          {String? name, List<String>? playerIds, String? captainId}) =>
      _api.put('/tournaments/$id/participants/$participantId', data: {
        if (name != null) 'name': name,
        if (playerIds != null) 'playerIds': playerIds,
        'captainId': captainId,
      });

  Future<void> removeParticipant(String id, String participantId) =>
      _api.delete('/tournaments/$id/participants/$participantId');

  /// توزيع لاعبين على [teamsCount] فرق تلقائياً. mode: random | balanced.
  /// replace=true يحذف الفرق الحالية ويعيد التوزيع من جديد.
  Future<void> autoSplit(
    String id, {
    required List<String> playerIds,
    required int teamsCount,
    String mode = 'random',
    bool replace = false,
  }) =>
      _api.post('/tournaments/$id/participants/auto-split', data: {
        'playerIds': playerIds,
        'teamsCount': teamsCount,
        'mode': mode,
        'replace': replace,
      });

  Future<void> orderParticipants(String id, List<String> order) =>
      _api.put('/tournaments/$id/participants/order', data: {'order': order});

  Future<void> generate(String id) => _api.post('/tournaments/$id/generate');

  Future<void> resetFixtures(String id) =>
      _api.delete('/tournaments/$id/fixtures');

  Future<void> updateFixture(
          String id, String fixtureId, Map<String, dynamic> body) =>
      _api.put('/tournaments/$id/fixtures/$fixtureId', data: body);

  Future<void> recordResult(
          String id, String fixtureId, Map<String, dynamic> body) =>
      _api.post('/tournaments/$id/fixtures/$fixtureId/result', data: body);

  Future<void> clearResult(String id, String fixtureId) =>
      _api.delete('/tournaments/$id/fixtures/$fixtureId/result');

  /// لاعبو فرع معيّن (للاختيار في الفرق) — بحث بالاسم أو الكود.
  Future<List<PickablePlayer>> searchPlayers(
          {required String academyId, String search = ''}) async =>
      (await searchPlayersPage(academyId: academyId, search: search)).items;

  /// صفحة من لاعبي الأكاديمية (100 لاعب لكل صفحة) — لزر "عرض المزيد".
  Future<PlayersPage> searchPlayersPage(
      {required String academyId, String search = '', int page = 1}) async {
    final res =
        await _api.get<Map<String, dynamic>>('/players', queryParameters: {
      'academyId': academyId,
      'limit': playersPageSize,
      'page': page,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List? ?? []).map((e) {
      final j = e as Map<String, dynamic>;
      return PickablePlayer(
        id: (j['_id'] ?? j['id']).toString(),
        fullName: j['fullName']?.toString() ?? '',
        playerCode: j['playerCode']?.toString() ?? '',
        academyId: j['academyId']?.toString() ?? academyId,
      );
    }).toList();
    final meta = body['meta'];
    // لو الخادم لم يرسل meta: صفحة كاملة تعني غالباً أن هناك المزيد.
    final hasNext = meta is Map && meta['hasNext'] is bool
        ? meta['hasNext'] as bool
        : items.length >= playersPageSize;
    final total = meta is Map && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : null;
    return PlayersPage(items: items, hasNext: hasNext, total: total);
  }

  // ── بوابة اللاعب ──
  Future<List<Tournament>> playerList() async {
    final res = await _api.get<Map<String, dynamic>>('/player/tournaments');
    return ((res.data as Map<String, dynamic>)['data'] as List? ?? [])
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentDetail> playerGet(String id) async =>
      TournamentDetail.fromJson(_data(
          await _api.get<Map<String, dynamic>>('/player/tournaments/$id')));
}
