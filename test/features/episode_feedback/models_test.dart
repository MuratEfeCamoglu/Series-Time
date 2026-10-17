import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/episode_feedback/data/models.dart';

void main() {
  test('EpisodeInfo.fromJson bölüm ve dizi adını ayrıştırır', () {
    final info = EpisodeInfo.fromJson({
      'id': 63056,
      'show_id': 1399,
      'season_number': 1,
      'episode_number': 1,
      'name': 'Kış Geliyor',
      'overview': '',
      'air_date': '2011-04-17',
      'runtime': 62,
      'still_path': null,
      'shows': {'name': 'Taht Oyunları'},
    });

    expect(info.episode.id, 63056);
    expect(info.showName, 'Taht Oyunları');
  });

  test('CastMember.fromJson episode_credits kolonlarını ayrıştırır', () {
    final member = CastMember.fromJson({
      'episode_id': 63056,
      'person_id': 22970,
      'name': 'Peter Dinklage',
      'character': 'Tyrion Lannister',
      'profile_path': '/p.jpg',
      'order': 0,
      'last_synced_at': '2026-10-17T00:00:00Z',
    });

    expect(member.personId, 22970);
    expect(member.name, 'Peter Dinklage');
    expect(member.character, 'Tyrion Lannister');
    expect(member.profilePath, '/p.jpg');
    expect(member.order, 0);
  });

  test('StarStat.fromJson get_episode_star_stats kolonlarını ayrıştırır', () {
    final stat = StarStat.fromJson({
      'person_id': 22970,
      'name': 'Peter Dinklage',
      'character': 'Tyrion',
      'profile_path': null,
      'votes': 3,
      'total_votes': 4,
    });

    expect(stat.personId, 22970);
    expect(stat.name, 'Peter Dinklage');
    expect(stat.character, 'Tyrion');
    expect(stat.votes, 3);
    expect(stat.totalVotes, 4);
  });

  test('StarStat kadrodan çıkmış kişide boş ad kabul eder', () {
    final stat = StarStat.fromJson({
      'person_id': 1,
      'name': null,
      'character': null,
      'profile_path': null,
      'votes': 1,
      'total_votes': 1,
    });
    expect(stat.name, '');
  });

  test('EpisodeComment.fromJson ve beğeni değişimi', () {
    final comment = EpisodeComment.fromJson({
      'id': 'c1',
      'user_id': 'u1',
      'username': 'ayse_1',
      'display_name': 'Ayşe',
      'avatar_path': null,
      'body': 'Harika',
      'is_spoiler': true,
      'created_at': '2026-10-17T10:00:00+00:00',
      'like_count': 2,
      'liked_by_me': false,
    });

    expect(comment.id, 'c1');
    expect(comment.userId, 'u1');
    expect(comment.username, 'ayse_1');
    expect(comment.displayName, 'Ayşe');
    expect(comment.body, 'Harika');
    expect(comment.isSpoiler, isTrue);
    expect(comment.createdAt, DateTime.utc(2026, 10, 17, 10));
    expect(comment.likeCount, 2);
    expect(comment.likedByMe, isFalse);

    final liked = comment.withLike(liked: true);
    expect(liked.likeCount, 3);
    expect(liked.likedByMe, isTrue);
    expect(liked.withLike(liked: false).likeCount, 2);
    expect(liked.withLike(liked: true).likeCount, 3);
  });

  test('reactionFromName enum adlarını eşler', () {
    expect(reactionFromName('love'), ReactionType.love);
    expect(reactionFromName(null), isNull);
    expect(reactionFromName('bilinmeyen'), isNull);
  });

  test(
    'RatingSummary.fromJson get_episode_rating_stats ve kendi değerleri',
    () {
      final summary = RatingSummary.fromJson(
        {'average': 3.8, 'rating_count': 2, 'like_count': 5},
        myRating: 4.5,
        liked: true,
      );
      expect(summary.average, 3.8);
      expect(summary.ratingCount, 2);
      expect(summary.likeCount, 5);
      expect(summary.myRating, 4.5);
      expect(summary.liked, isTrue);

      final empty = RatingSummary.fromJson({
        'average': null,
        'rating_count': 0,
        'like_count': 0,
      });
      expect(empty.average, isNull);
      expect(empty.myRating, isNull);
      expect(empty.liked, isFalse);
    },
  );
}
