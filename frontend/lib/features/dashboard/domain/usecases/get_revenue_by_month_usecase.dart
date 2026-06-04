import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:basketball_academy/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetRevenueByMonthParams {
  final String? academyId;
  const GetRevenueByMonthParams({this.academyId});
}

class GetRevenueByMonthUsecase extends UseCase<List<RevenueByMonthEntity>, GetRevenueByMonthParams> {
  final DashboardRepository _repository;

  GetRevenueByMonthUsecase(this._repository);

  @override
  Future<Either<Failure, List<RevenueByMonthEntity>>> call(GetRevenueByMonthParams params) {
    return _repository.getRevenueByMonth(academyId: params.academyId);
  }
}
