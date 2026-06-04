import 'package:equatable/equatable.dart';

enum UserRole { superAdmin, academyAdmin }

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? academyId;
  final String? academyName;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.academyId,
    this.academyName,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAcademyAdmin => role == UserRole.academyAdmin;

  @override
  List<Object?> get props => [id, name, email, role, academyId, academyName, createdAt];
}
