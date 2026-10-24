import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/player/domain/usecases/get_players_usecase.dart';

/// Returns the set of player ids matching the [sport] and/or [groupId] scope
/// within [academyId], fetched in a SINGLE query (no per-filter requests).
///
/// Sport and Group are INDEPENDENT dimensions — passing both returns the
/// intersection (e.g. "Basketball players inside Group A"). Returns `null`
/// when neither sport nor group is set, meaning "all academy players" —
/// callers then skip filtering entirely. Used by the PDF and Excel report
/// services to scope subscriptions / evaluations / revenue by player id.
Future<Set<String>?> playerIdsForSport(
  String? academyId,
  String? sport, [
  String? groupId,
]) async {
  final hasSport = sport != null && sport.isNotEmpty;
  final hasGroup = groupId != null && groupId.isNotEmpty;
  if (academyId == null || (!hasSport && !hasGroup)) return null;
  final res = await sl<GetPlayersUsecase>()(
    GetPlayersParams(
      academyId: academyId,
      sport: hasSport ? sport : null,
      groupId: hasGroup ? groupId : null,
      page: 1,
      limit: 500,
    ),
  );
  return res.fold(
    (_) => <String>{},
    (r) => r.players.map((p) => p.id).toSet(),
  );
}

/// إيرادات اشتراكات المباريات المضافة للإيرادات (بتاريخ الدفع) لرياضة معيّنة —
/// إجمالي + الشهر الحالي. تُستخدم في تقرير الإيرادات عند فلترة الرياضة، لأن
/// الإيرادات هناك تُجمع على الجهاز من الاشتراكات. بلا academyId ⇒ صفر.
Future<({double total, double month})> matchRevenueForReport(
  String? academyId,
  String? sport,
) async {
  if (academyId == null) return (total: 0.0, month: 0.0);
  final api = sl<ApiClient>();
  final now = DateTime.now();
  String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  Future<double> fetch(Map<String, dynamic> extra) async {
    try {
      final res = await api.get<Map<String, dynamic>>('/matches/revenue', queryParameters: {
        'academyId': academyId,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        ...extra,
      });
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      return (data?['total'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      return 0; // سيرفر أقدم بلا هذا المسار ⇒ لا نكسر التقرير.
    }
  }

  final results = await Future.wait([
    fetch(const {}),
    fetch({
      'startDate': ymd(DateTime(now.year, now.month, 1)),
      'endDate': ymd(DateTime(now.year, now.month + 1, 0)),
    }),
  ]);
  return (total: results[0], month: results[1]);
}
