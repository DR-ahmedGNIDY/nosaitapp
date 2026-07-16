import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class GetGroupsBySportParams {
  final String sportId;

  const GetGroupsBySportParams({required this.sportId});
}

class GetGroupsBySportUsecase
    extends UseCase<List<GroupEntity>, GetGroupsBySportParams> {
  final GroupsRepository _repository;

  GetGroupsBySportUsecase(this._repository);

  @override
  Future<Either<Failure, List<GroupEntity>>> call(
      GetGroupsBySportParams params) {
    return _repository.getGroupsBySport(params.sportId);
  }
}
