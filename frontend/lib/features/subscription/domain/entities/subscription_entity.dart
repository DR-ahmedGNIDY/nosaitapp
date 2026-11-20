import 'package:equatable/equatable.dart';

enum SubscriptionType { newSubscription, renewal }

enum SubscriptionStatus { active, expired }

/// حالة دفع الاشتراك (الدفع الجزئي).
enum PaymentStatus { paid, partial, unpaid }

/// طرق الدفع — المفاتيح مطابقة لـ PAYMENT_METHODS في الـ backend.
class PaymentMethods {
  PaymentMethods._();

  static const List<String> all = [
    'cash',
    'vodafone_cash',
    'instapay',
    'bank_transfer',
    'card',
    'other',
  ];

  static String label(String method) => switch (method) {
        'cash' => 'كاش',
        'vodafone_cash' => 'فودافون كاش',
        'instapay' => 'إنستاباي',
        'bank_transfer' => 'تحويل بنكي',
        'card' => 'بطاقة',
        _ => 'أخرى',
      };
}

/// دفعة واحدة من مبلغ الاشتراك.
class SubscriptionPaymentEntity extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String method;
  final String? note;
  final String recordedByName;
  /// رقم الإيصال (null للدفعات القديمة قبل أول طلب لإيصالها).
  final int? receiptNo;

  const SubscriptionPaymentEntity({
    required this.id,
    required this.amount,
    required this.date,
    this.method = 'cash',
    this.note,
    this.recordedByName = '',
    this.receiptNo,
  });

  String get methodLabel => PaymentMethods.label(method);

  @override
  List<Object?> get props => [id, amount, date, method, note, recordedByName, receiptNo];
}

class SubscriptionEntity extends Equatable {
  final String id;
  final String academyId;
  final String playerId;
  /// اسم اللاعب — مُستخرَج من populate الـ backend
  final String playerName;
  final String playerCode;
  final String? playerPhone;
  final String? playerImageUrl;
  final SubscriptionType type;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  /// عدد حصص الاشتراك (null = بلا حدّ).
  final int? sessionsLimit;
  /// لحظة استهلاك آخر حصة — الاشتراك منتهٍ منذها حتى لو لم ينتهِ تاريخه.
  final DateTime? exhaustedAt;
  /// المدفوع من مبلغ الاشتراك (null من سيرفر قديم ⇒ مدفوع بالكامل).
  final double? paidAmountRaw;
  /// سجل الدفعات (فارغ للاشتراكات القديمة).
  final List<SubscriptionPaymentEntity> payments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SubscriptionEntity({
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
    this.paidAmountRaw,
    this.payments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  bool get isExhausted => exhaustedAt != null;

  double get paidAmount => paidAmountRaw ?? amount;

  double get remainingAmount {
    final r = amount - paidAmount;
    return r > 0.005 ? r : 0;
  }

  PaymentStatus get paymentStatus {
    if (remainingAmount <= 0) return PaymentStatus.paid;
    if (paidAmount <= 0.005) return PaymentStatus.unpaid;
    return PaymentStatus.partial;
  }

  bool get hasDebt => remainingAmount > 0;

  /// الدفعات الفعلية — الاشتراك القديم بلا سجل = دفعة واحدة يوم الإنشاء.
  List<SubscriptionPaymentEntity> get effectivePayments {
    if (payments.isNotEmpty || paidAmount <= 0) return payments;
    return [
      SubscriptionPaymentEntity(id: '', amount: paidAmount, date: createdAt),
    ];
  }

  /// المُحصَّل فعلاً داخل شهر معيّن (بتاريخ الدفع).
  double collectedInMonth(int year, int month) => effectivePayments
      .where((p) {
        final d = p.date.toLocal();
        return d.year == year && d.month == month;
      })
      .fold<double>(0, (sum, p) => sum + p.amount);

  String get paymentStatusLabel => switch (paymentStatus) {
        PaymentStatus.paid => 'مدفوع',
        PaymentStatus.partial => 'مدفوع جزئياً',
        PaymentStatus.unpaid => 'غير مدفوع',
      };

  SubscriptionStatus get status =>
      !isExhausted && !DateTime.now().isAfter(endDate)
          ? SubscriptionStatus.active
          : SubscriptionStatus.expired;

  bool get isActive => status == SubscriptionStatus.active;

  String get typeLabel =>
      type == SubscriptionType.newSubscription ? 'اشتراك جديد' : 'تجديد';

  String get statusLabel => isActive ? 'نشط' : 'منتهي';

  /// أيام متبقية حتى انتهاء الاشتراك (سالب إذا كان منتهياً)
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  bool get isExpiringSoon => isActive && daysRemaining <= 7;

  /// نشط | ينتهي قريباً | منتهي — لا يوجد مفهوم "مجمد" في الـ backend حالياً
  String get displayStatus {
    if (!isActive) return 'منتهي';
    if (isExpiringSoon) return 'ينتهي قريباً';
    return 'نشط';
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        playerId,
        playerName,
        playerCode,
        playerPhone,
        playerImageUrl,
        type,
        amount,
        startDate,
        endDate,
        notes,
        sessionsLimit,
        exhaustedAt,
        paidAmountRaw,
        payments,
        createdAt,
        updatedAt,
      ];
}
