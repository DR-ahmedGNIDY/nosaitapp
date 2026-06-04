import 'package:basketball_academy/features/dashboard/domain/entities/dashboard_entity.dart';

class DashboardStatsModel {
  final int totalPlayers;
  final int activePlayers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final double totalRevenue;
  final double currentMonthRevenue;
  final int newSubscriptionsCount;
  final int renewalsCount;
  final double averageEvaluationScore;

  const DashboardStatsModel({
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

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalPlayers: (json['totalPlayers'] as num?)?.toInt() ?? 0,
      activePlayers: (json['activePlayers'] as num?)?.toInt() ?? 0,
      activeSubscriptions: (json['activeSubscriptions'] as num?)?.toInt() ?? 0,
      expiredSubscriptions: (json['expiredSubscriptions'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      currentMonthRevenue: (json['currentMonthRevenue'] as num?)?.toDouble() ?? 0.0,
      newSubscriptionsCount: (json['newSubscriptionsCount'] as num?)?.toInt() ?? 0,
      renewalsCount: (json['renewalsCount'] as num?)?.toInt() ?? 0,
      averageEvaluationScore: (json['averageEvaluationScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DashboardStatsEntity toEntity() {
    return DashboardStatsEntity(
      totalPlayers: totalPlayers,
      activePlayers: activePlayers,
      activeSubscriptions: activeSubscriptions,
      expiredSubscriptions: expiredSubscriptions,
      totalRevenue: totalRevenue,
      currentMonthRevenue: currentMonthRevenue,
      newSubscriptionsCount: newSubscriptionsCount,
      renewalsCount: renewalsCount,
      averageEvaluationScore: averageEvaluationScore,
    );
  }
}

class RevenueByMonthModel {
  final String month;
  final double revenue;
  final int count;

  const RevenueByMonthModel({
    required this.month,
    required this.revenue,
    required this.count,
  });

  factory RevenueByMonthModel.fromJson(Map<String, dynamic> json) {
    return RevenueByMonthModel(
      month: (json['month'] as String?) ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  RevenueByMonthEntity toEntity() {
    return RevenueByMonthEntity(
      month: month,
      revenue: revenue,
      count: count,
    );
  }
}

class SubscriptionsByTypeModel {
  final int newSubscription;
  final int renewal;
  final int total;

  const SubscriptionsByTypeModel({
    required this.newSubscription,
    required this.renewal,
    required this.total,
  });

  factory SubscriptionsByTypeModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionsByTypeModel(
      newSubscription: (json['newSubscription'] as num?)?.toInt() ?? 0,
      renewal: (json['renewal'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  SubscriptionsByTypeEntity toEntity() {
    return SubscriptionsByTypeEntity(
      newSubscription: newSubscription,
      renewal: renewal,
      total: total,
    );
  }
}

class PlayersByBirthYearModel {
  final int year;
  final int count;

  const PlayersByBirthYearModel({
    required this.year,
    required this.count,
  });

  factory PlayersByBirthYearModel.fromJson(Map<String, dynamic> json) {
    return PlayersByBirthYearModel(
      year: (json['year'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  PlayersByBirthYearEntity toEntity() {
    return PlayersByBirthYearEntity(year: year, count: count);
  }
}

class EvaluationDistributionModel {
  final int excellent;
  final int good;
  final int needsImprovement;
  final int total;

  const EvaluationDistributionModel({
    required this.excellent,
    required this.good,
    required this.needsImprovement,
    required this.total,
  });

  factory EvaluationDistributionModel.fromJson(Map<String, dynamic> json) {
    return EvaluationDistributionModel(
      excellent: (json['excellent'] as num?)?.toInt() ?? 0,
      good: (json['good'] as num?)?.toInt() ?? 0,
      needsImprovement: (json['needsImprovement'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  EvaluationDistributionEntity toEntity() {
    return EvaluationDistributionEntity(
      excellent: excellent,
      good: good,
      needsImprovement: needsImprovement,
      total: total,
    );
  }
}

class RecentActivityModel {
  final String type;
  final String? playerName;
  final String? playerCode;
  final double? amount;
  final double? average;
  final String? gradeLabel;
  final DateTime createdAt;

  const RecentActivityModel({
    required this.type,
    this.playerName,
    this.playerCode,
    this.amount,
    this.average,
    this.gradeLabel,
    required this.createdAt,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      type: (json['type'] as String?) ?? 'PLAYER',
      playerName: json['playerName'] as String?,
      playerCode: json['playerCode'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      average: (json['average'] as num?)?.toDouble(),
      gradeLabel: json['gradeLabel'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  RecentActivityEntity toEntity() {
    return RecentActivityEntity(
      type: type,
      playerName: playerName,
      playerCode: playerCode,
      amount: amount,
      average: average,
      gradeLabel: gradeLabel,
      createdAt: createdAt,
    );
  }
}

class RecentActivitiesModel {
  final List<RecentActivityModel> recentPlayers;
  final List<RecentActivityModel> recentSubscriptions;
  final List<RecentActivityModel> recentEvaluations;

  const RecentActivitiesModel({
    required this.recentPlayers,
    required this.recentSubscriptions,
    required this.recentEvaluations,
  });

  factory RecentActivitiesModel.fromJson(Map<String, dynamic> json) {
    List<RecentActivityModel> parseList(dynamic raw) {
      if (raw == null) return [];
      return (raw as List<dynamic>)
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return RecentActivitiesModel(
      recentPlayers: parseList(json['recentPlayers']),
      recentSubscriptions: parseList(json['recentSubscriptions']),
      recentEvaluations: parseList(json['recentEvaluations']),
    );
  }

  RecentActivitiesEntity toEntity() {
    return RecentActivitiesEntity(
      recentPlayers: recentPlayers.map((m) => m.toEntity()).toList(),
      recentSubscriptions: recentSubscriptions.map((m) => m.toEntity()).toList(),
      recentEvaluations: recentEvaluations.map((m) => m.toEntity()).toList(),
    );
  }
}
