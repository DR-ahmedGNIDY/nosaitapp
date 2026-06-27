import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class GetAttendanceLogParams {
  final String? academyId;
  final String? date;
  final String? startDate;
  final String? endDate;
  final String? sport;
  final String? playerId;
  final int page;
  final int limit;

  const GetAttendanceLogParams({
    this.academyId,
    this.date,
    this.startDate,
    this.endDate,
    this.sport,
    this.playerId,
    this.page = 1,
    this.limit = 30,
  });
}

typedef AttendanceLogResult = ({
  List<AttendanceLogEntry> records,
  int total,
  int page,
  int totalPages,
});

class GetAttendanceLogUsecase
    extends UseCase<AttendanceLogResult, GetAttendanceLogParams> {
  final AttendanceRepository _repository;

  GetAttendanceLogUsecase(this._repository);

  @override
  Future<Either<Failure, AttendanceLogResult>> call(
      GetAttendanceLogParams params) {
    return _repository.getAttendanceLog(
      academyId: params.academyId,
      date: params.date,
      startDate: params.startDate,
      endDate: params.endDate,
      sport: params.sport,
      playerId: params.playerId,
      page: params.page,
      limit: params.limit,
    );
  }
}
