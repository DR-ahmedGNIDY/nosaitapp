import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/payroll/data/models/payroll_model.dart';

abstract class PayrollRemoteDatasource {
  Future<List<PayrollModel>> generatePayroll({required String month, String? staffId, bool force = false});
  Future<List<PayrollModel>> getPayrollList({String? month, String? staffId, String? status});
  Future<({List<PayrollReportRowModel> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> getPayrollReport(String month);
  Future<PayrollModel> markPaid(String id);
}

class PayrollRemoteDatasourceImpl implements PayrollRemoteDatasource {
  final ApiClient _apiClient;
  PayrollRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<PayrollModel>> generatePayroll({required String month, String? staffId, bool force = false}) async {
    final response = await _apiClient.post('/payroll/generate', data: {
      'month': month,
      if (staffId != null) 'staffId': staffId,
      if (force) 'force': true,
    });
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).map((e) => PayrollModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PayrollModel>> getPayrollList({String? month, String? staffId, String? status}) async {
    final response = await _apiClient.get('/payroll', queryParameters: {
      if (month != null) 'month': month,
      if (staffId != null) 'staffId': staffId,
      if (status != null) 'status': status,
    });
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).map((e) => PayrollModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<({List<PayrollReportRowModel> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> getPayrollReport(String month) async {
    final response = await _apiClient.get('/payroll/report', queryParameters: {'month': month});
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final report = (data['report'] as List<dynamic>).map((e) => PayrollReportRowModel.fromJson(e as Map<String, dynamic>)).toList();
    final totals = data['totals'] as Map<String, dynamic>;
    return (
      report: report,
      totalBaseSalary: (totals['totalBaseSalary'] as num).toDouble(),
      totalDeductions: (totals['totalDeductions'] as num).toDouble(),
      totalNetSalary: (totals['totalNetSalary'] as num).toDouble(),
    );
  }

  @override
  Future<PayrollModel> markPaid(String id) async {
    final response = await _apiClient.patch('/payroll/$id/mark-paid');
    final body = response.data as Map<String, dynamic>;
    return PayrollModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
