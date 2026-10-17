import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/notifications/data/models.dart';
import 'package:sezonluk/features/notifications/logic.dart';

AppNotification _n({DateTime? readAt}) => AppNotification(
  id: 'n',
  type: NotificationType.newFollower,
  createdAt: DateTime.utc(2026, 10, 17),
  readAt: readAt,
);

void main() {
  test('okunmamış bildirimler sayılır', () {
    expect(
      countUnread([_n(), _n(readAt: DateTime.utc(2026, 10, 17)), _n()]),
      2,
    );
    expect(countUnread(const []), 0);
  });

  test('zil rozeti 99\'dan sonra 99+', () {
    expect(unreadBadgeLabel(5), '5');
    expect(unreadBadgeLabel(99), '99');
    expect(unreadBadgeLabel(100), '99+');
  });

  test('AppNotification.fromJson get_notifications kolonlarını ayrıştırır', () {
    final n = AppNotification.fromJson({
      'id': 'n1',
      'type': 'comment_liked',
      'actor_id': 'u1',
      'actor_username': 'ayse_1',
      'actor_display_name': 'Ayşe',
      'actor_avatar_path': null,
      'entity_id': 'c1',
      'badge_name': null,
      'episode_id': 63056,
      'read_at': null,
      'created_at': '2026-10-17T10:00:00+00:00',
    });

    expect(n.id, 'n1');
    expect(n.type, NotificationType.commentLiked);
    expect(n.actorId, 'u1');
    expect(n.actorUsername, 'ayse_1');
    expect(n.actorDisplayName, 'Ayşe');
    expect(n.entityId, 'c1');
    expect(n.episodeId, 63056);
    expect(n.isUnread, isTrue);
    expect(n.createdAt, DateTime.utc(2026, 10, 17, 10));
  });

  test('rozet ve takipçi türleri', () {
    AppNotification parse(String type) => AppNotification.fromJson({
      'id': 'n',
      'type': type,
      'created_at': '2026-10-17T10:00:00Z',
      'read_at': '2026-10-17T11:00:00Z',
    });
    expect(parse('new_follower').type, NotificationType.newFollower);
    expect(parse('badge_earned').type, NotificationType.badgeEarned);
    expect(parse('badge_earned').isUnread, isFalse);
  });
}
