import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:basketball_academy/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class GetAttendanceReportParams {
  final String? academyId;
  final String? startDate;
  final String? endDate;
  final String? sport;

  const GetAttendanceReportParams({
    this.academyId,
    this.startDate,
    this.endDate,
    this.sport,
  });
}

class GetAttendanceReportUsecase
    extends UseCase<AttendanceReport, GetAttendanceReportParams> {
  final AttendanceRepository _repository;

  GetAttendanceReportUsecase(this._repository);

  @override
  Future<Either<Failure, AttendanceReport>> call(
      GetAttendanceReportParams params) {
    return _repository.getAttendanceReport(
      academyId: params.academyId,
      startDate: params.startDate,
      endDate: params.endDate,
      sport: params.sport,
    );
  }
}
