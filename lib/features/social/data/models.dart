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
