import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/badges/data/models.dart';
import 'package:sezonluk/features/badges/logic.dart';

BadgeInfo _badge(String code) =>
    BadgeInfo(code: code, name: code, description: 'koşul', icon: code);

void main() {
  test('raf sabit sırada; kazanılanların tarihi var (F14)', () {
    final shelf = badgeShelf(
      [_badge('first_comment'), _badge('shows_10'), _badge('first_episode')],
      [EarnedBadge(code: 'shows_10', earnedAt: DateTime.utc(2026, 10, 1))],
    );

    expect(shelf.map((e) => e.badge.code), [
      'first_episode',
      'shows_10',
      'first_comment',
    ]);
    expect(shelf[0].earnedAt, isNull);
    expect(shelf[1].earnedAt, DateTime.utc(2026, 10, 1));
  });

  test('bilinmeyen rozet sona gelir', () {
    final shelf = badgeShelf([
      _badge('yeni'),
      _badge('first_episode'),
    ], const []);
    expect(shelf.map((e) => e.badge.code), ['first_episode', 'yeni']);
  });

  test('BadgeInfo ve EarnedBadge fromJson', () {
    final badge = BadgeInfo.fromJson({
      'code': 'first_episode',
      'name': 'İlk Bölüm',
      'description': 'İlk bölümünü izlendi olarak işaretle.',
      'icon': 'badge_first_episode',
    });
    expect(badge.code, 'first_episode');
    expect(badge.name, 'İlk Bölüm');
    expect(badge.description, 'İlk bölümünü izlendi olarak işaretle.');
    expect(badge.icon, 'badge_first_episode');

    final earned = EarnedBadge.fromJson({
      'user_id': 'u1',
      'badge_code': 'first_episode',
      'earned_at': '2026-10-17T10:00:00Z',
    });
    expect(earned.code, 'first_episode');
    expect(earned.earnedAt, DateTime.utc(2026, 10, 17, 10));
  });

  test('15 rozet; bölüm eşikleri artan sırada (F14)', () {
    expect(badgeOrder.length, 15);
    expect(badgeOrder.toSet().length, 15);
    final shelf = badgeShelf([
      _badge('episodes_5000'),
      _badge('episodes_10'),
      _badge('finished_5'),
      _badge('first_finished'),
    ], const []);
    expect(shelf.map((e) => e.badge.code), [
      'episodes_10',
      'episodes_5000',
      'first_finished',
      'finished_5',
    ]);
  });

  group('tür ve dizi rozetleri (F14)', () {
    test('tür rozeti kodu ayrıştırılır', () {
      expect(parseGenreBadge('genre_18_5'), (genreId: 18, tier: 5));
      expect(parseGenreBadge('first_episode'), isNull);
    });

    test('dizi rozeti bildirimi ayrıştırılır', () {
      expect(parseShowBadgeEntity('show:1399:2'), (
        showId: 1399,
        seasonNumber: 2,
      ));
      expect(parseShowBadgeEntity('show:1399:0'), (
        showId: 1399,
        seasonNumber: 0,
      ));
      expect(parseShowBadgeEntity('first_episode'), isNull);
      expect(parseShowBadgeEntity(null), isNull);
    });

    test('genel raf tür rozetlerini içermez; tür rafı kademe sıralı ve kazanılan tür önde', () {
      final all = [
        _badge('genre_35_10'),
        _badge('genre_18_5'),
        _badge('genre_35_1'),
        _badge('genre_18_1'),
        _badge('first_episode'),
      ];
      final earned = [
        EarnedBadge(code: 'genre_35_1', earnedAt: DateTime.utc(2026, 10, 1)),
      ];
      expect(badgeShelf(all, earned).map((e) => e.badge.code), [
        'first_episode',
      ]);
      final genres = genreShelf(all, earned);
      expect(genres.map((g) => g.genreId), [35, 18]);
      expect(genres.first.tiers.map((e) => e.badge.code), [
        'genre_35_1',
        'genre_35_10',
      ]);
      expect(genres.first.tiers.first.earnedAt, DateTime.utc(2026, 10, 1));
    });
  });

  group('vitrin (F14)', () {
    const a = BadgeRef.general('first_episode');
    const b = BadgeRef.show(1399, 0);

    test('ekler, aynı rozete tekrar dokununca çıkarır', () {
      final added = toggleFeatured(const [a], b);
      expect(added.featured, [a, b]);
      expect(added.rejected, isFalse);
      expect(toggleFeatured(added.featured, a).featured, [b]);
    });

    test('6 doluyken yeni rozet eklenmez', () {
      final full = [for (var i = 1; i <= 6; i++) BadgeRef.show(i, 1)];
      final result = toggleFeatured(full, a);
      expect(result.rejected, isTrue);
      expect(result.featured, full);
    });

    test('set_featured_badges öğeleri', () {
      expect(a.toJson(), {'badge_code': 'first_episode'});
      expect(b.toJson(), {'show_id': 1399, 'season_number': 0});
      expect(const BadgeRef.show(1, 2), const BadgeRef.show(1, 2));
    });
  });

  test('ShowBadge ve FeaturedBadge fromJson', () {
    final badge = ShowBadge.fromJson({
      'show_id': 1399,
      'season_number': 2,
      'show_name': 'Taht Oyunları',
      'poster_path': '/s2.jpg',
      'earned_at': '2026-10-18T10:00:00Z',
    });
    expect(badge.showId, 1399);
    expect(badge.seasonNumber, 2);
    expect(badge.showName, 'Taht Oyunları');
    expect(badge.posterPath, '/s2.jpg');
    expect(badge.earnedAt, DateTime.utc(2026, 10, 18, 10));
    expect(badge.isWholeShow, isFalse);

    final featured = FeaturedBadge.fromJson({
      'position': 2,
      'badge_code': null,
      'show_id': 1399,
      'season_number': 0,
      'show_name': 'Taht Oyunları',
      'poster_path': '/p.jpg',
    });
    expect(featured.position, 2);
    expect(featured.badgeCode, isNull);
    expect(featured.showId, 1399);
    expect(featured.seasonNumber, 0);
    expect(featured.showName, 'Taht Oyunları');
    expect(featured.posterPath, '/p.jpg');
    expect(BadgeRef.fromFeatured(featured), const BadgeRef.show(1399, 0));
  });
}
