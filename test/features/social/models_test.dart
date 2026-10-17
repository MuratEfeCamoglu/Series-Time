import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/social/data/models.dart';

void main() {
  test('ProfileCounts.fromJson get_profile_counts kolonlarını ayrıştırır', () {
    final counts = ProfileCounts.fromJson({
      'followers': 12,
      'following': 3,
      'badges': 2,
    });
    expect(counts.followers, 12);
    expect(counts.following, 3);
    expect(counts.badges, 2);
  });

  test('FollowListEntry.fromJson get_follow_list kolonlarını ayrıştırır', () {
    final entry = FollowListEntry.fromJson({
      'id': 'u2',
      'username': 'burak',
      'display_name': 'Burak',
      'avatar_path': null,
      'followed_at': '2026-10-17T10:00:00+00:00',
    });
    expect(entry.userId, 'u2');
    expect(entry.username, 'burak');
    expect(entry.displayName, 'Burak');
    expect(entry.avatarPath, isNull);
    expect(entry.followedAt, DateTime.utc(2026, 10, 17, 10));
  });

  test(
    'FriendActivity.fromJson get_friends_activity kolonlarını ayrıştırır (F6k)',
    () {
      final a = FriendActivity.fromJson({
        'user_id': 'u2',
        'username': 'burak',
        'avatar_path': 'u2/a.png',
        'episode_id': 12,
        'show_id': 1,
        'show_name': 'Bitti',
        'poster_path': '/p.jpg',
        'still_path': '/s.jpg',
        'season_number': 1,
        'episode_number': 2,
        'rating': 4.5,
        'watched_at': '2026-10-18T09:00:00Z',
      });
      expect(a.userId, 'u2');
      expect(a.username, 'burak');
      expect(a.avatarPath, 'u2/a.png');
      expect(a.episodeId, 12);
      expect(a.showId, 1);
      expect(a.showName, 'Bitti');
      expect(a.posterPath, '/p.jpg');
      expect(a.stillPath, '/s.jpg');
      expect(a.seasonNumber, 1);
      expect(a.episodeNumber, 2);
      expect(a.rating, 4.5);
      expect(a.watchedAt, DateTime.utc(2026, 10, 18, 9));
      expect(
        FriendActivity.fromJson({
          'user_id': 'u2',
          'username': 'burak',
          'episode_id': 12,
          'show_id': 1,
          'show_name': 'Bitti',
          'season_number': 1,
          'episode_number': 2,
          'rating': null,
          'watched_at': '2026-10-18T09:00:00Z',
        }).rating,
        isNull,
      );
    },
  );
}
