import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../discover/logic.dart';
import '../../profile/data/models.dart';

class SocialRepository {
  SocialRepository(this._client);

  final SupabaseClient _client;

  /// Kullanıcı adında önek eşleşmesi, en fazla 20 sonuç (F3c).
  // F3(f) engellenenleri hariç tutma, `blocks` tablosu gelince (Aşama 5, F15) bu sorguya eklenir.
  Future<List<Profile>> searchUsers(String query) async {
    final pattern = usernamePrefixPattern(query);
    if (pattern == null) return const [];
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .like('username', pattern)
          .order('username')
          .limit(maxUserResults);
      return [for (final row in rows) Profile.fromJson(row)];
    } catch (error) {
      throw toAppFailure(error);
    }
  }
}
