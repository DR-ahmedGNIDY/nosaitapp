import 'package:equatable/equatable.dart';

enum NotificationType {
  birthday,
  subscriptionExpiring,
  subscriptionExpired,
  system,
  // إشعارات قادمة من السيرفر (/notifications).
  message,
  albumComment,
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
  // true = إشعار محفوظ على السيرفر (المقروء يُحفظ هناك)، false = محسوب محلياً.
  final bool fromServer;
  final Map<String, dynamic> meta;

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
    this.fromServer = false,
    this.meta = const {},
  });

  /// من عنصر `/notifications` على السيرفر.
  factory NotificationEntity.fromServerJson(Map<String, dynamic> j) {
    final meta = (j['meta'] is Map)
        ? Map<String, dynamic>.from(j['meta'] as Map)
        : <String, dynamic>{};
    final type = switch (j['type']) {
      'NEW_MESSAGE' => NotificationType.message,
      'ALBUM_COMMENT' => NotificationType.albumComment,
      _ => NotificationType.system,
    };
    final count = (meta['count'] as num?)?.toInt() ?? 1;
    var body = (j['body'] ?? '').toString();
    if (type == NotificationType.message && count > 1) {
      body = '$body\n($count رسائل جديدة)';
    }
    return NotificationEntity(
      id: (j['_id'] ?? j['id']).toString(),
      type: type,
      title: (j['title'] ?? '').toString(),
      body: body,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      isRead: j['isRead'] == true,
      playerId: meta['playerId']?.toString(),
      playerName: meta['playerName']?.toString(),
      fromServer: true,
      meta: meta,
    );
  }

  /// تخزين محلي للإشعارات المحسوبة (أعياد الميلاد/الاشتراكات) لعرضها فوراً.
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'playerId': playerId,
        'parentPhone': parentPhone,
        'playerName': playerName,
        'academyName': academyName,
      };

  factory NotificationEntity.fromCacheJson(Map<String, dynamic> j) =>
      NotificationEntity(
        id: j['id'] as String,
        type: NotificationType.values.firstWhere((t) => t.name == j['type'],
            orElse: () => NotificationType.system),
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isRead: j['isRead'] == true,
        playerId: j['playerId'] as String?,
        parentPhone: j['parentPhone'] as String?,
        playerName: j['playerName'] as String?,
        academyName: j['academyName'] as String?,
      );

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
        fromServer: fromServer,
        meta: meta,
      );

  @override
  List<Object?> get props => [
        id, type, title, body, createdAt, isRead, playerId, parentPhone,
        playerName, academyName, fromServer,
      ];
}
