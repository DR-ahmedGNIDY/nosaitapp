import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:basketball_academy/features/attendance/domain/repositories/attendance_repository.dart';
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
  final int page; // صفحات من 100 سجل — "إظهار المزيد" يضيف صفحة

  const AttendanceLogFilter({
    required this.academyId,
    this.date,
    this.sport,
    this.playerId,
    this.page = 1,
  });

  AttendanceLogFilter copyWithPage(int p) => AttendanceLogFilter(
        academyId: academyId,
        date: date,
        sport: sport,
        playerId: playerId,
        page: p,
      );

  @override
  List<Object?> get props => [academyId, date, sport, playerId, page];
}

class AttendanceReportFilter extends Equatable {
  final String academyId;
  final String? startDate;
  final String? endDate;
  final String? sport;

  /// فلتر الاشتراك: 'active' = اللاعبون ذوو الاشتراك النشط حالياً،
  /// 'all' = كل اللاعبين النشطين في الأكاديمية.
  final String subscription;

  const AttendanceReportFilter({
    required this.academyId,
    this.startDate,
    this.endDate,
    this.sport,
    this.subscription = 'active',
  });

  @override
  List<Object?> get props =>
      [academyId, startDate, endDate, sport, subscription];
}

// ---------------------------------------------------------------------------
// Providers — كل واحد = طلب واحد فقط لكل تركيبة فلاتر (يُخزّن مؤقتاً عبر family)
// ---------------------------------------------------------------------------

const kAttendanceLogPageSize = 100;

final attendanceLogProvider = FutureProvider.autoDispose
    .family<AttendanceLogResult, AttendanceLogFilter>((ref, filter) async {
  final usecase = sl<GetAttendanceLogUsecase>();
  final result = await usecase(GetAttendanceLogParams(
    academyId: filter.academyId,
    date: filter.date,
    sport: filter.sport,
    playerId: filter.playerId,
    page: filter.page,
    limit: kAttendanceLogPageSize,
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
    subscription: filter.subscription,
  ));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

// ---------------------------------------------------------------------------
// سجل الحضور: بحث لاعب + ملخص حضوره في اشتراكه الأخير
// ---------------------------------------------------------------------------

class AttendancePlayerSearchKey extends Equatable {
  final String academyId;
  final String query;
  final String? sport;

  const AttendancePlayerSearchKey({
    required this.academyId,
    required this.query,
    this.sport,
  });

  @override
  List<Object?> get props => [academyId, query, sport];
}

final attendancePlayerSearchProvider = FutureProvider.autoDispose
    .family<List<AttendancePlayer>, AttendancePlayerSearchKey>((ref, key) async {
  final result = await sl<AttendanceRepository>().searchPlayers(
    academyId: key.academyId,
    query: key.query,
    sport: key.sport,
  );
  return result.fold((f) => throw Exception(f.message), (d) => d);
});

final attendancePlayerSummaryProvider = FutureProvider.autoDispose
    .family<AttendancePlayerSummary, String>((ref, playerId) async {
  final result = await sl<AttendanceRepository>().getPlayerSummary(playerId);
  return result.fold((f) => throw Exception(f.message), (d) => d);
});
