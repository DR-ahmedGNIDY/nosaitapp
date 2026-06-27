import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

@JsonSerializable()
class SubscriptionModel {
  @JsonKey(name: '_id')
  final String id;
  final String academyId;
  final String playerId;
  // اسم اللاعب — يُستخرج من playerId عندما يكون مُحمَّلاً (populated object)
  final String playerName;
  final String type; // 'NEW_SUBSCRIPTION' | 'RENEWAL'
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.academyId,
    required this.playerId,
    this.playerName = '',
    required this.type,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// يدعم كلا الحالتين:
  /// 1. playerId = String (ObjectId فقط)
  /// 2. playerId = { _id, fullName, playerCode } (populated من backend)
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final raw = json['playerId'];
    final String pid;
    final String pName;

    if (raw is Map) {
      pid   = (raw['_id']      as String?) ?? '';
      pName = (raw['fullName'] as String?) ?? '';
    } else {
      pid   = (raw as String?) ?? '';
      pName = '';
    }

    return SubscriptionModel(
      id:        json['_id'] as String,
      academyId: json['academyId'] as String,
      playerId:  pid,
      playerName: pName,
      type:      json['type'] as String,
      amount:    (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate:   DateTime.parse(json['endDate']   as String),
      notes:     json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  SubscriptionEntity toEntity() => SubscriptionEntity(
        id: id,
        academyId: academyId,
        playerId: playerId,
        playerName: playerName,
        type: type == 'NEW_SUBSCRIPTION'
            ? SubscriptionType.newSubscription
            : SubscriptionType.renewal,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
