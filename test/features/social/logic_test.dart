import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/social/data/models.dart';
import 'package:sezonluk/features/social/logic.dart';

void main() {
  test('kişi kendini takip edemez (F12d)', () {
    expect(canFollow(viewerId: 'a', targetId: 'a'), isFalse);
    expect(canFollow(viewerId: 'a', targetId: 'b'), isTrue);
  });

  test('takip/bırakma takipçi sayısını değiştirir (F12b)', () {
    const counts = ProfileCounts(followers: 2, following: 5, badges: 1);
    final followed = withFollowerChange(counts, follow: true);
    expect(followed.followers, 3);
    expect(followed.following, 5);
    expect(followed.badges, 1);
    expect(withFollowerChange(counts, follow: false).followers, 1);
  });

  test('takipçi sayısı eksiye düşmez', () {
    const counts = ProfileCounts(followers: 0, following: 0, badges: 0);
    expect(withFollowerChange(counts, follow: false).followers, 0);
  });

  test('30\'luk tam sayfadan sonra devamı olabilir (F12c)', () {
    expect(hasMoreFollows(30), isTrue);
    expect(hasMoreFollows(29), isFalse);
  });

  test('liste adları RPC parametresiyle aynı', () {
    expect(FollowList.values.map((l) => l.name), ['followers', 'following']);
  });
}
