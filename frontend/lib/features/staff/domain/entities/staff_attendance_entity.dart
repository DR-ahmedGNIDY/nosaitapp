import 'package:equatable/equatable.dart';

class StaffAttendanceEntity extends Equatable {
  final String id;
  final String staffId;
  final String academyId;
  final String date; // 'YYYY-MM-DD'
  final String status; // 'present' | 'absent'
  final String? notes;

  const StaffAttendanceEntity({
    required this.id,
    required this.staffId,
    required this.academyId,
    required this.date,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [id, staffId, academyId, date, status, notes];
}

class StaffAttendanceReportRow extends Equatable {
  final String staffId;
  final String fullName;
  final String position;
  final int presentCount;
  final int absentCount;

  const StaffAttendanceReportRow({
    required this.staffId,
    required this.fullName,
    required this.position,
    required this.presentCount,
    required this.absentCount,
  });

  @override
  List<Object?> get props => [staffId, fullName, position, presentCount, absentCount];
}
