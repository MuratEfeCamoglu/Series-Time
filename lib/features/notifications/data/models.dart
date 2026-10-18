/// Adlar `notification_type` enum değerleriyle aynıdır (F13a).
enum NotificationType { newFollower, commentLiked, badgeEarned }

NotificationType _typeFromDb(String value) => switch (value) {
  'new_follower' => NotificationType.newFollower,
  'comment_liked' => NotificationType.commentLiked,
  'badge_earned' => NotificationType.badgeEarned,
  _ => throw FormatException('Bilinmeyen bildirim türü: $value'),
};

/// `get_notifications()` satırı. Yorum metni hiçbir zaman gelmez (R7).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    this.actorId,
    this.actorUsername,
    this.actorDisplayName,
    this.actorAvatarPath,
    this.entityId,
    this.badgeName,
    this.episodeId,
    this.readAt,
    this.showName,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: _typeFromDb(json['type'] as String),
        actorId: json['actor_id'] as String?,
        actorUsername: json['actor_username'] as String?,
        actorDisplayName: json['actor_display_name'] as String?,
        actorAvatarPath: json['actor_avatar_path'] as String?,
        entityId: json['entity_id'] as String?,
        badgeName: json['badge_name'] as String?,
        episodeId: json['episode_id'] as int?,
        readAt: switch (json['read_at']) {
          final String value => DateTime.parse(value),
          _ => null,
        },
        createdAt: DateTime.parse(json['created_at'] as String),
        showName: json['show_name'] as String?,
      );

  final String id;
  final NotificationType type;
  final String? actorId;
  final String? actorUsername;
  final String? actorDisplayName;
  final String? actorAvatarPath;

  /// Beğenilen yorumun kimliği veya kazanılan rozetin kodu.
  final String? entityId;
  final String? badgeName;

  /// Beğenilen yorumun bölümü; yorum silindiyse null.
  final int? episodeId;
  final DateTime? readAt;
  final DateTime createdAt;

  /// Dizi/sezon rozeti bildiriminde (`entity_id` = `show:<dizi>:<sezon>`) dizinin adı.
  final String? showName;

  bool get isUnread => readAt == null;
}

/// `get_my_watch_feed()` satırı: Bildirimler › Ben'de kendi izlemen (F13f).
/// Aynı gün aynı dizide izlenen bölümler tek satırdır; okunmamış sayacına girmez.
class MyWatchItem {
  const MyWatchItem({
    required this.showId,
    required this.showName,
    required this.episodeId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.happenedAt,
    this.posterPath,
    this.backdropPath,
    this.stillPath,
    this.episodeCount = 1,
  });

  factory MyWatchItem.fromJson(Map<String, dynamic> json) => MyWatchItem(
    showId: json['show_id'] as int,
    showName: json['show_name'] as String,
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    stillPath: json['still_path'] as String?,
    episodeId: json['episode_id'] as int,
    seasonNumber: json['season_number'] as int,
    episodeNumber: json['episode_number'] as int,
    episodeCount: json['episode_count'] as int? ?? 1,
    happenedAt: DateTime.parse(json['happened_at'] as String),
  );

  final int showId;
  final String showName;
  final String? posterPath;
  final String? backdropPath;
  final String? stillPath;

  /// O gün izlenen en son bölüm.
  final int episodeId;
  final int seasonNumber;
  final int episodeNumber;
  final int episodeCount;
  final DateTime happenedAt;
}
