/// F14 saf kuralları: rozet rafının sırası ve kazanılma durumu.
library;

import 'data/models.dart';

/// Rozetler koşulların zorluğuna göre sıralanır (ISKELET.md F14 sırası).
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

/// Tüm rozetler, her biri kazanıldıysa tarihiyle. Bilinmeyen kodlar sona gelir.
List<({BadgeInfo badge, DateTime? earnedAt})> badgeShelf(
  List<BadgeInfo> all,
  List<EarnedBadge> earned,
) {
  final earnedAt = {for (final e in earned) e.code: e.earnedAt};
  int rank(BadgeInfo badge) {
    final index = badgeOrder.indexOf(badge.code);
    return index == -1 ? badgeOrder.length : index;
  }

  final sorted = [...all]..sort((a, b) => rank(a).compareTo(rank(b)));
  return [
    for (final badge in sorted) (badge: badge, earnedAt: earnedAt[badge.code]),
  ];
}
