import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class LogoutUsecase extends UseCaseNoParams<void> {
  final AuthRepository _repository;
  LogoutUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
