import 'package:equatable/equatable.dart';

/// نتيجة تسجيل الحضور القادمة من POST /attendance.
class AttendanceRecordResult extends Equatable {
  final bool recorded;
  final bool alreadyToday;
  final String playerName;
  final String playerCode;
  final String? sport;
  final String? imageUrl;
  final String message;

  const AttendanceRecordResult({
    required this.recorded,
    required this.alreadyToday,
    required this.playerName,
    required this.playerCode,
    this.sport,
    this.imageUrl,
    required this.message,
  });

  @override
  List<Object?> get props =>
      [recorded, alreadyToday, playerName, playerCode, sport, imageUrl, message];
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
  });

  @override
  List<Object?> get props =>
      [id, playerId, playerName, playerCode, imageUrl, sport, date, time, timestamp];
}
