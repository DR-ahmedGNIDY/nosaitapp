import 'package:basketball_academy/features/subscription/data/models/academy_debts_model.dart';
import 'package:basketball_academy/features/subscription/data/models/subscription_model.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _sub([Map<String, dynamic> extra = const {}]) => {
      '_id': 's1',
      'academyId': 'a1',
      'playerId': 'p1',
      'type': 'RENEWAL',
      'amount': 500,
      'startDate': '2026-11-01T00:00:00.000Z',
      'endDate': '2026-12-01T00:00:00.000Z',
      'created_at': '2026-11-01T00:00:00.000Z',
      ...extra,
    };

void main() {
  test('legacy subscription without paidAmount is fully paid', () {
    final e = SubscriptionModel.fromJson(_sub()).toEntity();
    expect(e.paidAmount, 500);
    expect(e.remainingAmount, 0);
    expect(e.paymentStatus, PaymentStatus.paid);
    expect(e.payments, isEmpty);
  });

  test('partial subscription parses payments and remaining', () {
    final e = SubscriptionModel.fromJson(_sub({
      'paidAmount': 200,
      'payments': [
        {
          '_id': 'pay1',
          'amount': 200,
          'date': '2026-11-02T10:00:00.000Z',
          'method': 'instapay',
          'recordedByName': 'مدير',
        },
      ],
    })).toEntity();
    expect(e.paymentStatus, PaymentStatus.partial);
    expect(e.remainingAmount, 300);
    expect(e.payments.single.methodLabel, 'إنستاباي');
    expect(e.payments.single.recordedByName, 'مدير');
  });

  test('unpaid subscription', () {
    final e = SubscriptionModel.fromJson(_sub({'paidAmount': 0, 'payments': []})).toEntity();
    expect(e.paymentStatus, PaymentStatus.unpaid);
    expect(e.hasDebt, isTrue);
  });

  test('debts response parses players and summary', () {
    final d = AcademyDebtsModel.fromJson({
      'summary': {'totalOutstanding': 300, 'playersCount': 1, 'subscriptionsCount': 1},
      'players': [
        {
          'playerId': 'p1',
          'fullName': 'علي',
          'playerCode': 'A1',
          'parentPhone': '',
          'playerPhone': '01012345678',
          'totalDue': 300,
          'subscriptions': [
            {
              '_id': 's1',
              'type': 'NEW_SUBSCRIPTION',
              'amount': 500,
              'paidAmount': 200,
              'remainingAmount': 300,
              'startDate': '2026-11-01T00:00:00.000Z',
              'endDate': '2026-12-01T00:00:00.000Z',
            },
          ],
        },
      ],
    });
    expect(d.totalOutstanding, 300);
    expect(d.players.single.contactPhone, '01012345678');
    expect(d.players.single.subscriptions.single.typeLabel, 'اشتراك جديد');
  });
}
