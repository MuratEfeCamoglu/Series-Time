import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import '../../discover/logic.dart';
import '../../profile/data/models.dart';
import '../logic.dart';
import 'models.dart';

/// Kullanıcı arama (F3) ve takip (F12).
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

  Future<ProfileCounts> fetchCounts(String userId) => _guard(() async {
    final rows = await _client.rpc(
      'get_profile_counts',
      params: {'user_id': userId},
    ) as List;
    return ProfileCounts.fromJson(rows.single as Map<String, dynamic>);
  });

  Future<bool> isFollowing(String userId) => _guard(() async {
    final row = await _client
        .from('follows')
        .select('followee_id')
        .eq('follower_id', _userId)
        .eq('followee_id', userId)
        .maybeSingle();
    return row != null;
  });

  Future<void> setFollowing(String userId, {required bool follow}) =>
      _guard(() async {
        if (follow) {
          await _client.from('follows').insert({
            'follower_id': _userId,
            'followee_id': userId,
          });
        } else {
          await _client
              .from('follows')
              .delete()
              .eq('follower_id', _userId)
              .eq('followee_id', userId);
        }
      });

  /// F12(c): [offset]'ten başlayarak en fazla 30 kişi, en yeni takip önce.
  Future<List<FollowListEntry>> fetchFollowList(
    String userId,
    FollowList list, {
    int offset = 0,
  }) => _guard(() async {
    final rows = await _client.rpc(
      'get_follow_list',
      params: {'user_id': userId, 'list': list.name, 'page_offset': offset},
    ) as List;
    return [
      for (final row in rows)
        FollowListEntry.fromJson(row as Map<String, dynamic>),
    ];
  });

  String get currentUserId => _userId;

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
