/// Engellenen kullanıcı: `blocks` satırı ve engellenenin profil özeti (F15c).
class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarPath,
  });

  /// `profiles` satırından; `blocks.blocked_id` = `profiles.id`.
  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
    userId: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    avatarPath: json['avatar_path'] as String?,
  );

  final String userId;
  final String username;
  final String displayName;
  final String? avatarPath;
}
