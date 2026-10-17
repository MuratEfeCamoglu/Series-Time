import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'models.dart';

/// F14: rozet tanımları ve kullanıcının kazandıkları (verme işi veritabanı tetikleyicisinde).
class BadgesRepository {
  BadgesRepository(this._client);

  final SupabaseClient _client;

  Future<List<BadgeInfo>> fetchBadges() => _guard(() async {
    final rows = await _client.from('badges').select();
    return [for (final row in rows) BadgeInfo.fromJson(row)];
  });

  Future<List<EarnedBadge>> fetchEarned(String userId) => _guard(() async {
    final rows = await _client
        .from('user_badges')
        .select()
        .eq('user_id', userId);
    return [for (final row in rows) EarnedBadge.fromJson(row)];
  });

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
