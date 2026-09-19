// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      academyId: json['academy_id'] as String?,
      academyName: json['academy_name'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      subscription: json['subscription'] == null
          ? null
          : AcademySubscriptionModel.fromJson(
              json['subscription'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'academy_id': instance.academyId,
      'academy_name': instance.academyName,
      'isActive': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'permissions': instance.permissions,
      'subscription': instance.subscription?.toJson(),
    };

AcademySubscriptionModel _$AcademySubscriptionModelFromJson(
        Map<String, dynamic> json) =>
    AcademySubscriptionModel(
      status: json['status'] as String?,
      plan: json['plan'] as String?,
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AcademySubscriptionModelToJson(
        AcademySubscriptionModel instance) =>
    <String, dynamic>{
      'status': instance.status,
      'plan': instance.plan,
      'endDate': instance.endDate?.toIso8601String(),
      'daysRemaining': instance.daysRemaining,
    };
