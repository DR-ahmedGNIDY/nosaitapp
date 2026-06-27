import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';

/// تحويل سجل حضور (مع playerId مُعبَّأ) إلى AttendanceLogEntry.
class AttendanceLogMapper {
  static AttendanceLogEntry fromJson(Map<String, dynamic> json) {
    final rawPlayer = json['playerId'];
    String playerId = '';
    String playerName = '';
    String playerCode = '';
    String? imageUrl;
    if (rawPlayer is Map) {
      playerId = (rawPlayer['_id'] ?? rawPlayer['id'] ?? '').toString();
      playerName = (rawPlayer['fullName'] ?? '').toString();
      playerCode = (rawPlayer['playerCode'] ?? '').toString();
      imageUrl = rawPlayer['image_url'] as String?;
    } else if (rawPlayer != null) {
      playerId = rawPlayer.toString();
    }

    return AttendanceLogEntry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      playerId: playerId,
      playerName: playerName,
      playerCode: playerCode,
      imageUrl: imageUrl,
      sport: json['sport'] as String?,
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

/// تحويل استجابة POST /attendance إلى AttendanceRecordResult.
class AttendanceRecordMapper {
  static AttendanceRecordResult fromResponse(
    Map<String, dynamic> data,
    String message,
  ) {
    final player = (data['player'] as Map?) ?? const {};
    return AttendanceRecordResult(
      recorded: data['recorded'] == true,
      alreadyToday: data['alreadyToday'] == true,
      playerName: (player['fullName'] ?? '').toString(),
      playerCode: (player['playerCode'] ?? '').toString(),
      sport: player['sport'] as String?,
      imageUrl: player['image_url'] as String?,
      message: message,
    );
  }
}
