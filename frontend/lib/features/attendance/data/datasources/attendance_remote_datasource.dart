import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/attendance/data/models/attendance_model.dart';
import 'package:basketball_academy/features/attendance/data/models/attendance_report_model.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_report_entity.dart';

abstract class AttendanceRemoteDatasource {
  Future<AttendanceRecordResult> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
  });

  Future<
      ({
        List<AttendanceLogEntry> records,
        int total,
        int page,
        int totalPages,
      })> getAttendanceLog({
    String? academyId,
    String? date,
    String? startDate,
    String? endDate,
    String? sport,
    String? playerId,
    int page,
    int limit,
  });

  Future<AttendanceReport> getAttendanceReport({
    String? academyId,
    String? startDate,
    String? endDate,
    String? sport,
  });
}

class AttendanceRemoteDatasourceImpl implements AttendanceRemoteDatasource {
  final ApiClient _apiClient;

  AttendanceRemoteDatasourceImpl(this._apiClient);

  @override
  Future<AttendanceRecordResult> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
  }) async {
    final data = <String, dynamic>{
      if (code != null) 'code': code,
      if (playerId != null) 'playerId': playerId,
      'localDate': localDate,
      'localTime': localTime,
    };
    final response = await _apiClient.post('/attendance', data: data);
    final body = response.data as Map<String, dynamic>;
    return AttendanceRecordMapper.fromResponse(
      (body['data'] as Map<String, dynamic>),
      (body['message'] as String?) ?? '',
    );
  }

  @override
  Future<
      ({
        List<AttendanceLogEntry> records,
        int total,
        int page,
        int totalPages,
      })> getAttendanceLog({
    String? academyId,
    String? date,
    String? startDate,
    String? endDate,
    String? sport,
    String? playerId,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (academyId != null) 'academyId': academyId,
      if (date != null) 'date': date,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
      if (playerId != null) 'playerId': playerId,
    };
    final response =
        await _apiClient.get('/attendance', queryParameters: query);
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => AttendanceLogMapper.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      records: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<AttendanceReport> getAttendanceReport({
    String? academyId,
    String? startDate,
    String? endDate,
    String? sport,
  }) async {
    final query = <String, dynamic>{
      if (academyId != null) 'academyId': academyId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
    };
    final response =
        await _apiClient.get('/attendance/report', queryParameters: query);
    final body = response.data as Map<String, dynamic>;
    return AttendanceReportMapper.fromJson(body['data'] as Map<String, dynamic>);
  }
}
