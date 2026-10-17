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
}
