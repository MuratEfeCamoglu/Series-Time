/// F14 saf kuralları: rozet rafının sırası, tür ve dizi rozetleri, vitrin seçimi.
library;

import 'data/models.dart';

/// Genel rozetler koşulların zorluğuna göre sıralanır (ISKELET.md F14 sırası).
const badgeOrder = [
  'first_episode',
  'episodes_10',
  'episodes_50',
  'episodes_100',
  'episodes_500',
  'episodes_1000',
  'episodes_5000',
  'shows_10',
  'shows_25',
  'shows_50',
  'first_finished',
  'finished_5',
  'first_comment',
  'comments_10',
  'comments_50',
];

/// Tür rozeti kademeleri: o türde bitirilmiş dizi sayısı (F14).
const genreBadgeTiers = [1, 5, 10];

/// Profildeki rozet vitrininin boyutu (F14).
const maxFeaturedBadges = 6;

/// `genre_<türId>_<kademe>` kodundan tür ve kademe; tür rozeti değilse null.
({int genreId, int tier})? parseGenreBadge(String code) {
  final match = RegExp(r'^genre_(\d+)_(\d+)$').firstMatch(code);
  if (match == null) return null;
  return (genreId: int.parse(match[1]!), tier: int.parse(match[2]!));
}

/// Dizi rozeti bildiriminin `entity_id`'si `show:<dizi>:<sezon>` (0 = dizinin tamamı).
({int showId, int seasonNumber})? parseShowBadgeEntity(String? entityId) {
  final match = RegExp(r'^show:(\d+):(\d+)$').firstMatch(entityId ?? '');
  if (match == null) return null;
  return (showId: int.parse(match[1]!), seasonNumber: int.parse(match[2]!));
}

typedef ShelfEntry = ({BadgeInfo badge, DateTime? earnedAt});

/// Genel rozetler (tür rozetleri hariç), her biri kazanıldıysa tarihiyle. Bilinmeyen kodlar
/// sona, kendi aralarında koda göre gelir.
List<ShelfEntry> badgeShelf(List<BadgeInfo> all, List<EarnedBadge> earned) {
  final earnedAt = {for (final e in earned) e.code: e.earnedAt};
  int rank(BadgeInfo badge) {
    final index = badgeOrder.indexOf(badge.code);
    return index == -1 ? badgeOrder.length : index;
  }

  final general =
      [
        for (final badge in all)
          if (parseGenreBadge(badge.code) == null) badge,
      ]..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.code.compareTo(b.code);
      });
  return [
    for (final badge in general) (badge: badge, earnedAt: earnedAt[badge.code]),
  ];
}

/// Tür rozetleri tür başına gruplu (kademeler 1, 5, 10 sırasıyla); en çok kademesi kazanılmış
/// tür önce, eşitse tür kimliğine göre.
List<({int genreId, List<ShelfEntry> tiers})> genreShelf(
  List<BadgeInfo> all,
  List<EarnedBadge> earned,
) {
  final earnedAt = {for (final e in earned) e.code: e.earnedAt};
  final byGenre = <int, List<ShelfEntry>>{};
  for (final badge in all) {
    final parsed = parseGenreBadge(badge.code);
    if (parsed == null) continue;
    byGenre.putIfAbsent(parsed.genreId, () => []).add((
      badge: badge,
      earnedAt: earnedAt[badge.code],
    ));
  }
  int tierOf(ShelfEntry e) => parseGenreBadge(e.badge.code)!.tier;
  int earnedCount(List<ShelfEntry> tiers) =>
      tiers.where((e) => e.earnedAt != null).length;
  final groups = [
    for (final MapEntry(:key, :value) in byGenre.entries)
      (
        genreId: key,
        tiers: value..sort((a, b) => tierOf(a).compareTo(tierOf(b))),
      ),
  ];
  return groups..sort((a, b) {
    final byEarned = earnedCount(b.tiers).compareTo(earnedCount(a.tiers));
    return byEarned != 0 ? byEarned : a.genreId.compareTo(b.genreId);
  });
}

/// Vitrindeki bir rozetin kimliği: genel rozet kodu ya da dizi + sezon (0 = dizinin tamamı).
final class BadgeRef {
  const BadgeRef.general(String this.code) : showId = null, seasonNumber = null;

  const BadgeRef.show(int this.showId, int this.seasonNumber) : code = null;

  factory BadgeRef.fromFeatured(FeaturedBadge badge) => switch (badge) {
    FeaturedBadge(badgeCode: final code?) => BadgeRef.general(code),
    FeaturedBadge(showId: final show?, seasonNumber: final season?) =>
      BadgeRef.show(show, season),
    _ => throw ArgumentError('Vitrin satırında rozet yok: ${badge.position}'),
  };

  final String? code;
  final int? showId;
  final int? seasonNumber;

  /// `set_featured_badges` öğesi.
  Map<String, Object> toJson() => switch (code) {
    final code? => {'badge_code': code},
    null => {'show_id': showId!, 'season_number': seasonNumber!},
  };

  @override
  bool operator ==(Object other) =>
      other is BadgeRef &&
      other.code == code &&
      other.showId == showId &&
      other.seasonNumber == seasonNumber;

  @override
  int get hashCode => Object.hash(code, showId, seasonNumber);
}

/// Vitrindeyse çıkarır, değilse sona ekler. 6 rozet doluyken yeni rozet eklenmez ve
/// [rejected] true döner (ekran "En fazla 6 rozet" iletisini gösterir).
({List<BadgeRef> featured, bool rejected}) toggleFeatured(
  List<BadgeRef> featured,
  BadgeRef badge,
) {
  if (featured.contains(badge)) {
    return (featured: [...featured]..remove(badge), rejected: false);
  }
  if (featured.length >= maxFeaturedBadges) {
    return (featured: featured, rejected: true);
  }
  return (featured: [...featured, badge], rejected: false);
}
