import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class GetGroupParams {
  final String id;

  const GetGroupParams({required this.id});
}

class GetGroupUsecase extends UseCase<GroupEntity, GetGroupParams> {
  final GroupsRepository _repository;

  GetGroupUsecase(this._repository);

  @override
  Future<Either<Failure, GroupEntity>> call(GetGroupParams params) {
    return _repository.getGroupById(params.id);
  }
}
