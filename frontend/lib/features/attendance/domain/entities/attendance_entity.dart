import 'package:equatable/equatable.dart';

/// حضور/غياب اللاعب داخل اشتراكه الأخير.
/// active → منذ بداية الاشتراك النشط. expired → في الاشتراك السابق
/// (آخر اشتراك كان نشطاً). none → لا يوجد أي اشتراك.
class AttendanceSubscriptionStats extends Equatable {
  final String status; // 'active' | 'expired' | 'none'
  final String? startDate; // 'YYYY-MM-DD'
  final String? endDate;
  final int present;
  final int absent;
  final int expected; // المتوقع حتى اليوم (أو كامل الفترة لو منتهي)
  final int expectedTotal; // المتوقع على كامل فترة الاشتراك

  const AttendanceSubscriptionStats({
    required this.status,
    this.startDate,
    this.endDate,
    required this.present,
    required this.absent,
    required this.expected,
    required this.expectedTotal,
  });

  bool get isActive => status == 'active';
  bool get hasSubscription => status != 'none';

  factory AttendanceSubscriptionStats.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map?;
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AttendanceSubscriptionStats(
      status: (json['status'] ?? 'none').toString(),
      startDate: sub?['startDate']?.toString(),
      endDate: sub?['endDate']?.toString(),
      present: n('present'),
      absent: n('absent'),
      expected: n('expected'),
      expectedTotal: n('expectedTotal'),
    );
  }

  @override
  List<Object?> get props =>
      [status, startDate, endDate, present, absent, expected, expectedTotal];
}

/// لاعب في نتائج بحث سجل الحضور (GET /attendance/players).
class AttendancePlayer extends Equatable {
  final String id;
  final String fullName;
  final String playerCode;
  final String? sport;
  final String? imageUrl;

  const AttendancePlayer({
    required this.id,
    required this.fullName,
    required this.playerCode,
    this.sport,
    this.imageUrl,
  });

  factory AttendancePlayer.fromJson(Map<String, dynamic> json) =>
      AttendancePlayer(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        fullName: (json['fullName'] ?? '').toString(),
        playerCode: (json['playerCode'] ?? '').toString(),
        sport: json['sport'] as String?,
        imageUrl: json['image_url'] as String?,
      );

  @override
  List<Object?> get props => [id, fullName, playerCode, sport, imageUrl];
}

/// ملخص حضور لاعب (GET /attendance/player/:id/summary).
class AttendancePlayerSummary extends Equatable {
  final AttendancePlayer player;
  final AttendanceSubscriptionStats stats;

  const AttendancePlayerSummary({required this.player, required this.stats});

  @override
  List<Object?> get props => [player, stats];
}

/// نتيجة تسجيل الحضور القادمة من POST /attendance.
class AttendanceRecordResult extends Equatable {
  final bool recorded;
  final bool alreadyToday;
  final bool subscriptionExpired;
  final String? playerId;
  final String playerName;
  final String playerCode;
  final String? sport;
  final String? imageUrl;
  final String message;

  /// حضور/غياب اللاعب في اشتراكه الأخير (null مع سيرفر قديم).
  final AttendanceSubscriptionStats? stats;

  /// نوع الحضور المسجّل (AttendanceKind).
  final String kind;

  const AttendanceRecordResult({
    required this.recorded,
    required this.alreadyToday,
    this.subscriptionExpired = false,
    this.playerId,
    required this.playerName,
    required this.playerCode,
    this.sport,
    this.imageUrl,
    required this.message,
    this.stats,
    this.kind = AttendanceKind.regular,
  });

  @override
  List<Object?> get props => [
        stats,
        kind,
        recorded,
        alreadyToday,
        subscriptionExpired,
        playerId,
        playerName,
        playerCode,
        sport,
        imageUrl,
        message,
      ];
}

/// نوع الحضور: regular | pay_later | makeup | free.
class AttendanceKind {
  AttendanceKind._();
  static const regular = 'regular';
  static const payLater = 'pay_later';
  static const makeup = 'makeup';
  static const free = 'free';

  /// عنوان الشارة المميزة (null للحضور العادي).
  static String? label(String kind) {
    switch (kind) {
      case payLater:
        return 'دفع لاحقاً';
      case makeup:
        return 'تعويض غياب';
      case free:
        return 'حصة مجانية';
      default:
        return null;
    }
  }
}

/// سطر في سجل الحضور القادم من GET /attendance.
class AttendanceLogEntry extends Equatable {
  final String id;
  final String playerId;
  final String playerName;
  final String playerCode;
  final String? imageUrl;
  final String? sport;
  final String date; // 'YYYY-MM-DD'
  final String time; // 'HH:mm'
  final DateTime timestamp;
  final String kind; // AttendanceKind

  const AttendanceLogEntry({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.playerCode,
    this.imageUrl,
    this.sport,
    required this.date,
    required this.time,
    required this.timestamp,
    this.kind = AttendanceKind.regular,
  });

  @override
  List<Object?> get props => [
        id,
        playerId,
        playerName,
        playerCode,
        imageUrl,
        sport,
        date,
        time,
        timestamp,
        kind,
      ];
}
