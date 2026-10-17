import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/shows/data/models.dart';

const _showRow = {
  'id': 1399,
  'name': 'Taht Oyunları',
  'original_name': 'Game of Thrones',
  'overview': 'Yedi krallık...',
  'poster_path': '/poster.jpg',
  'backdrop_path': '/backdrop.jpg',
  'status': 'Ended',
  'first_air_date': '2011-04-17',
  'number_of_seasons': 8,
  'number_of_episodes': 73,
  'default_runtime': 60,
  'genre_ids': [18, 10765],
  'last_synced_at': '2026-10-17T10:00:00+00:00',
};

void main() {
  test('Show.fromJson §3.3 kolon adlarını ayrıştırır', () {
    final show = Show.fromJson(_showRow);

    expect(show.id, 1399);
    expect(show.name, 'Taht Oyunları');
    expect(show.originalName, 'Game of Thrones');
    expect(show.overview, 'Yedi krallık...');
    expect(show.posterPath, '/poster.jpg');
    expect(show.backdropPath, '/backdrop.jpg');
    expect(show.status, 'Ended');
    expect(show.firstAirDate, DateTime.utc(2011, 4, 17));
    expect(show.numberOfSeasons, 8);
    expect(show.numberOfEpisodes, 73);
    expect(show.defaultRuntime, 60);
    expect(show.genreIds, [18, 10765]);
  });

  test('Show.fromJson arama sonucundaki özet satırı kabul eder', () {
    final show = Show.fromJson({
      'id': 1,
      'name': 'Dizi',
      'original_name': null,
      'overview': null,
      'poster_path': null,
      'backdrop_path': null,
      'first_air_date': null,
    });

    expect(show.overview, '');
    expect(show.firstAirDate, isNull);
    expect(show.status, isNull);
    expect(show.numberOfSeasons, isNull);
    expect(show.genreIds, isEmpty);
  });

  test('Season.fromJson ve Episode.fromJson', () {
    final season = Season.fromJson({
      'id': 3624,
      'show_id': 1399,
      'season_number': 1,
      'name': '1. Sezon',
      'poster_path': '/s1.jpg',
      'air_date': '2011-04-17',
      'episode_count': 10,
      'last_synced_at': null,
    });
    expect(season.id, 3624);
    expect(season.showId, 1399);
    expect(season.seasonNumber, 1);
    expect(season.name, '1. Sezon');
    expect(season.posterPath, '/s1.jpg');
    expect(season.airDate, DateTime.utc(2011, 4, 17));
    expect(season.episodeCount, 10);

    final episode = Episode.fromJson({
      'id': 63056,
      'show_id': 1399,
      'season_number': 1,
      'episode_number': 1,
      'name': 'Kış Geliyor',
      'overview': 'Özet',
      'air_date': '2011-04-17',
      'runtime': 62,
      'still_path': '/still.jpg',
    });
    expect(episode.id, 63056);
    expect(episode.showId, 1399);
    expect(episode.seasonNumber, 1);
    expect(episode.episodeNumber, 1);
    expect(episode.name, 'Kış Geliyor');
    expect(episode.overview, 'Özet');
    expect(episode.airDate, DateTime.utc(2011, 4, 17));
    expect(episode.runtime, 62);
    expect(episode.stillPath, '/still.jpg');
  });

  test('ShowDetail ve ShowSearchPage tmdb-proxy yanıtlarını ayrıştırır', () {
    final detail = ShowDetail.fromJson({
      'show': _showRow,
      'seasons': [
        {'id': 1, 'show_id': 1399, 'season_number': 0},
        {'id': 2, 'show_id': 1399, 'season_number': 1},
      ],
    });
    expect(detail.show.id, 1399);
    expect(detail.seasons.map((s) => s.seasonNumber), [0, 1]);

    final page = ShowSearchPage.fromJson({
      'results': [_showRow],
      'totalPages': 3,
    });
    expect(page.results.single.name, 'Taht Oyunları');
    expect(page.totalPages, 3);
  });

  test('UserShow.fromJson user_shows + shows birleşimini ayrıştırır', () {
    final userShow = UserShow.fromJson({
      'user_id': '11111111-1111-1111-1111-111111111111',
      'show_id': 1399,
      'added_at': '2026-10-17T10:00:00+00:00',
      'last_watched_at': null,
      'shows': _showRow,
    });

    expect(userShow.show.id, 1399);
    expect(userShow.addedAt, DateTime.utc(2026, 10, 17, 10));
    expect(userShow.lastWatchedAt, isNull);
  });

  test('ShowCastMember.fromJson show_credits satırını ayrıştırır', () {
    final member = ShowCastMember.fromJson({
      'person_id': 22970,
      'name': 'Peter Dinklage',
      'character': 'Tyrion Lannister',
      'profile_path': '/p.jpg',
    });
    expect(member.personId, 22970);
    expect(member.name, 'Peter Dinklage');
    expect(member.character, 'Tyrion Lannister');
    expect(member.profilePath, '/p.jpg');
  });
}
