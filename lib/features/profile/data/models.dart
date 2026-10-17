/// `profiles` tablosu satırı (ISKELET.md §3.3).
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.createdAt,
    this.countryCode,
    this.avatarPath,
    this.coverShowId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    bio: json['bio'] as String? ?? '',
    // `char(2)` kolonu Postgres'te boşlukla doldurulabilir.
    countryCode: (json['country_code'] as String?)?.trim(),
    avatarPath: json['avatar_path'] as String?,
    coverShowId: json['cover_show_id'] as int?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? countryCode;
  final String? avatarPath;
  final int? coverShowId;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'country_code': countryCode,
    'avatar_path': avatarPath,
    'cover_show_id': coverShowId,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Profil düzenleme ekranından gelen değişiklikler. [avatarBytes] null ise avatar değişmez.
class ProfileEdit {
  const ProfileEdit({
    required this.username,
    required this.displayName,
    required this.bio,
    required this.countryCode,
    required this.coverShowId,
    this.avatarBytes,
  });

  final String username;
  final String displayName;
  final String bio;
  final String? countryCode;

  /// null: kapak seçilmemiş (V9: son izlenen dizinin arka planı kullanılır).
  final int? coverShowId;
  final List<int>? avatarBytes;
}

/// `get_user_stats()` satırı (F8d).
class UserStats {
  const UserStats({required this.watchedEpisodes, required this.watchMinutes});

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    watchedEpisodes: json['watched_episodes'] as int,
    watchMinutes: json['watch_minutes'] as int,
  );

  final int watchedEpisodes;
  final int watchMinutes;
}
