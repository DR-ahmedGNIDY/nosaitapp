import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class CreatePlayerParams {
  final String fullName;
  final DateTime birthDate;
  final String parentName;
  final String parentRelationship;
  final String? parentJob;
  final String parentPhone;
  final String? playerPhone;
  final String? notes;
  final String? sport;
  final List<String> attendanceDays;
  final String? academyId;
  final String? imagePath;

  const CreatePlayerParams({
    required this.fullName,
    required this.birthDate,
    required this.parentName,
    required this.parentRelationship,
    this.parentJob,
    required this.parentPhone,
    this.playerPhone,
    this.notes,
    this.sport,
    this.attendanceDays = const [],
    this.academyId,
    this.imagePath,
  });
}

class CreatePlayerUsecase extends UseCase<PlayerEntity, CreatePlayerParams> {
  final PlayerRepository _repository;

  CreatePlayerUsecase(this._repository);

  @override
  Future<Either<Failure, PlayerEntity>> call(CreatePlayerParams params) {
    return _repository.createPlayer(
      fullName: params.fullName,
      birthDate: params.birthDate,
      parentName: params.parentName,
      parentRelationship: params.parentRelationship,
      parentJob: params.parentJob,
      parentPhone: params.parentPhone,
      playerPhone: params.playerPhone,
      notes: params.notes,
      sport: params.sport,
      attendanceDays: params.attendanceDays,
      academyId: params.academyId,
      imagePath: params.imagePath,
    );
  }
}
