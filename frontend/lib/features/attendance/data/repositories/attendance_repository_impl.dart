import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:basketball_academy/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDatasource _remoteDatasource;

  AttendanceRepositoryImpl({required AttendanceRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, AttendanceRecordResult>> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
  }) async {
    try {
      final result = await _remoteDatasource.recordAttendance(
        code: code,
        playerId: playerId,
        localDate: localDate,
        localTime: localTime,
      );
      return Right(result);
    } on NotFoundException {
      return const Left(NotFoundFailure(message: 'اللاعب غير موجود — تأكد من الكود'));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
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
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final result = await _remoteDatasource.getAttendanceLog(
        academyId: academyId,
        date: date,
        startDate: startDate,
        endDate: endDate,
        sport: sport,
        playerId: playerId,
        page: page,
        limit: limit,
      );
      return Right(result);
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
  Future<Either<Failure, AttendanceReport>> getAttendanceReport({
    String? academyId,
    String? startDate,
    String? endDate,
    String? sport,
  }) async {
    try {
      final result = await _remoteDatasource.getAttendanceReport(
        academyId: academyId,
        startDate: startDate,
        endDate: endDate,
        sport: sport,
      );
      return Right(result);
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
}
