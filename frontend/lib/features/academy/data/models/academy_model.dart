import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'academy_model.g.dart';

@JsonSerializable()
class AcademyModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final String phone;
  final String address;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'player_count')
  final int? playerCount;

  const AcademyModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.phone,
    required this.address,
    required this.createdAt,
    this.playerCount,
  });

  factory AcademyModel.fromJson(Map<String, dynamic> json) =>
      _$AcademyModelFromJson(json);

  Map<String, dynamic> toJson() => _$AcademyModelToJson(this);

  AcademyEntity toEntity() => AcademyEntity(
        id: id,
        name: name,
        logoUrl: logoUrl,
        phone: phone,
        address: address,
        createdAt: createdAt,
        playerCount: playerCount,
      );
}
