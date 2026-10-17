import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'models.dart';

/// İzleme kayıtları. Ağır hesaplar (sıradaki bölüm, ilerleme, yaklaşan) RPC'lerdedir.
class TrackingRepository {
  TrackingRepository(this._client);

  final SupabaseClient _client;

  Future<List<WatchlistItem>> fetchWatchlist() => _guard(() async {
    final rows = await _client.rpc('get_watchlist') as List;
    return [
      for (final row in rows)
        WatchlistItem.fromJson(row as Map<String, dynamic>),
    ];
  });

  Future<List<UpcomingEpisode>> fetchUpcoming(int days) => _guard(() async {
    final rows =
        await _client.rpc('get_upcoming', params: {'days': days}) as List;
    return [
      for (final row in rows)
        UpcomingEpisode.fromJson(row as Map<String, dynamic>),
    ];
  });

  /// Oturum sahibinin bu dizide izlediği bölüm kimlikleri.
  Future<Set<int>> fetchWatchedEpisodeIds(int showId) => _guard(() async {
    final rows = await _client
        .from('watched_episodes')
        .select('episode_id')
        .eq('user_id', _userId)
        .eq('show_id', showId);
    return {for (final row in rows) row['episode_id'] as int};
  });

  Future<void> markEpisode({required int episodeId, required int showId}) =>
      _guard(() async {
        // show_id'yi veritabanı tetikleyicisi bölümden yeniden yazar; burada NOT NULL için.
        await _client.from('watched_episodes').insert({
          'user_id': _userId,
          'episode_id': episodeId,
          'show_id': showId,
        });
      });

  Future<void> unmarkEpisode(int episodeId) => _guard(() async {
    await _client
        .from('watched_episodes')
        .delete()
        .eq('user_id', _userId)
        .eq('episode_id', episodeId);
  });

  Future<void> markSeason(int showId, int seasonNumber) => _guard(() async {
    await _client.rpc<int>(
      'mark_season',
      params: {'show_id': showId, 'season_number': seasonNumber},
    );
  });

  Future<void> markEpisodesUntil(int episodeId) => _guard(() async {
    await _client.rpc<int>(
      'mark_episodes_until',
      params: {'episode_id': episodeId},
    );
  });

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppFailure(AppFailureType.unknown);
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw toAppFailure(error);
    }
  }
}
