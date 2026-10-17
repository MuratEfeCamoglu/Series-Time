import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'models.dart';

const _tmdbProxy = 'tmdb-proxy';

/// TMDB verisi yalnızca `tmdb-proxy` üzerinden gelir (ISKELET.md §3.5); kullanıcının
/// listesi doğrudan `user_shows` tablosundan okunup yazılır.
class ShowsRepository {
  ShowsRepository(this._client);

  final SupabaseClient _client;

  Future<ShowSearchPage> searchShows(String query, {int page = 1}) =>
      _guard(() async {
        final data = await _invoke({
          'action': 'search',
          'query': query.trim(),
          'page': page,
        });
        return ShowSearchPage.fromJson(data);
      });

  Future<List<Show>> trendingShows() => _guard(() async {
    final data = await _invoke({'action': 'trending'});
    return showsFromJson(data['results'] as List);
  });

  Future<ShowDetail> fetchShow(int showId) => _guard(() async {
    final data = await _invoke({'action': 'show', 'showId': showId});
    return ShowDetail.fromJson(data);
  });

  Future<List<Episode>> fetchSeasonEpisodes(int showId, int seasonNumber) =>
      _guard(() async {
        final data = await _invoke({
          'action': 'season',
          'showId': showId,
          'seasonNumber': seasonNumber,
        });
        return [
          for (final row in data['episodes'] as List)
            Episode.fromJson(row as Map<String, dynamic>),
        ];
      });

  /// Oturum sahibinin listesi, en son eklenen önce.
  Future<List<UserShow>> fetchMyShows() => _guard(() async {
    final rows = await _client
        .from('user_shows')
        .select('*, shows(*)')
        .eq('user_id', _userId)
        .order('added_at', ascending: false);
    return [for (final row in rows) UserShow.fromJson(row)];
  });

  Future<void> addToMyShows(int showId) => _guard(() async {
    await _client.from('user_shows').insert({
      'user_id': _userId,
      'show_id': showId,
    });
  });

  Future<void> removeFromMyShows(int showId) => _guard(() async {
    await _client
        .from('user_shows')
        .delete()
        .eq('user_id', _userId)
        .eq('show_id', showId);
  });

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppFailure(AppFailureType.unknown);
    return id;
  }

  Future<Map<String, dynamic>> _invoke(Map<String, Object> body) async {
    final response = await _client.functions.invoke(_tmdbProxy, body: body);
    return response.data as Map<String, dynamic>;
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
