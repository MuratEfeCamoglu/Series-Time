import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../auth/logic.dart';
import '../auth/providers.dart';
import '../profile/providers.dart';
import '../tracking/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'logic.dart';

final showsRepositoryProvider = Provider<ShowsRepository>(
  (ref) => ShowsRepository(ref.watch(supabaseClientProvider)),
);

/// Diziler sekmesinin üstündeki "Şu an yayında" satırı (F6i).
final onTheAirProvider = FutureProvider.autoDispose<List<Show>>(
  (ref) => ref.watch(showsRepositoryProvider).onTheAirShows(),
);

final showCastProvider = FutureProvider.autoDispose
    .family<List<ShowCastMember>, int>(
      (ref, showId) => ref.watch(showsRepositoryProvider).fetchShowCast(showId),
    );

final showDetailProvider = FutureProvider.autoDispose.family<ShowDetail, int>(
  (ref, showId) => ref.watch(showsRepositoryProvider).fetchShow(showId),
);

final showEpisodesProvider = FutureProvider.autoDispose
    .family<List<Episode>, int>(
      (ref, showId) =>
          ref.watch(showsRepositoryProvider).fetchCachedEpisodes(showId),
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
    if (!isRegistered(ref.watch(authStatusProvider))) return const [];
    return ref.read(showsRepositoryProvider).fetchMyShows();
  }

  /// [seasonNumbers]: dizinin normal sezonları; bilinmiyorsa (öneri ızgarasındaki "+")
  /// dizi detayından alınır. Sıradaki bölüm ve ilerleme `episodes` tablosundan
  /// hesaplandığı için eklenen dizinin bölümleri önbelleğe çekilir.
  Future<void> add(Show show, {List<int>? seasonNumbers}) async {
    await _mutate(
      (current) => [
        UserShow(show: show, addedAt: DateTime.now().toUtc()),
        for (final entry in current)
          if (entry.show.id != show.id) entry,
      ],
      (repository) => repository.addToMyShows(show.id),
    );
    final repository = ref.read(showsRepositoryProvider);
    try {
      final numbers =
          seasonNumbers ??
          [
            for (final season in (await repository.fetchShow(show.id)).seasons)
              if (season.seasonNumber != specialsSeasonNumber)
                season.seasonNumber,
          ];
      await Future.wait([
        for (final n in numbers) repository.fetchSeasonEpisodes(show.id, n),
      ]);
    } catch (error) {
      // Dizi listeye eklendi; eksik sezonlar açıldıklarında veya tmdb-sync ile gelir.
      debugPrint('Sezon bölümleri önbelleğe alınamadı (${show.id}): $error');
    }
    ref
      ..invalidate(watchlistProvider)
      ..invalidate(showEpisodesProvider(show.id));
  }

  Future<void> remove(int showId) async {
    await _mutate(
      (current) => [
        for (final entry in current)
          if (entry.show.id != showId) entry,
      ],
      (repository) => repository.removeFromMyShows(showId),
    );
    // İzleme kayıtları veritabanında silindi (F4c).
    ref
      ..invalidate(watchlistProvider)
      ..invalidate(watchedEpisodesProvider(showId))
      ..invalidate(userStatsProvider);
  }

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
