import 'package:equatable/equatable.dart';

class StaffEntity extends Equatable {
  final String id;
  final String academyId;
  final String fullName;
  final String position;
  final String phone;
  final String? email;
  final String? photoUrl;
  final DateTime hireDate;
  final double? baseSalary;
  final List<String> workingDays;
  final int monthlyAttendanceTarget;
  final String deductionType; // 'percentage' | 'fixed'
  final double deductionValue;
  final bool isActive;
  final DateTime createdAt;

  const StaffEntity({
    required this.id,
    required this.academyId,
    required this.fullName,
    required this.position,
    required this.phone,
    this.email,
    this.photoUrl,
    required this.hireDate,
    this.baseSalary,
    this.workingDays = const [],
    required this.monthlyAttendanceTarget,
    required this.deductionType,
    required this.deductionValue,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        academyId,
        fullName,
        position,
        phone,
        email,
        photoUrl,
        hireDate,
        baseSalary,
        workingDays,
        monthlyAttendanceTarget,
        deductionType,
        deductionValue,
        isActive,
        createdAt,
      ];
}
