import 'package:basketball_academy/features/subscription/data/models/academy_debts_model.dart';
import 'package:basketball_academy/features/subscription/data/models/subscription_model.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/domain/entities/receipt_entity.dart';
import 'package:basketball_academy/features/subscription/services/receipt_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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

Map<String, dynamic> _receiptJson({double remaining = 300}) => {
      'receiptNoLabel': '000007',
      'payment': {
        '_id': 'pay1',
        'amount': 200,
        'date': '2026-11-02T10:00:00.000Z',
        'method': 'instapay',
        'recordedByName': 'مدير',
      },
      'subscription': {
        '_id': 's1',
        'type': 'NEW_SUBSCRIPTION',
        'amount': 500,
        'startDate': '2026-11-01T00:00:00.000Z',
        'endDate': '2026-12-01T00:00:00.000Z',
        'paidToDate': 500 - remaining,
        'remainingAfter': remaining,
      },
      'player': {'fullName': 'علي', 'playerCode': 'A1', 'parentPhone': '', 'playerPhone': '0101'},
      'academy': {'name': 'أكاديمية', 'logo_url': '', 'currency': 'EGP'},
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('ar'));

  test('receipt parses and builds a PDF + WhatsApp summary', () async {
    final r = ReceiptEntity.fromJson(_receiptJson());
    expect(r.receiptNoLabel, '000007');
    expect(r.methodLabel, 'إنستاباي');
    expect(r.fullyPaid, isFalse);
    expect(r.contactPhone, '0101');
    expect(r.typeLabel, 'اشتراك جديد');

    final bytes = await ReceiptPdfService.build(r);
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    final text = ReceiptPdfService.textSummary(r);
    expect(text, contains('000007'));
    expect(text, contains('المتبقي: 300'));
    expect(ReceiptPdfService.textSummary(ReceiptEntity.fromJson(_receiptJson(remaining: 0))),
        contains('مدفوع بالكامل'));
    expect(ReceiptPdfService.fileName(r), 'receipt_000007.pdf');
  });

  test('payment receiptNo is parsed', () {
    final e = SubscriptionModel.fromJson(_sub({
      'paidAmount': 100,
      'payments': [
        {'_id': 'p', 'amount': 100, 'date': '2026-11-02T10:00:00.000Z', 'receiptNo': 12},
      ],
    })).toEntity();
    expect(e.payments.single.receiptNo, 12);
  });

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

  test('collectedInMonth uses payment dates; legacy counts on created_at', () {
    final legacy = SubscriptionModel.fromJson(_sub()).toEntity();
    expect(legacy.collectedInMonth(2026, 11), 500);
    expect(legacy.collectedInMonth(2026, 10), 0);

    final partial = SubscriptionModel.fromJson(_sub({
      'paidAmount': 300,
      'payments': [
        {'_id': 'a', 'amount': 100, 'date': '2026-10-15T10:00:00.000Z'},
        {'_id': 'b', 'amount': 200, 'date': '2026-11-15T10:00:00.000Z'},
      ],
    })).toEntity();
    expect(partial.collectedInMonth(2026, 10), 100);
    expect(partial.collectedInMonth(2026, 11), 200);
    expect(partial.remainingAmount, 200);
  });

  test('freeze state parses and changes the display status', () {
    final e = SubscriptionModel.fromJson(_sub({
      'endDate': '2099-12-01T00:00:00.000Z',
      'freezeStatus': 'frozen',
      'currentFreeze': {
        'startDate': '2099-11-01T00:00:00.000Z',
        'endDate': '2099-11-15T00:00:00.000Z',
        'days': 14,
        'reason': 'injury',
      },
    })).toEntity();
    expect(e.isFrozen, isTrue);
    expect(e.hasOpenFreeze, isTrue);
    expect(e.freezeDays, 14);
    expect(e.displayStatus, 'مجمّد');
    expect(SubscriptionEntity.freezeReasonLabel(e.freezeReason), 'إصابة');
    expect(e.freezeLastDay!.isBefore(e.freezeEnd!), isTrue);

    final none = SubscriptionModel.fromJson(_sub({'endDate': '2099-12-01T00:00:00.000Z'})).toEntity();
    expect(none.hasOpenFreeze, isFalse);
    expect(none.displayStatus, isNot('مجمّد'));
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
