import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_locale.dart';
import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import '../../shows/data/models.dart';
import '../logic.dart';
import 'models.dart';

const _tmdbProxy = 'tmdb-proxy';

/// F18: türler, türe göre keşif ve benzer diziler `tmdb-proxy` üzerinden; listedeki
/// diziler sunucuda ayıklanır (§3.5). En sık türler `get_top_genres()` RPC'sinden.
class SuggestRepository {
  SuggestRepository(this._client);

  final SupabaseClient _client;

  Future<List<Genre>> fetchGenres() => _guard(() async {
    final data = await _invoke({'action': 'genres'});
    return [
      for (final row in data['genres'] as List)
        Genre.fromJson(row as Map<String, dynamic>),
    ];
  });

  /// [ids]: seçili tür kimlikleri ve ek kategoriler ([SuggestCategory.id], negatif).
  Future<ShowSearchPage> discover(List<int> ids, {int page = 1}) =>
      _guard(() async {
        final selection = splitSelection(ids);
        final data = await _invoke({
          'action': 'discover',
          'genreIds': selection.genreIds,
          'categories': selection.categories,
          'page': page,
        });
        return ShowSearchPage.fromJson(data);
      });

  Future<List<Show>> recommendations(int showId) => _guard(() async {
    final data = await _invoke({'action': 'recommendations', 'showId': showId});
    return showsFromJson(data['results'] as List);
  });

  Future<List<int>> topGenres() => _guard(() async {
    final rows = await _client.rpc('get_top_genres') as List;
    return [for (final id in rows) id as int];
  });

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
