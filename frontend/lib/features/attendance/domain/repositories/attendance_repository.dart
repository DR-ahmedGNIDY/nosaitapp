import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, AttendanceRecordResult>> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
  });

  Future<
      Either<
          Failure,
          ({
            List<AttendanceLogEntry> records,
            int total,
            int page,
            int totalPages,
          })>> getAttendanceLog({
    String? academyId,
    String? date,
    String? startDate,
    String? endDate,
    String? sport,
    String? playerId,
    int page,
    int limit,
  });

  Future<Either<Failure, AttendanceReport>> getAttendanceReport({
    String? academyId,
    String? startDate,
    String? endDate,
    String? sport,
  });
}
