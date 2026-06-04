import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class GetCurrentUserUsecase extends UseCaseNoParams<UserEntity> {
  final AuthRepository _repository;
  GetCurrentUserUsecase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call() {
    return _repository.getCurrentUser();
  }
}
