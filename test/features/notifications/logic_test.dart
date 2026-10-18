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
      'show_name': null,
    });

    expect(n.id, 'n1');
    expect(n.showName, isNull);
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

  test('MyWatchItem.fromJson get_my_watch_feed kolonlarını ayrıştırır', () {
    final w = MyWatchItem.fromJson({
      'show_id': 1399,
      'show_name': 'Taht Oyunları',
      'poster_path': '/p.jpg',
      'backdrop_path': '/b.jpg',
      'still_path': '/s.jpg',
      'episode_id': 63056,
      'season_number': 1,
      'episode_number': 3,
      'episode_count': 3,
      'happened_at': '2026-10-18T10:00:00+00:00',
    });

    expect(w.showId, 1399);
    expect(w.showName, 'Taht Oyunları');
    expect(w.posterPath, '/p.jpg');
    expect(w.backdropPath, '/b.jpg');
    expect(w.stillPath, '/s.jpg');
    expect(w.episodeId, 63056);
    expect(w.seasonNumber, 1);
    expect(w.episodeNumber, 3);
    expect(w.episodeCount, 3);
    expect(w.happenedAt, DateTime.utc(2026, 10, 18, 10));
  });

  group('mergeMeFeed', () {
    MyWatchItem watch(int hour) => MyWatchItem(
      showId: 1,
      showName: 'Bir',
      episodeId: hour,
      seasonNumber: 1,
      episodeNumber: 1,
      happenedAt: DateTime.utc(2026, 10, 18, hour),
    );
    AppNotification notification(int hour) => AppNotification(
      id: 'n$hour',
      type: NotificationType.newFollower,
      createdAt: DateTime.utc(2026, 10, 18, hour),
    );

    test('bildirimler ve izlemeler en yeniden eskiye karışık sıralanır', () {
      final merged = mergeMeFeed(
        [notification(12), notification(9)],
        [watch(11), watch(8)],
      );
      expect(merged.map((e) => e.time.hour), [12, 11, 9, 8]);
      expect(merged[0], isA<NotificationEntry>());
      expect(merged[1], isA<WatchEntry>());
    });

    test('aynı anda olanlarda bildirim önce gelir', () {
      final merged = mergeMeFeed([notification(10)], [watch(10)]);
      expect(merged.first, isA<NotificationEntry>());
    });

    test('ikisi de boşsa liste boş', () {
      expect(mergeMeFeed(const [], const []), isEmpty);
    });
  });
}
