import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'logic.dart';

final badgesRepositoryProvider = Provider<BadgesRepository>(
  (ref) => BadgesRepository(ref.watch(supabaseClientProvider)),
);

/// F14: kullanıcının rozet rafı (tüm rozetler + kazanılma tarihleri).
final badgeShelfProvider = FutureProvider.autoDispose
    .family<List<({BadgeInfo badge, DateTime? earnedAt})>, String>((
      ref,
      userId,
    ) async {
      final repository = ref.watch(badgesRepositoryProvider);
      final (all, earned) = await (
        repository.fetchBadges(),
        repository.fetchEarned(userId),
      ).wait;
      return badgeShelf(all, earned);
    });

/// Tüm rozet tanımları (Bildirimler › Arkadaşlar'da rozet adı için, F13f).
final badgesProvider = FutureProvider.autoDispose<List<BadgeInfo>>(
  (ref) => ref.watch(badgesRepositoryProvider).fetchBadges(),
);
