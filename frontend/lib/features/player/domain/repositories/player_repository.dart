import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PlayerRepository {
  Future<
      Either<
          Failure,
          ({
            List<PlayerEntity> players,
            int total,
            int page,
            int totalPages,
          })>> getPlayers({
    String? academyId,
    String? search,
    int? birthYear,
    String? sport,
    String? attendanceDay,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, List<PlayerEntity>>> searchPlayers(String query);

  Future<Either<Failure, PlayerEntity>> getPlayerById(String id);

  Future<Either<Failure, PlayerEntity>> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String> attendanceDays,
    String? academyId,
    String? imagePath,
  });

  Future<Either<Failure, PlayerEntity>> updatePlayer({
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
  });

  Future<Either<Failure, void>> deletePlayer(String id);

  Future<Either<Failure, void>> deletePlayerImage(String id);
}
