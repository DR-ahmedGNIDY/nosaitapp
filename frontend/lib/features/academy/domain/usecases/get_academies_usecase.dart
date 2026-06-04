import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class GetAcademiesUsecase extends UseCaseNoParams<List<AcademyEntity>> {
  final AcademyRepository _repository;
  GetAcademiesUsecase(this._repository);

  @override
  Future<Either<Failure, List<AcademyEntity>>> call() {
    return _repository.getAcademies();
  }
}
