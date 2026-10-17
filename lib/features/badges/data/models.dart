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
