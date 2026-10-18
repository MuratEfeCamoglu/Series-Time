import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'logic.dart';

final badgesRepositoryProvider = Provider<BadgesRepository>(
  (ref) => BadgesRepository(ref.watch(supabaseClientProvider)),
);

typedef BadgeRack = ({
  List<ShelfEntry> general,
  List<({int genreId, List<ShelfEntry> tiers})> genres,
  List<ShowBadge> shows,
});

/// F14: kullanıcının rozet rafı: dizi/sezon rozetleri, genel rozetler ve tür rozetleri.
final badgeShelfProvider = FutureProvider.autoDispose.family<BadgeRack, String>(
  (ref, userId) async {
    final repository = ref.watch(badgesRepositoryProvider);
    final (all, earned, shows) = await (
      repository.fetchBadges(),
      repository.fetchEarned(userId),
      repository.fetchShowBadges(userId),
    ).wait;
    return (
      general: badgeShelf(all, earned),
      genres: genreShelf(all, earned),
      shows: shows,
    );
  },
);

/// Profildeki rozet vitrini (F14). Oturum sahibi rozet ekranında dokunarak ekler/çıkarır;
/// değişiklik iyimserdir, hata olursa önceki vitrin geri gelir.
class FeaturedBadgesNotifier extends AsyncNotifier<List<FeaturedBadge>> {
  FeaturedBadgesNotifier(this.userId);

  final String userId;

  @override
  Future<List<FeaturedBadge>> build() =>
      ref.read(badgesRepositoryProvider).fetchFeatured(userId);

  /// false: vitrin dolu (6), rozet eklenmedi. [showName] ve [posterPath] dizi rozetinin
  /// sunucu yanıtı gelene kadar gösterilmesi içindir.
  Future<bool> toggle(
    BadgeRef badge, {
    String? showName,
    String? posterPath,
  }) async {
    final previous = await future;
    final result = toggleFeatured([
      for (final f in previous) BadgeRef.fromFeatured(f),
    ], badge);
    if (result.rejected) return false;
    final known = {for (final f in previous) BadgeRef.fromFeatured(f): f};
    state = AsyncData([
      for (final (index, ref) in result.featured.indexed)
        FeaturedBadge(
          position: index + 1,
          badgeCode: ref.code,
          showId: ref.showId,
          seasonNumber: ref.seasonNumber,
          showName: known[ref]?.showName ?? showName,
          posterPath: known[ref]?.posterPath ?? posterPath,
        ),
    ]);
    try {
      await ref.read(badgesRepositoryProvider).setFeatured(result.featured);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    return true;
  }
}

final featuredBadgesProvider = AsyncNotifierProvider.autoDispose
    .family<FeaturedBadgesNotifier, List<FeaturedBadge>, String>(
      FeaturedBadgesNotifier.new,
    );

/// Tüm rozet tanımları (Bildirimler › Arkadaşlar'da rozet adı için, F13f).
final badgesProvider = FutureProvider.autoDispose<List<BadgeInfo>>(
  (ref) => ref.watch(badgesRepositoryProvider).fetchBadges(),
);
