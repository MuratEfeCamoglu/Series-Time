import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_locale.dart';
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

  /// F3(d): en ünlü diziler (TMDB'de en çok oy alanlar).
  /// F3(d): en ünlü diziler, 20'şerli sayfalar.
  Future<ShowSearchPage> popularShows({int page = 1}) => _guard(() async {
    final data = await _invoke({'action': 'popular', 'page': page});
    return ShowSearchPage.fromJson(data);
  });

  /// F4(a) Hakkında: dizinin oyuncuları.
  Future<List<ShowCastMember>> fetchShowCast(int showId) => _guard(() async {
    final data = await _invoke({'action': 'show_credits', 'showId': showId});
    return [
      for (final row in data['cast'] as List)
        ShowCastMember.fromJson(row as Map<String, dynamic>),
    ];
  });

  /// F2: dizinin TMDB arka plan ve afiş görsellerinin yolları.
  Future<ShowImages> fetchShowImages(int showId) => _guard(() async {
    final data = await _invoke({'action': 'show_images', 'showId': showId});
    return ShowImages.fromJson(data);
  });

  /// F3(g): TMDB'de yeni bölümü yayında olan diziler.
  Future<List<Show>> onTheAirShows() => _guard(() async {
    final data = await _invoke({'action': 'on_the_air'});
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

  /// Dizinin önbellekteki tüm bölümleri (dizi detayı Bölümler sekmesi). TMDB'ye gitmez;
  /// eksik sezonlar açıldıklarında `season` eylemiyle gelir.
  Future<List<Episode>> fetchCachedEpisodes(int showId) => _guard(() async {
    final rows = await _client
        .from('episodes')
        .select()
        .eq('show_id', showId)
        .order('season_number')
        .order('episode_number');
    return [for (final row in rows) Episode.fromJson(row)];
  });

  /// Oturum sahibinin listesi, en son eklenen önce.
  Future<List<UserShow>> fetchMyShows() =>
      _guard(() => fetchUserShows(_userId));

  /// Herhangi bir kullanıcının listesi (V10: listeler herkese açık).
  Future<List<UserShow>> fetchUserShows(String userId) => _guard(() async {
    final rows = await _client
        .from('user_shows')
        .select('*, shows(*)')
        .eq('user_id', userId)
        .order('added_at', ascending: false);
    return [for (final row in rows) UserShow.fromJson(row)];
  });

  Future<void> addToMyShows(int showId) => _guard(() async {
    await _client.from('user_shows').insert({
      'user_id': _userId,
      'show_id': showId,
    });
  });

  /// F4(f): null "Varsayılan" (TMDB afişi).
  Future<void> setPosterPath(int showId, String? path) => _guard(() async {
    await _client
        .from('user_shows')
        .update({'poster_path': path})
        .eq('user_id', _userId)
        .eq('show_id', showId);
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
    // F21(b): önbelleğe yazılmayan eylemler bu dilde döner.
    final response = await _client.functions.invoke(
      _tmdbProxy,
      body: {...body, 'language': AppLocale.code},
    );
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
