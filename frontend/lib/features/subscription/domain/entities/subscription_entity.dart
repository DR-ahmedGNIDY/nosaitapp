import 'package:equatable/equatable.dart';

enum SubscriptionType { newSubscription, renewal }

enum SubscriptionStatus { active, expired }

class SubscriptionEntity extends Equatable {
  final String id;
  final String academyId;
  final String playerId;
  /// اسم اللاعب — مُستخرَج من populate الـ backend
  final String playerName;
  final SubscriptionType type;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SubscriptionEntity({
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

  SubscriptionStatus get status =>
      DateTime.now().isBefore(endDate) ||
              DateTime.now().isAtSameMomentAs(endDate)
          ? SubscriptionStatus.active
          : SubscriptionStatus.expired;

  bool get isActive => status == SubscriptionStatus.active;

  String get typeLabel =>
      type == SubscriptionType.newSubscription ? 'اشتراك جديد' : 'تجديد';

  String get statusLabel => isActive ? 'نشط' : 'منتهي';

  @override
  List<Object?> get props => [
        id,
        academyId,
        playerId,
        playerName,
        type,
        amount,
        startDate,
        endDate,
        notes,
        createdAt,
        updatedAt,
      ];
}
