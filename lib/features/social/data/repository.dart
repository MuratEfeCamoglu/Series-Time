import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../discover/logic.dart';
import '../../profile/data/models.dart';

class SocialRepository {
  SocialRepository(this._client);

  final SupabaseClient _client;

  /// Kullanıcı adında önek eşleşmesi, en fazla 20 sonuç (F3c); oturum sahibinin
  /// engellediği kişiler listelenmez (F3f).
  Future<List<Profile>> searchUsers(String query) async {
    final pattern = usernamePrefixPattern(query);
    if (pattern == null) return const [];
    try {
      // blocks RLS'i yalnızca oturum sahibinin engellerini döndürür.
      final blocked = [
        for (final row in await _client.from('blocks').select('blocked_id'))
          row['blocked_id'] as String,
      ];
      var request = _client.from('profiles').select().like('username', pattern);
      if (blocked.isNotEmpty) {
        request = request.not('id', 'in', '(${blocked.join(',')})');
      }
      final rows = await request.order('username').limit(maxUserResults);
      return [for (final row in rows) Profile.fromJson(row)];
    } catch (error) {
      throw toAppFailure(error);
    }
  }
}
