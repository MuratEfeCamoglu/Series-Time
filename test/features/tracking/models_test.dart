import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/tracking/data/models.dart';

void main() {
  test('WatchlistItem.fromJson get_watchlist kolonlarını ayrıştırır', () {
    final item = WatchlistItem.fromJson({
      'show_id': 1399,
      'name': 'Taht Oyunları',
      'poster_path': '/p.jpg',
      'added_at': '2026-10-01T10:00:00+00:00',
      'last_watched_at': '2026-10-16T21:00:00+00:00',
      'next_episode_id': 63057,
      'next_season_number': 1,
      'next_episode_number': 2,
      'next_episode_name': 'Kral Yolu',
      'next_still_path': '/sahne.jpg',
      'backdrop_path': '/arka.jpg',
      'aired_count': 73,
      'watched_count': 1,
    });

    expect(item.showId, 1399);
    expect(item.name, 'Taht Oyunları');
    expect(item.posterPath, '/p.jpg');
    expect(item.addedAt, DateTime.utc(2026, 10, 1, 10));
    expect(item.lastWatchedAt, DateTime.utc(2026, 10, 16, 21));
    expect(item.nextEpisodeId, 63057);
    expect(item.nextSeasonNumber, 1);
    expect(item.nextEpisodeNumber, 2);
    expect(item.nextEpisodeName, 'Kral Yolu');
    expect(item.nextStillPath, '/sahne.jpg');
    expect(item.backdropPath, '/arka.jpg');
    expect(item.airedCount, 73);
    expect(item.watchedCount, 1);
    expect(item.pending, isFalse);
  });

  test('WatchlistItem hiç izlenmemiş dizide last_watched_at boş', () {
    final item = WatchlistItem.fromJson({
      'show_id': 1,
      'name': 'D',
      'poster_path': null,
      'added_at': '2026-10-01T10:00:00Z',
      'last_watched_at': null,
      'next_episode_id': 1,
      'next_season_number': 1,
      'next_episode_number': 1,
      'aired_count': 1,
      'watched_count': 0,
    });

    expect(item.lastWatchedAt, isNull);
    final pending = item.markedPending(DateTime.utc(2026, 10, 17));
    expect(pending.pending, isTrue);
    expect(pending.watchedCount, 1);
    expect(pending.lastWatchedAt, DateTime.utc(2026, 10, 17));
  });

  test('UpcomingEpisode.fromJson get_upcoming kolonlarını ayrıştırır', () {
    final episode = UpcomingEpisode.fromJson({
      'episode_id': 5,
      'show_id': 1399,
      'show_name': 'Taht Oyunları',
      'poster_path': null,
      'season_number': 9,
      'episode_number': 1,
      'episode_name': 'Yeni',
      'air_date': '2026-10-18',
    });

    expect(episode.episodeId, 5);
    expect(episode.showId, 1399);
    expect(episode.showName, 'Taht Oyunları');
    expect(episode.posterPath, isNull);
    expect(episode.seasonNumber, 9);
    expect(episode.episodeNumber, 1);
    expect(episode.episodeName, 'Yeni');
    expect(episode.airDate, DateTime.utc(2026, 10, 18));
  });

  test(
    'ShowProgress.fromJson get_user_show_progress kolonlarını ayrıştırır',
    () {
      final p = ShowProgress.fromJson({
        'show_id': 1399,
        'name': 'Taht Oyunları',
        'poster_path': '/p.jpg',
        'backdrop_path': '/b.jpg',
        'show_status': 'Ended',
        'added_at': '2026-10-01T10:00:00Z',
        'last_watched_at': null,
        'manual_status': 'paused',
        'aired_count': 73,
        'watched_count': 10,
      });
      expect(p.showId, 1399);
      expect(p.name, 'Taht Oyunları');
      expect(p.posterPath, '/p.jpg');
      expect(p.backdropPath, '/b.jpg');
      expect(p.showStatus, 'Ended');
      expect(p.addedAt, DateTime.utc(2026, 10, 1, 10));
      expect(p.lastWatchedAt, isNull);
      expect(p.manualStatus, ManualShowStatus.paused);
      expect(p.airedCount, 73);
      expect(p.watchedCount, 10);
      expect(p.withManualStatus(null).manualStatus, isNull);
    },
  );

  test('WatchlistItem show_status ve manual_status', () {
    final item = WatchlistItem.fromJson({
      'show_id': 1,
      'name': 'D',
      'added_at': '2026-10-01T10:00:00Z',
      'next_episode_id': 1,
      'next_season_number': 1,
      'next_episode_number': 1,
      'aired_count': 2,
      'watched_count': 0,
      'show_status': 'Returning Series',
      'manual_status': 'planned',
    });
    expect(item.showStatus, 'Returning Series');
    expect(item.manualStatus, ManualShowStatus.planned);
    // İşaretleyince İzleme Listesi seçimi otomatiğe döner.
    expect(item.markedPending(DateTime.utc(2026)).manualStatus, isNull);
    expect(manualShowStatusFromName('bilinmeyen'), isNull);
  });

  test('ShowProgress is_favorite ve RecentEpisode.fromJson (F8j, F8k)', () {
    final p = ShowProgress.fromJson({
      'show_id': 1,
      'name': 'D',
      'added_at': '2026-10-01T10:00:00Z',
      'manual_status': 'paused',
      'is_favorite': true,
      'aired_count': 1,
      'watched_count': 0,
    });
    expect(p.isFavorite, isTrue);
    expect(p.withFavorite(false).isFavorite, isFalse);
    expect(p.withFavorite(false).manualStatus, ManualShowStatus.paused);
    expect(p.withManualStatus(null).isFavorite, isTrue);

    final e = RecentEpisode.fromJson({
      'episode_id': 63056,
      'show_id': 1399,
      'show_name': 'Taht Oyunları',
      'poster_path': '/p.jpg',
      'season_number': 1,
      'episode_number': 2,
      'episode_name': 'Kral Yolu',
      'watched_at': '2026-10-17T20:00:00Z',
    });
    expect(e.episodeId, 63056);
    expect(e.showId, 1399);
    expect(e.showName, 'Taht Oyunları');
    expect(e.posterPath, '/p.jpg');
    expect(e.seasonNumber, 1);
    expect(e.episodeNumber, 2);
    expect(e.episodeName, 'Kral Yolu');
    expect(e.watchedAt, DateTime.utc(2026, 10, 17, 20));
  });
}
