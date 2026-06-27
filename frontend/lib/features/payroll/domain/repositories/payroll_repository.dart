import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/payroll/domain/entities/payroll_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PayrollRepository {
  Future<Either<Failure, List<PayrollEntity>>> generatePayroll({required String month, String? staffId, bool force = false});
  Future<Either<Failure, List<PayrollEntity>>> getPayrollList({String? month, String? staffId, String? status});
  Future<Either<Failure, ({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})>> getPayrollReport(String month);
  Future<Either<Failure, PayrollEntity>> markPaid(String id);
}
