import 'package:basketball_academy/features/auth/domain/entities/academy_subscription_status.dart';
import 'package:equatable/equatable.dart';

enum UserRole { superAdmin, academyAdmin, admin }

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? academyId;
  final String? academyName;
  final bool isActive;
  final DateTime createdAt;
  final List<String> permissions;

  /// حالة اشتراك **الأكاديمية** التي ينتمي إليها المستخدم (Academy-level).
  /// تصل من الخادم ضمن ردّ /auth/login و /auth/me — لا تُحسب على الجهاز ولا
  /// تُقرأ من أي إدخال محلي.
  final AcademySubscriptionStatus academySubscriptionStatus;

  /// تاريخ نهاية اشتراك الأكاديمية — يسمح باكتشاف الانتهاء أثناء الجلسة
  /// دون نداء شبكة إضافي. null إذا لم يوجد اشتراك.
  final DateTime? academySubscriptionEndDate;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.academyId,
    this.academyName,
    this.isActive = true,
    required this.createdAt,
    this.permissions = const [],
    this.academySubscriptionStatus = AcademySubscriptionStatus.unknown,
    this.academySubscriptionEndDate,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAcademyAdmin => role == UserRole.academyAdmin;
  bool get isAdmin => role == UserRole.admin;

  /// يملك صلاحيات اللاعبين والاشتراكات فقط
  bool get isLimitedAdmin => role == UserRole.admin;

  /// يملك صلاحيات كاملة على أكاديميته
  bool get isAcademyLevel => role == UserRole.academyAdmin || role == UserRole.admin;

  /// academy_admin و super_admin غير مقيَّدين بمصفوفة permissions أصلاً؛
  /// لدور admin نتحقق من وجود المفتاح فعلياً في permissions.
  bool hasPermission(String key) =>
      isAcademyLevel && !isAdmin ? true : permissions.contains(key);

  String get fullName => name;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        academyId,
        academyName,
        isActive,
        createdAt,
        permissions,
        academySubscriptionStatus,
        academySubscriptionEndDate,
      ];
}
