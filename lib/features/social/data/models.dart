/// `get_profile_counts()` satırı (F8f, F12b).
class ProfileCounts {
  const ProfileCounts({
    required this.followers,
    required this.following,
    required this.badges,
  });

  factory ProfileCounts.fromJson(Map<String, dynamic> json) => ProfileCounts(
    followers: json['followers'] as int,
    following: json['following'] as int,
    badges: json['badges'] as int,
  );

  final int followers;
  final int following;
  final int badges;
}

/// `get_follow_list()` satırı: takipçi veya takip edilen kişi (F12c).
class FollowListEntry {
  const FollowListEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.followedAt,
    this.avatarPath,
  });

  factory FollowListEntry.fromJson(Map<String, dynamic> json) =>
      FollowListEntry(
        userId: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        avatarPath: json['avatar_path'] as String?,
        followedAt: DateTime.parse(json['followed_at'] as String),
      );

  final String userId;
  final String username;
  final String displayName;
  final String? avatarPath;
  final DateTime followedAt;
}

/// `get_friends_activity()` satırı: takip edilen kişinin son izlediği bölüm (F6k).
class FriendActivity {
  const FriendActivity({
    required this.userId,
    required this.username,
    required this.episodeId,
    required this.showId,
    required this.showName,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.watchedAt,
    this.avatarPath,
    this.posterPath,
    this.stillPath,
    this.rating,
  });

  factory FriendActivity.fromJson(Map<String, dynamic> json) => FriendActivity(
    userId: json['user_id'] as String,
    username: json['username'] as String,
    avatarPath: json['avatar_path'] as String?,
    episodeId: json['episode_id'] as int,
    showId: json['show_id'] as int,
    showName: json['show_name'] as String,
    posterPath: json['poster_path'] as String?,
    stillPath: json['still_path'] as String?,
    seasonNumber: json['season_number'] as int,
    episodeNumber: json['episode_number'] as int,
    rating: (json['rating'] as num?)?.toDouble(),
    watchedAt: DateTime.parse(json['watched_at'] as String),
  );

  final String userId;
  final String username;
  final String? avatarPath;
  final int episodeId;
  final int showId;
  final String showName;
  final String? posterPath;
  final String? stillPath;
  final int seasonNumber;
  final int episodeNumber;

  /// O bölüme verdiği puan (F20); vermediyse null.
  final double? rating;
  final DateTime watchedAt;
}
