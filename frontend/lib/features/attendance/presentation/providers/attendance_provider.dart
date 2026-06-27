import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:basketball_academy/features/attendance/domain/usecases/get_attendance_log_usecase.dart';
import 'package:basketball_academy/features/attendance/domain/usecases/get_attendance_report_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Filter keys (Equatable so the .family providers cache correctly)
// ---------------------------------------------------------------------------

class AttendanceLogFilter extends Equatable {
  final String academyId;
  final String? date; // 'YYYY-MM-DD'
  final String? sport; // null/'' = الكل
  final String? playerId;

  const AttendanceLogFilter({
    required this.academyId,
    this.date,
    this.sport,
    this.playerId,
  });

  @override
  List<Object?> get props => [academyId, date, sport, playerId];
}

class AttendanceReportFilter extends Equatable {
  final String academyId;
  final String? startDate;
  final String? endDate;
  final String? sport;

  const AttendanceReportFilter({
    required this.academyId,
    this.startDate,
    this.endDate,
    this.sport,
  });

  @override
  List<Object?> get props => [academyId, startDate, endDate, sport];
}

// ---------------------------------------------------------------------------
// Providers — كل واحد = طلب واحد فقط لكل تركيبة فلاتر (يُخزّن مؤقتاً عبر family)
// ---------------------------------------------------------------------------

final attendanceLogProvider = FutureProvider.autoDispose
    .family<AttendanceLogResult, AttendanceLogFilter>((ref, filter) async {
  final usecase = sl<GetAttendanceLogUsecase>();
  final result = await usecase(GetAttendanceLogParams(
    academyId: filter.academyId,
    date: filter.date,
    sport: filter.sport,
    playerId: filter.playerId,
    page: 1,
    limit: 100,
  ));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

final attendanceReportProvider = FutureProvider.autoDispose
    .family<AttendanceReport, AttendanceReportFilter>((ref, filter) async {
  final usecase = sl<GetAttendanceReportUsecase>();
  final result = await usecase(GetAttendanceReportParams(
    academyId: filter.academyId,
    startDate: filter.startDate,
    endDate: filter.endDate,
    sport: filter.sport,
  ));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});
