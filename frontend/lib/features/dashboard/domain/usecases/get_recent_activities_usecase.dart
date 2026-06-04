import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:basketball_academy/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetRecentActivitiesParams {
  final String? academyId;
  const GetRecentActivitiesParams({this.academyId});
}

class GetRecentActivitiesUsecase extends UseCase<RecentActivitiesEntity, GetRecentActivitiesParams> {
  final DashboardRepository _repository;

  GetRecentActivitiesUsecase(this._repository);

  @override
  Future<Either<Failure, RecentActivitiesEntity>> call(GetRecentActivitiesParams params) {
    return _repository.getRecentActivities(academyId: params.academyId);
  }
}
