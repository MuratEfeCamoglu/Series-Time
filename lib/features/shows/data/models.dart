import '../../../core/format.dart';

/// `shows` tablosu satırı (ISKELET.md §3.3). Arama/trend sonuçlarında yalnızca özet
/// alanlar doludur; detay alanları `show` eylemiyle gelir.
class Show {
  const Show({
    required this.id,
    required this.name,
    this.originalName,
    this.overview = '',
    this.posterPath,
    this.backdropPath,
    this.status,
    this.firstAirDate,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.defaultRuntime,
  });

  factory Show.fromJson(Map<String, dynamic> json) => Show(
    id: json['id'] as int,
    name: json['name'] as String,
    originalName: json['original_name'] as String?,
    overview: json['overview'] as String? ?? '',
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    status: json['status'] as String?,
    firstAirDate: parseDbDate(json['first_air_date']),
    numberOfSeasons: json['number_of_seasons'] as int?,
    numberOfEpisodes: json['number_of_episodes'] as int?,
    defaultRuntime: json['default_runtime'] as int?,
  );

  final int id;
  final String name;
  final String? originalName;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? status;
  final DateTime? firstAirDate;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final int? defaultRuntime;
}

/// `seasons` tablosu satırı.
class Season {
  const Season({
    required this.id,
    required this.showId,
    required this.seasonNumber,
    this.name,
    this.posterPath,
    this.airDate,
    this.episodeCount,
  });

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    id: json['id'] as int,
    showId: json['show_id'] as int,
    seasonNumber: json['season_number'] as int,
    name: json['name'] as String?,
    posterPath: json['poster_path'] as String?,
    airDate: parseDbDate(json['air_date']),
    episodeCount: json['episode_count'] as int?,
  );

  final int id;
  final int showId;
  final int seasonNumber;
  final String? name;
  final String? posterPath;
  final DateTime? airDate;
  final int? episodeCount;
}

/// `episodes` tablosu satırı.
class Episode {
  const Episode({
    required this.id,
    required this.showId,
    required this.seasonNumber,
    required this.episodeNumber,
    this.name,
    this.overview = '',
    this.airDate,
    this.runtime,
    this.stillPath,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json['id'] as int,
    showId: json['show_id'] as int,
    seasonNumber: json['season_number'] as int,
    episodeNumber: json['episode_number'] as int,
    name: json['name'] as String?,
    overview: json['overview'] as String? ?? '',
    airDate: parseDbDate(json['air_date']),
    runtime: json['runtime'] as int?,
    stillPath: json['still_path'] as String?,
  );

  final int id;
  final int showId;
  final int seasonNumber;
  final int episodeNumber;
  final String? name;
  final String overview;
  final DateTime? airDate;
  final int? runtime;
  final String? stillPath;
}

/// `tmdb-proxy` `show` eyleminin yanıtı.
class ShowDetail {
  const ShowDetail({required this.show, required this.seasons});

  factory ShowDetail.fromJson(Map<String, dynamic> json) => ShowDetail(
    show: Show.fromJson(json['show'] as Map<String, dynamic>),
    seasons: [
      for (final row in json['seasons'] as List)
        Season.fromJson(row as Map<String, dynamic>),
    ],
  );

  final Show show;
  final List<Season> seasons;
}

/// `tmdb-proxy` `search` eyleminin yanıtı.
class ShowSearchPage {
  const ShowSearchPage({required this.results, required this.totalPages});

  factory ShowSearchPage.fromJson(Map<String, dynamic> json) => ShowSearchPage(
    results: showsFromJson(json['results'] as List),
    totalPages: json['totalPages'] as int? ?? 0,
  );

  final List<Show> results;
  final int totalPages;
}

List<Show> showsFromJson(List rows) => [
  for (final row in rows) Show.fromJson(row as Map<String, dynamic>),
];

/// `user_shows` satırı ve ilişkili `shows` satırı (`select('*, shows(*)')`).
class UserShow {
  const UserShow({
    required this.show,
    required this.addedAt,
    this.lastWatchedAt,
  });

  factory UserShow.fromJson(Map<String, dynamic> json) => UserShow(
    show: Show.fromJson(json['shows'] as Map<String, dynamic>),
    addedAt: DateTime.parse(json['added_at'] as String),
    lastWatchedAt: switch (json['last_watched_at']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
  );

  final Show show;
  final DateTime addedAt;
  final DateTime? lastWatchedAt;
}
