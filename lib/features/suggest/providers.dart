import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences.dart';
import '../../core/supabase_client.dart';
import '../shows/data/models.dart';
import '../shows/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'logic.dart';

final suggestRepositoryProvider = Provider<SuggestRepository>(
  (ref) => SuggestRepository(ref.watch(supabaseClientProvider)),
);

final genresProvider = FutureProvider.autoDispose<List<Genre>>(
  (ref) => ref.watch(suggestRepositoryProvider).fetchGenres(),
);

const _selectionKey = 'suggest.genres';

/// Seçili kategoriler (F18b, F18c). Her değişiklik cihazda saklanır.
class SelectedGenresNotifier extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    final stored = ref
        .read(sharedPreferencesProvider)
        .getStringList(_selectionKey)
        ?.map(int.parse)
        .toList();
    // Saklanan seçim varsa en sık türler hiç sorulmaz.
    final top = stored == null
        ? await ref.read(suggestRepositoryProvider).topGenres()
        : const <int>[];
    return defaultGenreSelection(stored: stored, topGenres: top);
  }

  /// false: seçim eklenmedi (3 sınırı, F18b).
  Future<bool> toggle(int genreId) async {
    final result = toggleGenre(await future, genreId);
    if (result.rejected) return false;
    state = AsyncData(result.selection);
    await ref.read(sharedPreferencesProvider).setStringList(_selectionKey, [
      for (final id in result.selection) '$id',
    ]);
    return true;
  }
}

final selectedGenresProvider =
    AsyncNotifierProvider<SelectedGenresNotifier, Set<int>>(
      SelectedGenresNotifier.new,
    );

class SuggestionsState {
  const SuggestionsState({
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

/// Seçili türlere göre öneriler, 20'şerli sayfalar (F18d). Seçim değişince baştan yüklenir.
class SuggestionsNotifier extends AsyncNotifier<SuggestionsState> {
  @override
  Future<SuggestionsState> build() async {
    final genres = await ref.watch(selectedGenresProvider.future);
    if (genres.isEmpty) {
      return const SuggestionsState(shows: [], page: 0, totalPages: 0);
    }
    final first = await ref
        .read(suggestRepositoryProvider)
        .discover(genres.toList()..sort());
    return SuggestionsState(
      shows: first.results,
      page: 1,
      totalPages: first.totalPages,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      SuggestionsState(
        shows: current.shows,
        page: current.page,
        totalPages: current.totalPages,
        loadingMore: true,
      ),
    );
    final genres = await ref.read(selectedGenresProvider.future);
    try {
      final next = await ref
          .read(suggestRepositoryProvider)
          .discover(genres.toList()..sort(), page: current.page + 1);
      final seen = {for (final s in current.shows) s.id};
      state = AsyncData(
        SuggestionsState(
          // Popülerlik sayfalar arasında kayabilir; aynı dizi iki kez gösterilmez.
          shows: [...current.shows, ...withoutShows(next.results, seen)],
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

final suggestionsProvider =
    AsyncNotifierProvider.autoDispose<SuggestionsNotifier, SuggestionsState>(
      SuggestionsNotifier.new,
    );

/// F18(f): en son izlenen dizi ve ona benzer diziler; hiç izleme yoksa null.
final similarShowsProvider =
    FutureProvider.autoDispose<({Show source, List<Show> shows})?>((ref) async {
      // read: listeye dizi eklemek kaynağı değiştirmez; ızgaradan kaldırma ekranda yapılır.
      final myShows = await ref.read(myShowsProvider.future);
      final source = lastWatchedShow(myShows);
      if (source == null) return null;
      final shows = await ref
          .read(suggestRepositoryProvider)
          .recommendations(source.id);
      return (source: source, shows: shows);
    });
