import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';

/// بيانات إيصال دفعة واحدة كما يرجعها الـ API
/// (GET /subscriptions/:id/payments/:paymentId/receipt أو GET /player/receipts).
class ReceiptEntity {
  final String receiptNoLabel;
  final String subscriptionId;
  final String paymentId;
  final double amount;
  final DateTime date;
  final String method;
  final String note;
  final String recordedByName;
  final SubscriptionType subscriptionType;
  final double subscriptionAmount;
  final DateTime startDate;
  final DateTime endDate;
  final double paidToDate;
  final double remainingAfter;
  final String playerName;
  final String playerCode;
  final String parentName;
  final String parentPhone;
  final String playerPhone;
  final String academyName;
  final String academyLogoUrl;
  final String academyPhone;
  final String academyAddress;
  final String currencyCode;

  const ReceiptEntity({
    required this.receiptNoLabel,
    required this.subscriptionId,
    required this.paymentId,
    required this.amount,
    required this.date,
    required this.method,
    required this.note,
    required this.recordedByName,
    required this.subscriptionType,
    required this.subscriptionAmount,
    required this.startDate,
    required this.endDate,
    required this.paidToDate,
    required this.remainingAfter,
    required this.playerName,
    required this.playerCode,
    required this.parentName,
    required this.parentPhone,
    required this.playerPhone,
    required this.academyName,
    required this.academyLogoUrl,
    required this.academyPhone,
    required this.academyAddress,
    required this.currencyCode,
  });

  String get methodLabel => PaymentMethods.label(method);

  String get typeLabel => subscriptionType == SubscriptionType.newSubscription
      ? 'اشتراك جديد'
      : 'تجديد';

  bool get fullyPaid => remainingAfter <= 0.005;

  /// رقم التواصل: ولي الأمر أولاً ثم اللاعب.
  String? get contactPhone {
    if (parentPhone.trim().isNotEmpty) return parentPhone;
    if (playerPhone.trim().isNotEmpty) return playerPhone;
    return null;
  }

  factory ReceiptEntity.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> m(String k) =>
        (json[k] as Map?)?.cast<String, dynamic>() ?? const {};
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;
    String s(dynamic v) => (v ?? '').toString();
    DateTime d(dynamic v) =>
        v is String ? DateTime.parse(v).toLocal() : DateTime.now();

    final pay = m('payment');
    final sub = m('subscription');
    final player = m('player');
    final academy = m('academy');
    return ReceiptEntity(
      receiptNoLabel: s(json['receiptNoLabel']),
      subscriptionId: s(sub['_id']),
      paymentId: s(pay['_id']),
      amount: n(pay['amount']),
      date: d(pay['date']),
      method: s(pay['method']).isEmpty ? 'cash' : s(pay['method']),
      note: s(pay['note']),
      recordedByName: s(pay['recordedByName']),
      subscriptionType: sub['type'] == 'NEW_SUBSCRIPTION'
          ? SubscriptionType.newSubscription
          : SubscriptionType.renewal,
      subscriptionAmount: n(sub['amount']),
      startDate: d(sub['startDate']),
      endDate: d(sub['endDate']),
      paidToDate: n(sub['paidToDate']),
      remainingAfter: n(sub['remainingAfter']),
      playerName: s(player['fullName']),
      playerCode: s(player['playerCode']),
      parentName: s(player['parentName']),
      parentPhone: s(player['parentPhone']),
      playerPhone: s(player['playerPhone']),
      academyName: s(academy['name']),
      academyLogoUrl: s(academy['logo_url']),
      academyPhone: s(academy['phone']),
      academyAddress: s(academy['address']),
      currencyCode: s(academy['currency']).isEmpty ? 'EGP' : s(academy['currency']),
    );
  }
}
