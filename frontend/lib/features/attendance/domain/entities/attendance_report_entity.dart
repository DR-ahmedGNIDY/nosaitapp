import 'package:equatable/equatable.dart';

/// سطر تقرير الحضور/الغياب للاعب واحد.
class AttendanceReportRow extends Equatable {
  final String playerId;
  final String playerCode;
  final String fullName;
  final String? sport;
  final int expected; // عدد أيام التدريب المتوقعة في الفترة
  final int present; // عدد أيام الحضور المسجّلة
  final int absent; // الغياب = المتوقع − الحضور
  final int rate; // نسبة الالتزام %

  const AttendanceReportRow({
    required this.playerId,
    required this.playerCode,
    required this.fullName,
    this.sport,
    required this.expected,
    required this.present,
    required this.absent,
    required this.rate,
  });

  @override
  List<Object?> get props =>
      [playerId, playerCode, fullName, sport, expected, present, absent, rate];
}

/// تقرير الحضور/الغياب الكامل القادم من GET /attendance/report.
class AttendanceReport extends Equatable {
  final String startDate;
  final String endDate;
  final String? sport;
  final int playersCount;
  final int totalPresent;
  final int totalAbsent;
  final List<AttendanceReportRow> rows;

  const AttendanceReport({
    required this.startDate,
    required this.endDate,
    this.sport,
    required this.playersCount,
    required this.totalPresent,
    required this.totalAbsent,
    required this.rows,
  });

  @override
  List<Object?> get props =>
      [startDate, endDate, sport, playersCount, totalPresent, totalAbsent, rows];
}
