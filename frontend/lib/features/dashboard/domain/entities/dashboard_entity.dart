import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int totalPlayers;
  final int activePlayers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final double totalRevenue;
  final double currentMonthRevenue;
  final int newSubscriptionsCount;
  final int renewalsCount;
  final double averageEvaluationScore;

  const DashboardStatsEntity({
    required this.totalPlayers,
    required this.activePlayers,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.totalRevenue,
    required this.currentMonthRevenue,
    required this.newSubscriptionsCount,
    required this.renewalsCount,
    required this.averageEvaluationScore,
  });

  @override
  List<Object?> get props => [
        totalPlayers,
        activePlayers,
        activeSubscriptions,
        expiredSubscriptions,
        totalRevenue,
        currentMonthRevenue,
        newSubscriptionsCount,
        renewalsCount,
        averageEvaluationScore,
      ];
}

class RevenueByMonthEntity extends Equatable {
  final String month; // "2024-01"
  final double revenue;
  final int count;

  const RevenueByMonthEntity({
    required this.month,
    required this.revenue,
    required this.count,
  });

  @override
  List<Object?> get props => [month, revenue, count];
}

class SubscriptionsByTypeEntity extends Equatable {
  final int newSubscription;
  final int renewal;
  final int total;

  const SubscriptionsByTypeEntity({
    required this.newSubscription,
    required this.renewal,
    required this.total,
  });

  @override
  List<Object?> get props => [newSubscription, renewal, total];
}

class PlayersByBirthYearEntity extends Equatable {
  final int year;
  final int count;

  const PlayersByBirthYearEntity({
    required this.year,
    required this.count,
  });

  @override
  List<Object?> get props => [year, count];
}

class EvaluationDistributionEntity extends Equatable {
  final int excellent;
  final int good;
  final int needsImprovement;
  final int total;

  const EvaluationDistributionEntity({
    required this.excellent,
    required this.good,
    required this.needsImprovement,
    required this.total,
  });

  @override
  List<Object?> get props => [excellent, good, needsImprovement, total];
}

class RecentActivityEntity extends Equatable {
  final String type; // 'PLAYER' | 'NEW_SUBSCRIPTION' | 'RENEWAL' | 'EVALUATION'
  final String? playerName;
  final String? playerCode;
  final double? amount;
  final double? average;
  final String? gradeLabel;
  final DateTime createdAt;

  const RecentActivityEntity({
    required this.type,
    this.playerName,
    this.playerCode,
    this.amount,
    this.average,
    this.gradeLabel,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        type,
        playerName,
        playerCode,
        amount,
        average,
        gradeLabel,
        createdAt,
      ];
}

class RecentActivitiesEntity extends Equatable {
  final List<RecentActivityEntity> recentPlayers;
  final List<RecentActivityEntity> recentSubscriptions;
  final List<RecentActivityEntity> recentEvaluations;

  const RecentActivitiesEntity({
    required this.recentPlayers,
    required this.recentSubscriptions,
    required this.recentEvaluations,
  });

  List<RecentActivityEntity> get all {
    final combined = [
      ...recentPlayers,
      ...recentSubscriptions,
      ...recentEvaluations,
    ];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  @override
  List<Object?> get props => [recentPlayers, recentSubscriptions, recentEvaluations];
}
