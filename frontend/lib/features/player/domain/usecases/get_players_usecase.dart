import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class GetPlayersParams {
  final String? academyId;
  final String? search;
  final int? birthYear;
  final String? sport;
  final String? attendanceDay;
  final int page;
  final int limit;

  const GetPlayersParams({
    this.academyId,
    this.search,
    this.birthYear,
    this.sport,
    this.attendanceDay,
    this.page = 1,
    this.limit = 20,
  });
}

class GetPlayersUsecase extends UseCase<
    ({List<PlayerEntity> players, int total, int page, int totalPages}),
    GetPlayersParams> {
  final PlayerRepository _repository;

  GetPlayersUsecase(this._repository);

  @override
  Future<Either<Failure, ({List<PlayerEntity> players, int total, int page, int totalPages})>>
      call(GetPlayersParams params) {
    return _repository.getPlayers(
      academyId: params.academyId,
      search: params.search,
      birthYear: params.birthYear,
      sport: params.sport,
      attendanceDay: params.attendanceDay,
      page: params.page,
      limit: params.limit,
    );
  }
}
