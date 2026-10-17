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
}
