import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:basketball_academy/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetSubscriptionsByTypeParams {
  final String? academyId;
  const GetSubscriptionsByTypeParams({this.academyId});
}

class GetSubscriptionsByTypeUsecase extends UseCase<SubscriptionsByTypeEntity, GetSubscriptionsByTypeParams> {
  final DashboardRepository _repository;

  GetSubscriptionsByTypeUsecase(this._repository);

  @override
  Future<Either<Failure, SubscriptionsByTypeEntity>> call(GetSubscriptionsByTypeParams params) {
    return _repository.getSubscriptionsByType(academyId: params.academyId);
  }
}
