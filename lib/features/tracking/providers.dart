import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences.dart';
import '../../core/supabase_client.dart';
import '../auth/logic.dart';
import '../auth/providers.dart';
import '../notifications/providers.dart';
import '../profile/providers.dart';
import '../social/providers.dart';
import '../shows/data/models.dart';
import '../shows/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'logic.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => TrackingRepository(ref.watch(supabaseClientProvider)),
);

/// Sıradaki bölümü olan diziler (F6). Afişteki onay düğmesi sıradaki bölümü iyimser
/// işaretler; sunucu yanıtından sonra liste yeni sıradaki bölümle yeniden çekilir.
class WatchlistNotifier extends AsyncNotifier<List<WatchlistItem>> {
  @override
  Future<List<WatchlistItem>> build() async {
    if (!isRegistered(ref.watch(authStatusProvider))) return const [];
    return ref.read(trackingRepositoryProvider).fetchWatchlist();
  }

  Future<void> markNext(WatchlistItem item) async {
    final previous = await future;
    final now = DateTime.now().toUtc();
    state = AsyncData([
      for (final entry in previous)
        entry.showId == item.showId ? entry.markedPending(now) : entry,
    ]);
    final repository = ref.read(trackingRepositoryProvider);
    try {
      await repository.markEpisode(
        episodeId: item.nextEpisodeId,
        showId: item.showId,
      );
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    // Rozet (F14) ve rozet bildirimi (F13) işaretlemeyle gelebilir.
    ref
      ..invalidate(watchedEpisodesProvider(item.showId))
      ..invalidate(myShowProgressProvider)
      ..invalidate(showProgressProvider)
      ..invalidate(userStatsProvider)
      ..invalidate(profileCountsProvider)
      ..invalidate(unreadCountProvider);
    state = AsyncData(await repository.fetchWatchlist());
  }
}

final watchlistProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
      WatchlistNotifier.new,
    );

final upcomingProvider = FutureProvider.autoDispose<List<UpcomingEpisode>>(
  (ref) => ref.watch(trackingRepositoryProvider).fetchUpcoming(upcomingDays),
);

/// Bir dizide izlenen bölüm kimlikleri (sezon ekranı onay kutuları). Tüm işaretlemeler
/// iyimserdir (F5e): küme hemen değişir, hata olursa önceki küme geri gelir.
class WatchedEpisodesNotifier extends AsyncNotifier<Set<int>> {
  WatchedEpisodesNotifier(this.showId);

  final int showId;

  @override
  Future<Set<int>> build() async {
    if (!isRegistered(ref.watch(authStatusProvider))) return const {};
    return ref.read(trackingRepositoryProvider).fetchWatchedEpisodeIds(showId);
  }

  Future<void> toggle(Episode episode) async {
    final current = await future;
    final watched = current.contains(episode.id);
    await _mutate(
      watched ? ({...current}..remove(episode.id)) : {...current, episode.id},
      (repository) => watched
          ? repository.unmarkEpisode(episode.id)
          : repository.markEpisode(episodeId: episode.id, showId: showId),
    );
  }

  Future<void> markSeason(int seasonNumber, List<Episode> episodes) async {
    final current = await future;
    await _mutate({
      ...current,
      ...markableEpisodeIds(episodes, DateTime.now()),
    }, (repository) => repository.markSeason(showId, seasonNumber));
  }

  Future<void> markUntil(Episode target, List<Episode> seasonEpisodes) async {
    final current = await future;
    await _mutate(
      {...current, ...episodeIdsUntil(seasonEpisodes, target, DateTime.now())},
      (repository) => repository.markEpisodesUntil(target.id),
      // Önceki sezonlar da işaretlendiği için küme sunucudan yenilenir.
      refetch: true,
    );
  }

  Future<void> _mutate(
    Set<int> optimistic,
    Future<void> Function(TrackingRepository repository) request, {
    bool refetch = false,
  }) async {
    final previous = await future;
    state = AsyncData(optimistic);
    final repository = ref.read(trackingRepositoryProvider);
    try {
      await request(repository);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    if (refetch) {
      state = AsyncData(await repository.fetchWatchedEpisodeIds(showId));
    }
    // İşaretleme listede olmayan diziyi listeye ekler ve sıradaki bölümü değiştirir.
    ref
      ..invalidate(watchlistProvider)
      ..invalidate(myShowsProvider)
      ..invalidate(myShowProgressProvider)
      ..invalidate(showProgressProvider)
      ..invalidate(userStatsProvider)
      ..invalidate(profileCountsProvider)
      ..invalidate(unreadCountProvider);
  }
}

final watchedEpisodesProvider =
    AsyncNotifierProvider.family<WatchedEpisodesNotifier, Set<int>, int>(
      WatchedEpisodesNotifier.new,
    );

/// Herhangi bir kullanıcının dizileri ve grupları (profil "Dizilerim" ve "Tümü", F6j).
final showProgressProvider = FutureProvider.autoDispose
    .family<List<ShowProgress>, String>(
      (ref, userId) =>
          ref.watch(trackingRepositoryProvider).fetchShowProgress(userId),
    );

/// Oturum sahibinin dizileri ve grupları (Dizilerim sekmesi, dizi detayındaki durum menüsü).
/// Elle grup seçimi iyimser güncellenir; hata olursa önceki liste geri gelir.
class MyShowProgressNotifier extends AsyncNotifier<List<ShowProgress>> {
  @override
  Future<List<ShowProgress>> build() async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (!isRegistered(ref.watch(authStatusProvider)) || userId == null) {
      return const [];
    }
    return ref.read(trackingRepositoryProvider).fetchShowProgress(userId);
  }

  /// [choice] null ise "Otomatik".
  Future<void> setStatus(int showId, ShowStatus? choice) async {
    final previous = await future;
    final manual = manualFor(choice);
    state = AsyncData([
      for (final entry in previous)
        entry.showId == showId ? entry.withManualStatus(manual) : entry,
    ]);
    try {
      await ref
          .read(trackingRepositoryProvider)
          .setManualStatus(showId, manual);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    // Durduruldu/Dönülmez diziler Sıradaki'den çıkar, geri dönenler girer.
    ref
      ..invalidate(watchlistProvider)
      ..invalidate(showProgressProvider);
  }
}

final myShowProgressProvider =
    AsyncNotifierProvider<MyShowProgressNotifier, List<ShowProgress>>(
      MyShowProgressNotifier.new,
    );

const _layoutKey = 'watchlist.layout';

/// F6(c): ızgara/liste tercihi cihazda saklanır.
class WatchlistLayoutNotifier extends Notifier<WatchlistLayout> {
  @override
  WatchlistLayout build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_layoutKey);
    return WatchlistLayout.values.asNameMap()[stored] ?? WatchlistLayout.list;
  }

  Future<void> toggle() async {
    state = state == WatchlistLayout.grid
        ? WatchlistLayout.list
        : WatchlistLayout.grid;
    await ref.read(sharedPreferencesProvider).setString(_layoutKey, state.name);
  }
}

final watchlistLayoutProvider =
    NotifierProvider<WatchlistLayoutNotifier, WatchlistLayout>(
      WatchlistLayoutNotifier.new,
    );
