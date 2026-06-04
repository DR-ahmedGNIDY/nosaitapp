import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:basketball_academy/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetEvaluationDistributionParams {
  final String? academyId;
  const GetEvaluationDistributionParams({this.academyId});
}

class GetEvaluationDistributionUsecase extends UseCase<EvaluationDistributionEntity, GetEvaluationDistributionParams> {
  final DashboardRepository _repository;

  GetEvaluationDistributionUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationDistributionEntity>> call(GetEvaluationDistributionParams params) {
    return _repository.getEvaluationDistribution(academyId: params.academyId);
  }
}
