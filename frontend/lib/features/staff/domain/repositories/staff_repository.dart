import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_attendance_entity.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_entity.dart';
import 'package:dartz/dartz.dart';

abstract class StaffRepository {
  Future<Either<Failure, ({List<StaffEntity> staff, int total, int page, int totalPages})>> getStaff({
    String? search,
    bool showInactive = false,
    int page = 1,
    int limit = 50,
  });

  Future<Either<Failure, StaffEntity>> getStaffById(String id);

  Future<Either<Failure, StaffEntity>> createStaff({
    required String fullName,
    required String position,
    required String phone,
    String? email,
    required DateTime hireDate,
    double? baseSalary,
    required List<String> workingDays,
    required int monthlyAttendanceTarget,
    required String deductionType,
    required double deductionValue,
    String? photoPath,
  });

  Future<Either<Failure, StaffEntity>> updateStaff({
    required String id,
    String? fullName,
    String? position,
    String? phone,
    String? email,
    DateTime? hireDate,
    double? baseSalary,
    List<String>? workingDays,
    int? monthlyAttendanceTarget,
    String? deductionType,
    double? deductionValue,
    String? photoPath,
  });

  Future<Either<Failure, void>> deleteStaff(String id);

  Future<Either<Failure, StaffAttendanceEntity>> markAttendance({
    required String staffId,
    required String date,
    required String status,
    String? notes,
  });

  Future<Either<Failure, List<StaffAttendanceEntity>>> getAttendanceHistory({
    String? staffId,
    String? startDate,
    String? endDate,
  });

  Future<Either<Failure, List<StaffAttendanceReportRow>>> getAttendanceReport({
    required String startDate,
    required String endDate,
  });
}
