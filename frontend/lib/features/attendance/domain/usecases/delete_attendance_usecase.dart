import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteAttendanceUsecase extends UseCase<void, String> {
  final AttendanceRepository _repository;

  DeleteAttendanceUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteAttendance(id);
  }
}
