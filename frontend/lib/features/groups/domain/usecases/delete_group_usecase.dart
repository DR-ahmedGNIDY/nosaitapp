import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteGroupParams {
  final String id;

  const DeleteGroupParams({required this.id});
}

class DeleteGroupUsecase extends UseCase<void, DeleteGroupParams> {
  final GroupsRepository _repository;

  DeleteGroupUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteGroupParams params) {
    return _repository.deleteGroup(params.id);
  }
}
