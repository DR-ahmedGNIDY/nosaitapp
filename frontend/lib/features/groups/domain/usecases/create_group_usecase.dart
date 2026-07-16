import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class CreateGroupParams {
  final String name;
  final String? academyId;
  final String? sportId;
  final String? ageGroup;
  final int? capacity;

  const CreateGroupParams({
    required this.name,
    this.academyId,
    this.sportId,
    this.ageGroup,
    this.capacity,
  });
}

class CreateGroupUsecase extends UseCase<GroupEntity, CreateGroupParams> {
  final GroupsRepository _repository;

  CreateGroupUsecase(this._repository);

  @override
  Future<Either<Failure, GroupEntity>> call(CreateGroupParams params) {
    return _repository.createGroup(
      name: params.name,
      academyId: params.academyId,
      sportId: params.sportId,
      ageGroup: params.ageGroup,
      capacity: params.capacity,
    );
  }
}
