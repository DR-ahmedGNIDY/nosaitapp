import 'package:basketball_academy/features/notification/domain/entities/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('server NEW_MESSAGE maps to message with player info and count', () {
    final n = NotificationEntity.fromServerJson({
      '_id': 'n1',
      'type': 'NEW_MESSAGE',
      'title': 'رسالة جديدة من أحمد',
      'body': 'مرحبا',
      'isRead': false,
      'createdAt': '2026-11-10T10:00:00.000Z',
      'meta': {'playerId': 'p1', 'playerName': 'أحمد', 'count': 3},
    });
    expect(n.type, NotificationType.message);
    expect(n.fromServer, isTrue);
    expect(n.playerId, 'p1');
    expect(n.playerName, 'أحمد');
    expect(n.body, contains('3 رسائل'));
    expect(n.isRead, isFalse);
  });

  test('ALBUM_COMMENT and unknown types map correctly', () {
    final a = NotificationEntity.fromServerJson(
        {'_id': 'a', 'type': 'ALBUM_COMMENT', 'title': 't', 'isRead': true});
    expect(a.type, NotificationType.albumComment);
    expect(a.isRead, isTrue);
    final u = NotificationEntity.fromServerJson(
        {'_id': 'u', 'type': 'MATCH_ADDED', 'title': 't'});
    expect(u.type, NotificationType.system);
  });

  test('local cache JSON round-trips', () {
    final n = NotificationEntity(
      id: 'birthday_p1_2026',
      type: NotificationType.birthday,
      title: 'عيد ميلاد',
      body: 'b',
      createdAt: DateTime(2026, 11, 13, 8),
      playerId: 'p1',
      parentPhone: '010',
      playerName: 'أحمد',
      academyName: 'A',
    );
    expect(NotificationEntity.fromCacheJson(n.toCacheJson()), n);
  });

  test('copyWith keeps server fields', () {
    final n = NotificationEntity.fromServerJson(
        {'_id': 'x', 'type': 'NEW_MESSAGE', 'title': 't', 'meta': {'playerId': 'p'}});
    final r = n.copyWith(isRead: true);
    expect(r.fromServer, isTrue);
    expect(r.playerId, 'p');
    expect(r.isRead, isTrue);
  });
}
