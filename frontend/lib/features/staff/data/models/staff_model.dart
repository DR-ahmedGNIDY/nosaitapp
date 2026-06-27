import 'package:basketball_academy/features/staff/domain/entities/staff_entity.dart';

class StaffModel {
  final String id;
  final String academyId;
  final String fullName;
  final String position;
  final String phone;
  final String? email;
  final String? photoUrl;
  final String hireDateStr;
  final double? baseSalary;
  final List<String> workingDays;
  final int monthlyAttendanceTarget;
  final String deductionType;
  final double deductionValue;
  final bool isActive;
  final String createdAtStr;

  const StaffModel({
    required this.id,
    required this.academyId,
    required this.fullName,
    required this.position,
    required this.phone,
    this.email,
    this.photoUrl,
    required this.hireDateStr,
    this.baseSalary,
    this.workingDays = const [],
    required this.monthlyAttendanceTarget,
    required this.deductionType,
    required this.deductionValue,
    this.isActive = true,
    required this.createdAtStr,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
        id: json['_id'] as String,
        academyId: json['academyId'] as String,
        fullName: json['fullName'] as String,
        position: json['position'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        photoUrl: json['photo_url'] as String?,
        hireDateStr: json['hireDate'] as String,
        baseSalary: (json['baseSalary'] as num?)?.toDouble(),
        workingDays: (json['workingDays'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        monthlyAttendanceTarget: (json['monthlyAttendanceTarget'] as num).toInt(),
        deductionType: json['deductionType'] as String,
        deductionValue: (json['deductionValue'] as num).toDouble(),
        isActive: json['isActive'] as bool? ?? true,
        createdAtStr: json['created_at'] as String,
      );

  StaffEntity toEntity() => StaffEntity(
        id: id,
        academyId: academyId,
        fullName: fullName,
        position: position,
        phone: phone,
        email: email,
        photoUrl: photoUrl,
        hireDate: DateTime.parse(hireDateStr),
        baseSalary: baseSalary,
        workingDays: workingDays,
        monthlyAttendanceTarget: monthlyAttendanceTarget,
        deductionType: deductionType,
        deductionValue: deductionValue,
        isActive: isActive,
        createdAt: DateTime.parse(createdAtStr),
      );
}
