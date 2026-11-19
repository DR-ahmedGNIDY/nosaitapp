import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';

/// اشتراك عليه مبلغ متبقٍّ (سطر داخل مديونية لاعب).
class DebtSubscriptionEntity {
  final String id;
  final SubscriptionType type;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime startDate;
  final DateTime endDate;

  const DebtSubscriptionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.startDate,
    required this.endDate,
  });

  String get typeLabel =>
      type == SubscriptionType.newSubscription ? 'اشتراك جديد' : 'تجديد';
}

/// مديونية لاعب واحد (مجموع المتبقي على كل اشتراكاته).
class PlayerDebtEntity {
  final String playerId;
  final String fullName;
  final String playerCode;
  final String? parentPhone;
  final String? playerPhone;
  final String? imageUrl;
  final bool isActive;
  final double totalDue;
  final List<DebtSubscriptionEntity> subscriptions;

  const PlayerDebtEntity({
    required this.playerId,
    required this.fullName,
    required this.playerCode,
    this.parentPhone,
    this.playerPhone,
    this.imageUrl,
    this.isActive = true,
    required this.totalDue,
    required this.subscriptions,
  });

  /// رقم التواصل: ولي الأمر أولاً ثم اللاعب.
  String? get contactPhone {
    if (parentPhone != null && parentPhone!.trim().isNotEmpty) return parentPhone;
    if (playerPhone != null && playerPhone!.trim().isNotEmpty) return playerPhone;
    return null;
  }
}

/// كل مديونيات الأكاديمية + ملخّص.
class AcademyDebtsEntity {
  final double totalOutstanding;
  final int playersCount;
  final int subscriptionsCount;
  final List<PlayerDebtEntity> players;

  const AcademyDebtsEntity({
    required this.totalOutstanding,
    required this.playersCount,
    required this.subscriptionsCount,
    required this.players,
  });
}
