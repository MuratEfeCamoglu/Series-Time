/// `badges` tablosu satırı (F14). Material `Badge` ile çakışmasın diye BadgeInfo.
class BadgeInfo {
  const BadgeInfo({
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory BadgeInfo.fromJson(Map<String, dynamic> json) => BadgeInfo(
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    icon: json['icon'] as String,
  );

  final String code;
  final String name;

  /// Rozetin kazanılma koşulu; kazanılmamış rozetin altında gösterilir.
  final String description;
  final String icon;
}

/// `user_badges` satırı.
class EarnedBadge {
  const EarnedBadge({required this.code, required this.earnedAt});

  factory EarnedBadge.fromJson(Map<String, dynamic> json) => EarnedBadge(
    code: json['badge_code'] as String,
    earnedAt: DateTime.parse(json['earned_at'] as String),
  );

  final String code;
  final DateTime earnedAt;
}

/// `get_show_badges()` satırı: bitirilen sezon veya dizi (F14). [seasonNumber] 0 = dizinin tamamı.
class ShowBadge {
  const ShowBadge({
    required this.showId,
    required this.seasonNumber,
    required this.showName,
    required this.earnedAt,
    this.posterPath,
  });

  factory ShowBadge.fromJson(Map<String, dynamic> json) => ShowBadge(
    showId: json['show_id'] as int,
    seasonNumber: json['season_number'] as int,
    showName: json['show_name'] as String,
    posterPath: json['poster_path'] as String?,
    earnedAt: DateTime.parse(json['earned_at'] as String),
  );

  final int showId;
  final int seasonNumber;
  final String showName;

  /// Sezon rozetinde sezon afişi, yoksa dizinin afişi.
  final String? posterPath;
  final DateTime earnedAt;

  bool get isWholeShow => seasonNumber == 0;
}

/// `get_featured_badges()` satırı: profildeki rozet vitrininde bir yer (F14, en fazla 6).
/// Ya genel rozet ([badgeCode]) ya dizi/sezon rozetidir ([showId], [seasonNumber]).
class FeaturedBadge {
  const FeaturedBadge({
    required this.position,
    this.badgeCode,
    this.showId,
    this.seasonNumber,
    this.showName,
    this.posterPath,
  });

  factory FeaturedBadge.fromJson(Map<String, dynamic> json) => FeaturedBadge(
    position: json['position'] as int,
    badgeCode: json['badge_code'] as String?,
    showId: json['show_id'] as int?,
    seasonNumber: json['season_number'] as int?,
    showName: json['show_name'] as String?,
    posterPath: json['poster_path'] as String?,
  );

  final int position;
  final String? badgeCode;
  final int? showId;
  final int? seasonNumber;
  final String? showName;
  final String? posterPath;
}
