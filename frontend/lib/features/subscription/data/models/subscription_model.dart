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
  final String playerCode;
  final String? playerPhone;
  final String? playerImageUrl;
  final String type; // 'NEW_SUBSCRIPTION' | 'RENEWAL'
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final int? sessionsLimit;
  final DateTime? exhaustedAt;
  /// المدفوع (null من سيرفر قديم ⇒ مدفوع بالكامل).
  final double? paidAmount;
  /// سجل الدفعات كما يرجع من الـ API.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<SubscriptionPaymentEntity> payments;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.academyId,
    required this.playerId,
    this.playerName = '',
    this.playerCode = '',
    this.playerPhone,
    this.playerImageUrl,
    required this.type,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.sessionsLimit,
    this.exhaustedAt,
    this.paidAmount,
    this.payments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  static List<SubscriptionPaymentEntity> _parsePayments(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((p) {
      final m = p.cast<String, dynamic>();
      return SubscriptionPaymentEntity(
        id: (m['_id'] ?? '').toString(),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        date: m['date'] is String
            ? DateTime.parse(m['date'] as String)
            : DateTime.now(),
        method: (m['method'] as String?) ?? 'cash',
        note: m['note'] as String?,
        recordedByName: (m['recordedByName'] as String?) ?? '',
        receiptNo: (m['receiptNo'] as num?)?.toInt(),
      );
    }).toList();
  }

  /// يدعم كلا الحالتين:
  /// 1. playerId = String (ObjectId فقط)
  /// 2. playerId = { _id, fullName, playerCode } (populated من backend)
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final raw = json['playerId'];
    final String pid;
    final String pName;
    final String pCode;
    final String? pPhone;
    final String? pImage;

    if (raw is Map) {
      pid    = (raw['_id']       as String?) ?? '';
      pName  = (raw['fullName']  as String?) ?? '';
      pCode  = (raw['playerCode'] as String?) ?? '';
      pPhone = raw['parentPhone'] as String?;
      pImage = raw['image_url'] as String?;
    } else {
      pid    = (raw as String?) ?? '';
      pName  = '';
      pCode  = '';
      pPhone = null;
      pImage = null;
    }

    return SubscriptionModel(
      id:        json['_id'] as String,
      academyId: json['academyId'] as String,
      playerId:  pid,
      playerName: pName,
      playerCode: pCode,
      playerPhone: pPhone,
      playerImageUrl: pImage,
      type:      json['type'] as String,
      amount:    (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate:   DateTime.parse(json['endDate']   as String),
      notes:     json['notes'] as String?,
      sessionsLimit: (json['sessionsLimit'] as num?)?.toInt(),
      exhaustedAt: json['exhaustedAt'] == null
          ? null
          : DateTime.parse(json['exhaustedAt'] as String),
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
      payments: _parsePayments(json['payments']),
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
        playerCode: playerCode,
        playerPhone: playerPhone,
        playerImageUrl: playerImageUrl,
        type: type == 'NEW_SUBSCRIPTION'
            ? SubscriptionType.newSubscription
            : SubscriptionType.renewal,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        sessionsLimit: sessionsLimit,
        exhaustedAt: exhaustedAt,
        paidAmountRaw: paidAmount,
        payments: payments,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
