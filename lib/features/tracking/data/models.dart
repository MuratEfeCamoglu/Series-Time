import '../../../core/format.dart';

/// F6(j): kullanıcının elle seçtiği grup; adlar `manual_show_status` enum değerleriyle aynıdır.
enum ManualShowStatus { paused, dropped, planned }

ManualShowStatus? manualShowStatusFromName(Object? name) =>
    name is String ? ManualShowStatus.values.asNameMap()[name] : null;

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
    this.showStatus,
    this.manualStatus,
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
    showStatus: json['show_status'] as String?,
    manualStatus: manualShowStatusFromName(json['manual_status']),
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

  /// TMDB durumu ("Ended", "Returning Series"…) ve elle seçilen grup: kart rengi (F6j).
  final String? showStatus;
  final ManualShowStatus? manualStatus;

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
    showStatus: showStatus,
    // Durduruldu/İzleme Listesi işaretleyince otomatiğe döner (veritabanı tetikleyicisi).
    manualStatus: manualStatus == ManualShowStatus.dropped
        ? manualStatus
        : null,
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
    this.stillPath,
    this.backdropPath,
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
        stillPath: json['still_path'] as String?,
        backdropPath: json['backdrop_path'] as String?,
      );

  final int episodeId;
  final int showId;
  final String showName;
  final String? posterPath;
  final int seasonNumber;
  final int episodeNumber;
  final String? episodeName;
  final DateTime airDate;

  /// Satırın görseli: bölümün sahne görseli, yoksa dizinin arka planı (F7).
  final String? stillPath;
  final String? backdropPath;
}

/// `get_user_show_progress()` satırı: listedeki dizi, ilerleme sayıları ve grup bilgisi (F6j).
class ShowProgress {
  const ShowProgress({
    required this.showId,
    required this.name,
    required this.addedAt,
    required this.airedCount,
    required this.watchedCount,
    this.posterPath,
    this.backdropPath,
    this.showStatus,
    this.lastWatchedAt,
    this.manualStatus,
    this.isFavorite = false,
  });

  factory ShowProgress.fromJson(Map<String, dynamic> json) => ShowProgress(
    showId: json['show_id'] as int,
    name: json['name'] as String,
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    showStatus: json['show_status'] as String?,
    addedAt: DateTime.parse(json['added_at'] as String),
    lastWatchedAt: switch (json['last_watched_at']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
    manualStatus: manualShowStatusFromName(json['manual_status']),
    isFavorite: json['is_favorite'] as bool? ?? false,
    airedCount: json['aired_count'] as int,
    watchedCount: json['watched_count'] as int,
  );

  final int showId;
  final String name;
  final String? posterPath;
  final String? backdropPath;
  final String? showStatus;
  final DateTime addedAt;
  final DateTime? lastWatchedAt;
  final ManualShowStatus? manualStatus;

  /// F8(j): profildeki favori dizilerden biri.
  final bool isFavorite;
  final int airedCount;
  final int watchedCount;

  ShowProgress withManualStatus(ManualShowStatus? status) =>
      _copy(manualStatus: status);

  ShowProgress withFavorite(bool favorite) => _copy(isFavorite: favorite);

  ShowProgress _copy({Object? manualStatus = _unchanged, bool? isFavorite}) =>
      ShowProgress(
        showId: showId,
        name: name,
        posterPath: posterPath,
        backdropPath: backdropPath,
        showStatus: showStatus,
        addedAt: addedAt,
        lastWatchedAt: lastWatchedAt,
        manualStatus: identical(manualStatus, _unchanged)
            ? this.manualStatus
            : manualStatus as ManualShowStatus?,
        isFavorite: isFavorite ?? this.isFavorite,
        airedCount: airedCount,
        watchedCount: watchedCount,
      );
}

const _unchanged = Object();

/// `get_recent_activity()` satırı: profildeki son izlenen bölüm (F8k).
class RecentEpisode {
  const RecentEpisode({
    required this.episodeId,
    required this.showId,
    required this.showName,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.watchedAt,
    this.posterPath,
    this.backdropPath,
    this.stillPath,
    this.episodeName,
  });

  factory RecentEpisode.fromJson(Map<String, dynamic> json) => RecentEpisode(
    episodeId: json['episode_id'] as int,
    showId: json['show_id'] as int,
    showName: json['show_name'] as String,
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    stillPath: json['still_path'] as String?,
    seasonNumber: json['season_number'] as int,
    episodeNumber: json['episode_number'] as int,
    episodeName: json['episode_name'] as String?,
    watchedAt: DateTime.parse(json['watched_at'] as String),
  );

  final int episodeId;
  final int showId;
  final String showName;
  final String? posterPath;
  final String? backdropPath;

  /// Bölümün sahne görseli (F8k); yoksa arka plan, o da yoksa afiş kullanılır.
  final String? stillPath;
  final int seasonNumber;
  final int episodeNumber;
  final String? episodeName;
  final DateTime watchedAt;
}
