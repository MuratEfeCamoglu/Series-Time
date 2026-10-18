import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/data/models.dart';
import '../shows/data/models.dart';
import '../shows/providers.dart';
import '../social/providers.dart';

class PopularShowsState {
  const PopularShowsState({
    required this.shows,
    required this.page,
    required this.totalPages,
    this.loadingMore = false,
  });

  final List<Show> shows;
  final int page;
  final int totalPages;
  final bool loadingMore;

  bool get hasMore => page < totalPages;
}

/// Keşfet'teki en ünlü diziler (F3d): 20'şerli sayfalar, aşağı kaydırınca sonraki sayfa.
class PopularShowsNotifier extends AsyncNotifier<PopularShowsState> {
  @override
  Future<PopularShowsState> build() async {
    final first = await ref.read(showsRepositoryProvider).popularShows();
    return PopularShowsState(
      shows: first.results,
      page: 1,
      totalPages: first.totalPages,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      PopularShowsState(
        shows: current.shows,
        page: current.page,
        totalPages: current.totalPages,
        loadingMore: true,
      ),
    );
    try {
      final next = await ref
          .read(showsRepositoryProvider)
          .popularShows(page: current.page + 1);
      final seen = {for (final s in current.shows) s.id};
      state = AsyncData(
        PopularShowsState(
          // Oy sayıları sayfalar arasında kayabilir; aynı dizi iki kez gösterilmez.
          shows: [
            ...current.shows,
            ...next.results.where((s) => !seen.contains(s.id)),
          ],
          page: current.page + 1,
          totalPages: next.totalPages,
        ),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final popularShowsProvider =
    AsyncNotifierProvider.autoDispose<PopularShowsNotifier, PopularShowsState>(
      PopularShowsNotifier.new,
    );

final showSearchProvider = FutureProvider.autoDispose
    .family<List<Show>, String>(
      (ref, query) async =>
          (await ref.watch(showsRepositoryProvider).searchShows(query)).results,
    );

final userSearchProvider = FutureProvider.autoDispose
    .family<List<Profile>, String>(
      (ref, query) => ref.watch(socialRepositoryProvider).searchUsers(query),
    );
