import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../episode_feedback/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(ref.watch(supabaseClientProvider)),
);

/// F15(c): Ayarlar › Engellenenler. Engeli kaldırma iyimser.
class BlockedUsersNotifier extends AsyncNotifier<List<BlockedUser>> {
  @override
  Future<List<BlockedUser>> build() =>
      ref.read(moderationRepositoryProvider).fetchBlockedUsers();

  Future<void> block(String userId) async {
    await ref.read(moderationRepositoryProvider).block(userId);
    ref
      ..invalidateSelf()
      // Diğer açık bölümlerin yorumları sunucudan engel uygulanmış haliyle gelir.
      ..invalidate(commentsProvider);
  }

  Future<void> unblock(String userId) async {
    final previous = await future;
    state = AsyncData([
      for (final user in previous)
        if (user.userId != userId) user,
    ]);
    try {
      await ref.read(moderationRepositoryProvider).unblock(userId);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    ref.invalidate(commentsProvider);
  }
}

final blockedUsersProvider =
    AsyncNotifierProvider<BlockedUsersNotifier, List<BlockedUser>>(
      BlockedUsersNotifier.new,
    );
