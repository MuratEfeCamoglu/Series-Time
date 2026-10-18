import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import '../logic.dart';
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

  /// Bitirilen dizi ve sezonlar, en yeni önce.
  Future<List<ShowBadge>> fetchShowBadges(String userId) => _guard(() async {
    final rows = await _client.rpc(
      'get_show_badges',
      params: {'user_id': userId},
    ) as List;
    return [
      for (final row in rows) ShowBadge.fromJson(row as Map<String, dynamic>),
    ];
  });

  Future<List<FeaturedBadge>> fetchFeatured(String userId) => _guard(() async {
    final rows = await _client.rpc(
      'get_featured_badges',
      params: {'user_id': userId},
    ) as List;
    return [
      for (final row in rows)
        FeaturedBadge.fromJson(row as Map<String, dynamic>),
    ];
  });

  /// Vitrini sırasıyla bütünüyle değiştirir (en fazla 6; veritabanı da denetler).
  Future<void> setFeatured(List<BadgeRef> badges) => _guard(() async {
    await _client.rpc(
      'set_featured_badges',
      params: {
        'items': [for (final badge in badges) badge.toJson()],
      },
    );
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
