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
  bool get isAcademyLevel =>
      role == UserRole.academyAdmin || role == UserRole.admin;

  /// academy_admin و super_admin غير مقيَّدين بمصفوفة permissions أصلاً؛
  /// لدور admin نتحقق من وجود المفتاح فعلياً في permissions.
  bool hasPermission(String key) =>
      isAcademyLevel && !isAdmin ? true : permissions.contains(key);

  String get fullName => name;

  /// الحالة الفعلية لاشتراك الأكاديمية: اشتراك وصل trial/active لكن مرّ تاريخ
  /// نهايته أثناء الجلسة يُعامَل منتهياً (نظير effectiveStatus() في الـ backend).
  AcademySubscriptionStatus get effectiveAcademySubscriptionStatus {
    final isLive =
        academySubscriptionStatus == AcademySubscriptionStatus.active ||
            academySubscriptionStatus == AcademySubscriptionStatus.trial;
    final end = academySubscriptionEndDate;
    if (isLive && end != null && DateTime.now().isAfter(end)) {
      return AcademySubscriptionStatus.expired;
    }
    return academySubscriptionStatus;
  }

  /// اشتراك الأكاديمية منتهٍ أو معلّق ⇒ تسجيل اشتراكات اللاعبين والحضور مقفول.
  /// super_admin لا يُقيَّد، والحالة غير المعروفة لا تقفل شيئاً (fail-open كالخادم).
  bool get isAcademyReadOnly {
    if (isSuperAdmin) return false;
    final s = effectiveAcademySubscriptionStatus;
    return s == AcademySubscriptionStatus.expired ||
        s == AcademySubscriptionStatus.suspended;
  }

  /// الأيام المتبقية في اشتراك الأكاديمية (null لو لا يوجد تاريخ نهاية).
  int? get academySubscriptionDaysLeft {
    final end = academySubscriptionEndDate;
    if (end == null) return null;
    final hours = end.difference(DateTime.now()).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  /// تحذير "اشتراك الأكاديمية قرب ينتهي": اشتراك حي باقٍ عليه 7 أيام أو أقل.
  bool get isAcademySubscriptionExpiringSoon {
    if (isSuperAdmin) return false;
    final s = effectiveAcademySubscriptionStatus;
    final days = academySubscriptionDaysLeft;
    return (s == AcademySubscriptionStatus.active ||
            s == AcademySubscriptionStatus.trial) &&
        days != null &&
        days <= 7;
  }

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
