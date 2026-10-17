import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'logic.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(ref.watch(supabaseClientProvider)),
);

/// F8(f): takipçi, takip edilen ve rozet sayıları. Takip düğmesi takipçi sayısını
/// iyimser değiştirir (F12b).
class ProfileCountsNotifier extends AsyncNotifier<ProfileCounts> {
  ProfileCountsNotifier(this.userId);

  final String userId;

  @override
  Future<ProfileCounts> build() =>
      ref.read(socialRepositoryProvider).fetchCounts(userId);

  void applyFollow({required bool follow}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(withFollowerChange(current, follow: follow));
  }
}

final profileCountsProvider = AsyncNotifierProvider.autoDispose
    .family<ProfileCountsNotifier, ProfileCounts, String>(
      ProfileCountsNotifier.new,
    );

/// F12: "Takip et / Takip ediliyor". İyimser; hata olursa düğme ve sayı geri döner.
class FollowNotifier extends AsyncNotifier<bool> {
  FollowNotifier(this.userId);

  final String userId;

  @override
  Future<bool> build() =>
      ref.read(socialRepositoryProvider).isFollowing(userId);

  Future<void> toggle() async {
    final previous = await future;
    final follow = !previous;
    final counts = ref.read(profileCountsProvider(userId).notifier);
    state = AsyncData(follow);
    counts.applyFollow(follow: follow);
    try {
      await ref
          .read(socialRepositoryProvider)
          .setFollowing(userId, follow: follow);
    } catch (_) {
      state = AsyncData(previous);
      counts.applyFollow(follow: previous);
      rethrow;
    }
    // Oturum sahibinin "takip edilen" sayısı da değişti.
    ref.invalidate(
      profileCountsProvider(ref.read(socialRepositoryProvider).currentUserId),
    );
  }
}

final followProvider = AsyncNotifierProvider.autoDispose
    .family<FollowNotifier, bool, String>(FollowNotifier.new);

class FollowListState {
  const FollowListState({
    required this.entries,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<FollowListEntry> entries;
  final bool hasMore;
  final bool loadingMore;
}

/// F12(c): 30'arlı sayfalar.
class FollowListNotifier extends AsyncNotifier<FollowListState> {
  FollowListNotifier(this.key);

  final ({String userId, FollowList list}) key;

  @override
  Future<FollowListState> build() async {
    final first = await ref
        .read(socialRepositoryProvider)
        .fetchFollowList(key.userId, key.list);
    return FollowListState(
      entries: first,
      hasMore: hasMoreFollows(first.length),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      FollowListState(
        entries: current.entries,
        hasMore: true,
        loadingMore: true,
      ),
    );
    try {
      final next = await ref
          .read(socialRepositoryProvider)
          .fetchFollowList(
            key.userId,
            key.list,
            offset: current.entries.length,
          );
      state = AsyncData(
        FollowListState(
          entries: [...current.entries, ...next],
          hasMore: hasMoreFollows(next.length),
        ),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final followListProvider = AsyncNotifierProvider.autoDispose
    .family<
      FollowListNotifier,
      FollowListState,
      ({String userId, FollowList list})
    >(FollowListNotifier.new);
