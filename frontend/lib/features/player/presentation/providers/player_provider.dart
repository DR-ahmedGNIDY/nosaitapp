import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/domain/usecases/create_player_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/delete_player_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/get_players_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/search_players_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/update_player_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// PlayersState
// ---------------------------------------------------------------------------

class PlayersState {
  final List<PlayerEntity> players;
  final int total;
  final int page;
  final int totalPages;
  final bool hasMore;
  final String? search;
  final int? birthYearFilter;
  final String? academyIdFilter;
  final String? sportFilter;
  final String? attendanceDayFilter;

  const PlayersState({
    this.players = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.search,
    this.birthYearFilter,
    this.academyIdFilter,
    this.sportFilter,
    this.attendanceDayFilter,
  });

  PlayersState copyWith({
    List<PlayerEntity>? players,
    int? total,
    int? page,
    int? totalPages,
    bool? hasMore,
    Object? search = _sentinel,
    Object? birthYearFilter = _sentinel,
    Object? academyIdFilter = _sentinel,
    Object? sportFilter = _sentinel,
    Object? attendanceDayFilter = _sentinel,
  }) {
    return PlayersState(
      players: players ?? this.players,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      search: search == _sentinel ? this.search : search as String?,
      birthYearFilter: birthYearFilter == _sentinel
          ? this.birthYearFilter
          : birthYearFilter as int?,
      academyIdFilter: academyIdFilter == _sentinel
          ? this.academyIdFilter
          : academyIdFilter as String?,
      sportFilter:
          sportFilter == _sentinel ? this.sportFilter : sportFilter as String?,
      attendanceDayFilter: attendanceDayFilter == _sentinel
          ? this.attendanceDayFilter
          : attendanceDayFilter as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// PlayersNotifier
// ---------------------------------------------------------------------------

class PlayersNotifier extends AsyncNotifier<PlayersState> {
  late final GetPlayersUsecase _getPlayersUsecase;
  late final CreatePlayerUsecase _createPlayerUsecase;
  late final UpdatePlayerUsecase _updatePlayerUsecase;
  late final DeletePlayerUsecase _deletePlayerUsecase;

  @override
  Future<PlayersState> build() async {
    _getPlayersUsecase = sl<GetPlayersUsecase>();
    _createPlayerUsecase = sl<CreatePlayerUsecase>();
    _updatePlayerUsecase = sl<UpdatePlayerUsecase>();
    _deletePlayerUsecase = sl<DeletePlayerUsecase>();
    // Do NOT fetch on build — academy context is required.
    // PlayersListScreen.initState calls filterByAcademy() which triggers the first load.
    return const PlayersState();
  }

  Future<PlayersState> _fetchPlayers({
    String? search,
    int? birthYearFilter,
    String? academyIdFilter,
    String? sportFilter,
    String? attendanceDayFilter,
    int page = 1,
    int limit = 50,
  }) async {
    final result = await _getPlayersUsecase(
      GetPlayersParams(
        search: search,
        birthYear: birthYearFilter,
        academyId: academyIdFilter,
        sport: sportFilter,
        attendanceDay: attendanceDayFilter,
        page: page,
        limit: limit,
      ),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => PlayersState(
        players: data.players,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        hasMore: data.page < data.totalPages,
        search: search,
        birthYearFilter: birthYearFilter,
        academyIdFilter: academyIdFilter,
        sportFilter: sportFilter,
        attendanceDayFilter: attendanceDayFilter,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
      ),
    );
  }

  Future<void> search(String query) async {
    // Capture current filters BEFORE switching to loading —
    // AsyncLoading() clears valueOrNull, otherwise academy/year filters are lost.
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: query.isEmpty ? null : query,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
      ),
    );
  }

  Future<void> clearSearch() async {
    // Remove the search term entirely and reload the full list,
    // preserving academy and birth-year filters.
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: null,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
      ),
    );
  }

  Future<void> filterByBirthYear(int? year) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: year,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
      ),
    );
  }

  Future<void> filterByAcademy(String? academyId) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: academyId,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
      ),
    );
  }

  Future<void> filterBySport(String? sport) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: sport,
        attendanceDayFilter: current?.attendanceDayFilter,
      ),
    );
  }

  Future<void> filterByAttendanceDay(String? day) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: day,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final nextPage = current.page + 1;
    final result = await _getPlayersUsecase(
      GetPlayersParams(
        search: current.search,
        birthYear: current.birthYearFilter,
        academyId: current.academyIdFilter,
        sport: current.sportFilter,
        attendanceDay: current.attendanceDayFilter,
        page: nextPage,
        limit: 50,
      ),
    );
    result.fold(
      (_) {},
      (data) {
        state = AsyncValue.data(
          current.copyWith(
            players: [...current.players, ...data.players],
            page: data.page,
            totalPages: data.totalPages,
            total: data.total,
            hasMore: data.page < data.totalPages,
          ),
        );
      },
    );
  }

  Future<String?> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String> attendanceDays = const [],
    String? academyId,
    String? imagePath,
  }) async {
    final result = await _createPlayerUsecase(
      CreatePlayerParams(
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        playerPhone: playerPhone,
        notes: notes,
        sport: sport,
        attendanceDays: attendanceDays,
        academyId: academyId,
        imagePath: imagePath,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> updatePlayer({
    required String id,
    String? fullName,
    DateTime? birthDate,
    String? parentName,
    String? parentRelationship,
    String? parentJob,
    String? parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String>? attendanceDays,
    String? imagePath,
  }) async {
    final result = await _updatePlayerUsecase(
      UpdatePlayerParams(
        id: id,
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        playerPhone: playerPhone,
        notes: notes,
        sport: sport,
        attendanceDays: attendanceDays,
        imagePath: imagePath,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deletePlayer(String id) async {
    final result = await _deletePlayerUsecase(
      DeletePlayerParams(id: id),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }
}

final playersProvider =
    AsyncNotifierProvider<PlayersNotifier, PlayersState>(PlayersNotifier.new);

// ---------------------------------------------------------------------------
// PlayerSearchNotifier
// ---------------------------------------------------------------------------

class PlayerSearchNotifier extends AsyncNotifier<List<PlayerEntity>> {
  late final SearchPlayersUsecase _searchPlayersUsecase;

  @override
  Future<List<PlayerEntity>> build() async {
    _searchPlayersUsecase = sl<SearchPlayersUsecase>();
    return [];
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _searchPlayersUsecase(
        SearchPlayersParams(query: query.trim()),
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (players) => players,
      );
    });
  }

  Future<void> clear() async {
    state = const AsyncValue.data([]);
  }
}

final playerSearchProvider =
    AsyncNotifierProvider<PlayerSearchNotifier, List<PlayerEntity>>(
  PlayerSearchNotifier.new,
);
