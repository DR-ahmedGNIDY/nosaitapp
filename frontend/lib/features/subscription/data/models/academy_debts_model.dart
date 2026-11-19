import 'package:basketball_academy/features/subscription/domain/entities/academy_debts_entity.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';

/// يحوّل رد GET /subscriptions/academy/:id/debts إلى entities.
class AcademyDebtsModel {
  AcademyDebtsModel._();

  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

  static AcademyDebtsEntity fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final players = (json['players'] as List? ?? const [])
        .whereType<Map>()
        .map((p) => _player(p.cast<String, dynamic>()))
        .toList();
    return AcademyDebtsEntity(
      totalOutstanding: _num(summary['totalOutstanding']),
      playersCount: (summary['playersCount'] as num?)?.toInt() ?? players.length,
      subscriptionsCount: (summary['subscriptionsCount'] as num?)?.toInt() ?? 0,
      players: players,
    );
  }

  static PlayerDebtEntity _player(Map<String, dynamic> p) => PlayerDebtEntity(
        playerId: (p['playerId'] ?? '').toString(),
        fullName: (p['fullName'] as String?) ?? '',
        playerCode: (p['playerCode'] ?? '').toString(),
        parentPhone: p['parentPhone'] as String?,
        playerPhone: p['playerPhone'] as String?,
        imageUrl: p['image_url'] as String?,
        isActive: p['isActive'] as bool? ?? true,
        totalDue: _num(p['totalDue']),
        subscriptions: (p['subscriptions'] as List? ?? const [])
            .whereType<Map>()
            .map((s) => _sub(s.cast<String, dynamic>()))
            .toList(),
      );

  static DebtSubscriptionEntity _sub(Map<String, dynamic> s) =>
      DebtSubscriptionEntity(
        id: (s['_id'] ?? '').toString(),
        type: s['type'] == 'NEW_SUBSCRIPTION'
            ? SubscriptionType.newSubscription
            : SubscriptionType.renewal,
        amount: _num(s['amount']),
        paidAmount: _num(s['paidAmount']),
        remainingAmount: _num(s['remainingAmount']),
        startDate: DateTime.parse(s['startDate'] as String),
        endDate: DateTime.parse(s['endDate'] as String),
      );
}
