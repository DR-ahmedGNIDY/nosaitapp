import 'dart:convert';

import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/core/utils/multipart/image_multipart_helper.dart';
import 'package:basketball_academy/features/staff/data/models/staff_attendance_model.dart';
import 'package:basketball_academy/features/staff/data/models/staff_model.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

abstract class StaffRemoteDatasource {
  Future<({List<StaffModel> staff, int total, int page, int totalPages})> getStaff({
    String? search,
    bool showInactive = false,
    int page = 1,
    int limit = 50,
  });

  Future<StaffModel> getStaffById(String id);

  Future<StaffModel> createStaff({
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

  Future<StaffModel> updateStaff({
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

  Future<void> deleteStaff(String id);

  Future<StaffAttendanceModel> markAttendance({
    required String staffId,
    required String date,
    required String status,
    String? notes,
  });

  Future<List<StaffAttendanceModel>> getAttendanceHistory({
    String? staffId,
    String? startDate,
    String? endDate,
  });

  Future<List<StaffAttendanceReportRowModel>> getAttendanceReport({
    required String startDate,
    required String endDate,
  });
}

class StaffRemoteDatasourceImpl implements StaffRemoteDatasource {
  final ApiClient _apiClient;
  StaffRemoteDatasourceImpl(this._apiClient);

  @override
  Future<({List<StaffModel> staff, int total, int page, int totalPages})> getStaff({
    String? search,
    bool showInactive = false,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get('/staff', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (showInactive) 'showInactive': 'true',
    });
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      staff: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<StaffModel> getStaffById(String id) async {
    final response = await _apiClient.get('/staff/$id');
    final body = response.data as Map<String, dynamic>;
    return StaffModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _buildFields({
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
  }) {
    return {
      if (fullName != null) 'fullName': fullName,
      if (position != null) 'position': position,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (hireDate != null) 'hireDate': DateFormat('yyyy-MM-dd').format(hireDate),
      if (baseSalary != null) 'baseSalary': baseSalary,
      if (workingDays != null) 'workingDays': workingDays,
      if (monthlyAttendanceTarget != null) 'monthlyAttendanceTarget': monthlyAttendanceTarget,
      if (deductionType != null) 'deductionType': deductionType,
      if (deductionValue != null) 'deductionValue': deductionValue,
    };
  }

  @override
  Future<StaffModel> createStaff({
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
  }) async {
    final fields = _buildFields(
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
    );

    if (photoPath != null) {
      final formMap = Map<String, dynamic>.from(fields);
      formMap['workingDays'] = jsonEncode(workingDays);
      formMap['photo'] = await buildImageMultipart(photoPath, filename: 'staff_photo.jpg');
      final response = await _apiClient.postMultipart<Map<String, dynamic>>(
        '/staff',
        data: FormData.fromMap(formMap),
      );
      final body = response.data as Map<String, dynamic>;
      return StaffModel.fromJson(body['data'] as Map<String, dynamic>);
    } else {
      final response = await _apiClient.post('/staff', data: fields);
      final body = response.data as Map<String, dynamic>;
      return StaffModel.fromJson(body['data'] as Map<String, dynamic>);
    }
  }

  @override
  Future<StaffModel> updateStaff({
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
  }) async {
    final fields = _buildFields(
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
    );

    if (photoPath != null) {
      final formMap = Map<String, dynamic>.from(fields);
      if (workingDays != null) formMap['workingDays'] = jsonEncode(workingDays);
      formMap['photo'] = await buildImageMultipart(photoPath, filename: 'staff_photo.jpg');
      final response = await _apiClient.putMultipart<Map<String, dynamic>>(
        '/staff/$id',
        data: FormData.fromMap(formMap),
      );
      final body = response.data as Map<String, dynamic>;
      return StaffModel.fromJson(body['data'] as Map<String, dynamic>);
    } else {
      final response = await _apiClient.put('/staff/$id', data: fields);
      final body = response.data as Map<String, dynamic>;
      return StaffModel.fromJson(body['data'] as Map<String, dynamic>);
    }
  }

  @override
  Future<void> deleteStaff(String id) async {
    await _apiClient.delete('/staff/$id');
  }

  @override
  Future<StaffAttendanceModel> markAttendance({
    required String staffId,
    required String date,
    required String status,
    String? notes,
  }) async {
    final response = await _apiClient.post('/staff-attendance', data: {
      'staffId': staffId,
      'date': date,
      'status': status,
      if (notes != null) 'notes': notes,
    });
    final body = response.data as Map<String, dynamic>;
    return StaffAttendanceModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<StaffAttendanceModel>> getAttendanceHistory({
    String? staffId,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _apiClient.get('/staff-attendance', queryParameters: {
      if (staffId != null) 'staffId': staffId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>)
        .map((e) => StaffAttendanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StaffAttendanceReportRowModel>> getAttendanceReport({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.get('/staff-attendance/report', queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
    });
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>)
        .map((e) => StaffAttendanceReportRowModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
