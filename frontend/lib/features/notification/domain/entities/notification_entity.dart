import 'package:equatable/equatable.dart';

enum NotificationType {
  birthday,
  subscriptionExpiring,
  subscriptionExpired,
  system,
}

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? playerId;
  // بيانات لازمة لفتح WhatsApp مباشرةً عند الضغط على الإشعار.
  final String? parentPhone;
  final String? playerName;
  final String? academyName;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.playerId,
    this.parentPhone,
    this.playerName,
    this.academyName,
  });

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        playerId: playerId,
        parentPhone: parentPhone,
        playerName: playerName,
        academyName: academyName,
      );

  @override
  List<Object?> get props =>
      [id, type, title, body, createdAt, isRead, playerId, parentPhone, playerName, academyName];
}
