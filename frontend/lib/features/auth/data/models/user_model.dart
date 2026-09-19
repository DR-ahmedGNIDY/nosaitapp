import 'package:basketball_academy/features/auth/domain/entities/academy_subscription_status.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// اشتراك المنصة الخاص بـ **أكاديمية** المستخدم كما يصل من /auth/login و
/// /auth/me. يصل null لـ super_admin ولأكاديمية بلا وثيقة اشتراك.
@JsonSerializable()
class AcademySubscriptionModel {
  /// الحالة الفعلية من الخادم (effectiveStatus) — trial|active|expired|suspended.
  final String? status;
  final String? plan;
  final DateTime? endDate;
  final int? daysRemaining;

  const AcademySubscriptionModel({
    this.status,
    this.plan,
    this.endDate,
    this.daysRemaining,
  });

  factory AcademySubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$AcademySubscriptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$AcademySubscriptionModelToJson(this);
}

@JsonSerializable()
class UserModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String role;
  @JsonKey(name: 'academy_id')
  final String? academyId;
  @JsonKey(name: 'academy_name')
  final String? academyName;
  @JsonKey(name: 'isActive', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'permissions', defaultValue: <String>[])
  final List<String> permissions;

  /// اشتراك الأكاديمية (Academy-level). غيابه ≠ اشتراك فعّال — انظر [AdsPolicy].
  @JsonKey(name: 'subscription')
  final AcademySubscriptionModel? subscription;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.academyId,
    this.academyName,
    this.isActive = true,
    required this.createdAt,
    this.permissions = const [],
    this.subscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      role: role == 'super_admin'
          ? UserRole.superAdmin
          : role == 'admin'
              ? UserRole.admin
              : UserRole.academyAdmin,
      academyId: academyId,
      academyName: academyName,
      isActive: isActive,
      createdAt: createdAt,
      permissions: permissions,
      // لا اشتراك في الرد ⇒ none (وليس unknown): الخادم أجاب فعلاً ولم يجد
      // وثيقة اشتراك، أو المستخدم super_admin بلا أكاديمية.
      academySubscriptionStatus: subscription == null
          ? AcademySubscriptionStatus.none
          : AcademySubscriptionStatus.fromApi(subscription!.status),
      academySubscriptionEndDate: subscription?.endDate,
    );
  }
}
