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
    this.coverPath,
    this.letterboxdUsername,
    this.instagramUsername,
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
    coverPath: json['cover_path'] as String?,
    letterboxdUsername: json['letterboxd_username'] as String?,
    instagramUsername: json['instagram_username'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? countryCode;
  final String? avatarPath;
  final int? coverShowId;

  /// Seçilen TMDB arka plan görseli; null ise dizinin ana arka planı (V9).
  final String? coverPath;

  /// F8(i): yalnızca kullanıcı adları saklanır; adres istemcide kurulur.
  final String? letterboxdUsername;
  final String? instagramUsername;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'country_code': countryCode,
    'avatar_path': avatarPath,
    'cover_show_id': coverShowId,
    'cover_path': coverPath,
    'letterboxd_username': letterboxdUsername,
    'instagram_username': instagramUsername,
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
    this.coverPath,
    this.letterboxdUsername,
    this.instagramUsername,
    this.avatarBytes,
  });

  final String username;
  final String displayName;
  final String bio;
  final String? countryCode;

  /// null: kapak seçilmemiş (V9: son izlenen dizinin arka planı kullanılır).
  final int? coverShowId;
  final String? coverPath;

  /// null: bağlantı yok.
  final String? letterboxdUsername;
  final String? instagramUsername;

  /// Kare kırpılmış PNG avatar (galeriden veya dizi görselinden).
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
