import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_attendance_entity.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_entity.dart';
import 'package:basketball_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:dartz/dartz.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDatasource _remoteDatasource;
  StaffRepositoryImpl({required StaffRemoteDatasource remoteDatasource}) : _remoteDatasource = remoteDatasource;

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ({List<StaffEntity> staff, int total, int page, int totalPages})>> getStaff({
    String? search,
    bool showInactive = false,
    int page = 1,
    int limit = 50,
  }) {
    return _wrap(() async {
      final result = await _remoteDatasource.getStaff(
        search: search, showInactive: showInactive, page: page, limit: limit,
      );
      return (
        staff: result.staff.map((m) => m.toEntity()).toList(),
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, StaffEntity>> getStaffById(String id) {
    return _wrap(() async => (await _remoteDatasource.getStaffById(id)).toEntity());
  }

  @override
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
  }) {
    return _wrap(() async => (await _remoteDatasource.createStaff(
          fullName: fullName,
          position: position,
          phone: phone,
          email: email,
          hireDate: hireDate,
          baseSalary: baseSalary,
          workingDays: workingDays,
          monthlyAttendanceTarget: monthlyAttendanceTarget,
          deductionType: deductionType,
          deductionValue: deductionValue,
          photoPath: photoPath,
        ))
            .toEntity());
  }

  @override
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
  }) {
    return _wrap(() async => (await _remoteDatasource.updateStaff(
          id: id,
          fullName: fullName,
          position: position,
          phone: phone,
          email: email,
          hireDate: hireDate,
          baseSalary: baseSalary,
          workingDays: workingDays,
          monthlyAttendanceTarget: monthlyAttendanceTarget,
          deductionType: deductionType,
          deductionValue: deductionValue,
          photoPath: photoPath,
        ))
            .toEntity());
  }

  @override
  Future<Either<Failure, void>> deleteStaff(String id) {
    return _wrap(() => _remoteDatasource.deleteStaff(id));
  }

  @override
  Future<Either<Failure, StaffAttendanceEntity>> markAttendance({
    required String staffId,
    required String date,
    required String status,
    String? notes,
  }) {
    return _wrap(() async => (await _remoteDatasource.markAttendance(
          staffId: staffId, date: date, status: status, notes: notes,
        ))
            .toEntity());
  }

  @override
  Future<Either<Failure, List<StaffAttendanceEntity>>> getAttendanceHistory({
    String? staffId,
    String? startDate,
    String? endDate,
  }) {
    return _wrap(() async => (await _remoteDatasource.getAttendanceHistory(
          staffId: staffId, startDate: startDate, endDate: endDate,
        ))
            .map((m) => m.toEntity())
            .toList());
  }

  @override
  Future<Either<Failure, List<StaffAttendanceReportRow>>> getAttendanceReport({
    required String startDate,
    required String endDate,
  }) {
    return _wrap(() async => (await _remoteDatasource.getAttendanceReport(
          startDate: startDate, endDate: endDate,
        ))
            .map((m) => m.toEntity())
            .toList());
  }
}
