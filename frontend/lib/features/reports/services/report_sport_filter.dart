import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player/domain/usecases/get_players_usecase.dart';

/// Returns the set of player ids belonging to [sport] within [academyId],
/// fetched in a SINGLE query (no per-sport requests → no 429).
///
/// Returns `null` when [sport] is null/empty, meaning "all sports" — callers
/// then skip filtering entirely. Used by the PDF and Excel report services to
/// scope subscriptions / evaluations / revenue to one sport by player id.
Future<Set<String>?> playerIdsForSport(String? academyId, String? sport) async {
  if (sport == null || sport.isEmpty || academyId == null) return null;
  final res = await sl<GetPlayersUsecase>()(
    GetPlayersParams(academyId: academyId, sport: sport, page: 1, limit: 500),
  );
  return res.fold(
    (_) => <String>{},
    (r) => r.players.map((p) => p.id).toSet(),
  );
}
