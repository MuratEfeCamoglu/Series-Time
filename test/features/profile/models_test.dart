import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/profile/data/models.dart';

void main() {
  test('Profile.fromJson §3.3 kolon adlarını ayrıştırır', () {
    final profile = Profile.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'username': 'ayse_1',
      'display_name': 'Ayşe',
      'bio': 'Dizi kurdu',
      'country_code': 'TR',
      'avatar_path': '11111111-1111-1111-1111-111111111111/1.jpg',
      'cover_show_id': 1399,
      'created_at': '2026-10-01T12:00:00+00:00',
    });

    expect(profile.id, '11111111-1111-1111-1111-111111111111');
    expect(profile.username, 'ayse_1');
    expect(profile.displayName, 'Ayşe');
    expect(profile.bio, 'Dizi kurdu');
    expect(profile.countryCode, 'TR');
    expect(profile.avatarPath, '11111111-1111-1111-1111-111111111111/1.jpg');
    expect(profile.coverShowId, 1399);
    expect(profile.createdAt, DateTime.utc(2026, 10, 1, 12));
  });

  test('Profile.fromJson boş alanları kabul eder', () {
    final profile = Profile.fromJson({
      'id': 'x',
      'username': 'abc',
      'display_name': 'abc',
      'bio': '',
      'country_code': null,
      'avatar_path': null,
      'cover_show_id': null,
      'created_at': '2026-10-01T12:00:00Z',
    });

    expect(profile.countryCode, isNull);
    expect(profile.avatarPath, isNull);
    expect(profile.coverShowId, isNull);
  });

  test('toJson → fromJson aynı profili verir', () {
    final original = Profile(
      id: 'x',
      username: 'abc',
      displayName: 'Abc',
      bio: 'b',
      countryCode: 'DE',
      createdAt: DateTime.utc(2026, 1, 2),
    );
    final copy = Profile.fromJson(original.toJson());

    expect(copy.toJson(), original.toJson());
  });

  test('UserStats.fromJson get_user_stats kolonlarını ayrıştırır', () {
    final stats = UserStats.fromJson({
      'watched_episodes': 73,
      'watch_minutes': 4380,
    });

    expect(stats.watchedEpisodes, 73);
    expect(stats.watchMinutes, 4380);
  });

  test('Profile.fromJson cover_path kolonunu ayrıştırır', () {
    final profile = Profile.fromJson({
      'id': 'x',
      'username': 'abc',
      'display_name': 'abc',
      'bio': '',
      'country_code': null,
      'avatar_path': 'tmdb:/kisi.jpg',
      'cover_show_id': 1399,
      'cover_path': '/arka.jpg',
      'created_at': '2026-10-01T12:00:00Z',
    });
    expect(profile.coverPath, '/arka.jpg');
    expect(profile.avatarPath, 'tmdb:/kisi.jpg');
  });

  test('Profile.fromJson sosyal kullanıcı adlarını ayrıştırır (F2, F8i)', () {
    final profile = Profile.fromJson({
      'id': 'u',
      'username': 'ayse_1',
      'display_name': 'Ayşe',
      'bio': '',
      'created_at': '2026-10-01T00:00:00Z',
      'letterboxd_username': 'ayse_lb',
      'instagram_username': 'ayse.dizi',
    });
    expect(profile.letterboxdUsername, 'ayse_lb');
    expect(profile.instagramUsername, 'ayse.dizi');
    expect(profile.toJson()['letterboxd_username'], 'ayse_lb');
    expect(profile.toJson()['instagram_username'], 'ayse.dizi');
  });
}
