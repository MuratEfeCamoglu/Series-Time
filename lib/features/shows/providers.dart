import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../auth/logic.dart';
import '../auth/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';

final showsRepositoryProvider = Provider<ShowsRepository>(
  (ref) => ShowsRepository(ref.watch(supabaseClientProvider)),
);

final showDetailProvider = FutureProvider.autoDispose.family<ShowDetail, int>(
  (ref, showId) => ref.watch(showsRepositoryProvider).fetchShow(showId),
);

final seasonEpisodesProvider = FutureProvider.autoDispose
    .family<List<Episode>, ({int showId, int seasonNumber})>(
      (ref, key) => ref
          .watch(showsRepositoryProvider)
          .fetchSeasonEpisodes(key.showId, key.seasonNumber),
    );

/// Oturum sahibinin dizi listesi. Ekleme/çıkarma iyimser güncellenir: Diziler sekmesi
/// sunucu yanıtını beklemeden değişir (F4b), hata olursa önceki liste geri gelir.
class MyShowsNotifier extends AsyncNotifier<List<UserShow>> {
  @override
  Future<List<UserShow>> build() async {
    if (ref.watch(authStatusProvider) == AuthStatus.signedOut) return const [];
    return ref.read(showsRepositoryProvider).fetchMyShows();
  }

  Future<void> add(Show show) => _mutate(
    (current) => [
      UserShow(show: show, addedAt: DateTime.now().toUtc()),
      for (final entry in current)
        if (entry.show.id != show.id) entry,
    ],
    (repository) => repository.addToMyShows(show.id),
  );

  Future<void> remove(int showId) => _mutate(
    (current) => [
      for (final entry in current)
        if (entry.show.id != showId) entry,
    ],
    (repository) => repository.removeFromMyShows(showId),
  );

  Future<void> _mutate(
    List<UserShow> Function(List<UserShow> current) optimistic,
    Future<void> Function(ShowsRepository repository) request,
  ) async {
    final previous = await future;
    state = AsyncData(optimistic(previous));
    try {
      await request(ref.read(showsRepositoryProvider));
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final myShowsProvider = AsyncNotifierProvider<MyShowsNotifier, List<UserShow>>(
  MyShowsNotifier.new,
);

/// Dizi detayındaki "Ekle / Listeden çıkar" düğmesi için.
final isInMyShowsProvider = Provider.autoDispose.family<bool, int>(
  (ref, showId) =>
      ref
          .watch(myShowsProvider)
          .value
          ?.any((entry) => entry.show.id == showId) ??
      false,
);
