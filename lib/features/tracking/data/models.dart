import '../../../core/format.dart';

/// `get_watchlist()` satırı: sıradaki bölümü olan dizi ve ilerleme sayıları (F6).
class WatchlistItem {
  const WatchlistItem({
    required this.showId,
    required this.name,
    required this.addedAt,
    required this.nextEpisodeId,
    required this.nextSeasonNumber,
    required this.nextEpisodeNumber,
    required this.airedCount,
    required this.watchedCount,
    this.posterPath,
    this.lastWatchedAt,
    this.nextEpisodeName,
    this.nextStillPath,
    this.backdropPath,
    this.pending = false,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
    showId: json['show_id'] as int,
    name: json['name'] as String,
    posterPath: json['poster_path'] as String?,
    addedAt: DateTime.parse(json['added_at'] as String),
    lastWatchedAt: switch (json['last_watched_at']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
    nextEpisodeId: json['next_episode_id'] as int,
    nextSeasonNumber: json['next_season_number'] as int,
    nextEpisodeNumber: json['next_episode_number'] as int,
    nextEpisodeName: json['next_episode_name'] as String?,
    nextStillPath: json['next_still_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    airedCount: json['aired_count'] as int,
    watchedCount: json['watched_count'] as int,
  );

  final int showId;
  final String name;
  final String? posterPath;
  final DateTime addedAt;
  final DateTime? lastWatchedAt;
  final int nextEpisodeId;
  final int nextSeasonNumber;
  final int nextEpisodeNumber;
  final String? nextEpisodeName;

  /// Kartın solundaki yatay görsel: sıradaki bölümün sahnesi, yoksa dizinin arka planı.
  final String? nextStillPath;
  final String? backdropPath;
  final int airedCount;
  final int watchedCount;

  /// Sıradaki bölüm işaretlendi, sunucu yanıtı bekleniyor (iyimser güncelleme, F5e).
  final bool pending;

  WatchlistItem markedPending(DateTime now) => WatchlistItem(
    showId: showId,
    name: name,
    posterPath: posterPath,
    addedAt: addedAt,
    lastWatchedAt: now,
    nextEpisodeId: nextEpisodeId,
    nextSeasonNumber: nextSeasonNumber,
    nextEpisodeNumber: nextEpisodeNumber,
    nextEpisodeName: nextEpisodeName,
    nextStillPath: nextStillPath,
    backdropPath: backdropPath,
    airedCount: airedCount,
    watchedCount: watchedCount + 1,
    pending: true,
  );
}

/// `get_upcoming()` satırı (F7).
class UpcomingEpisode {
  const UpcomingEpisode({
    required this.episodeId,
    required this.showId,
    required this.showName,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.airDate,
    this.posterPath,
    this.episodeName,
  });

  factory UpcomingEpisode.fromJson(Map<String, dynamic> json) =>
      UpcomingEpisode(
        episodeId: json['episode_id'] as int,
        showId: json['show_id'] as int,
        showName: json['show_name'] as String,
        posterPath: json['poster_path'] as String?,
        seasonNumber: json['season_number'] as int,
        episodeNumber: json['episode_number'] as int,
        episodeName: json['episode_name'] as String?,
        airDate: parseDbDate(json['air_date'])!,
      );

  final int episodeId;
  final int showId;
  final String showName;
  final String? posterPath;
  final int seasonNumber;
  final int episodeNumber;
  final String? episodeName;
  final DateTime airDate;
}
