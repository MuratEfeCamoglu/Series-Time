import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import '../logic.dart';
import 'models.dart';

/// F15: şikayet ve engelleme. Şikayetler istemciden okunamaz (§3.3 RLS özeti).
class ModerationRepository {
  ModerationRepository(this._client);

  final SupabaseClient _client;

  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? note,
  }) => _guard(() async {
    try {
      await _client.from('reports').insert({
        'reporter_id': _userId,
        'target_type': target.name,
        'target_id': targetId,
        'reason': reason.name,
        'note': note,
      });
    } on PostgrestException catch (error) {
      // Aynı içerik daha önce şikayet edilmiş: kullanıcı açısından işlem tamam.
      if (error.code != '23505') rethrow;
    }
  });

  Future<void> block(String userId) => _guard(() async {
    try {
      await _client.from('blocks').insert({
        'blocker_id': _userId,
        'blocked_id': userId,
      });
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
    }
  });

  Future<void> unblock(String userId) => _guard(() async {
    await _client
        .from('blocks')
        .delete()
        .eq('blocker_id', _userId)
        .eq('blocked_id', userId);
  });

  /// F15(c): engellenenler, en son engellenen önce.
  Future<List<BlockedUser>> fetchBlockedUsers() => _guard(() async {
    final blocks = await _client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', _userId)
        .order('created_at', ascending: false);
    final ids = [for (final row in blocks) row['blocked_id'] as String];
    if (ids.isEmpty) return const [];
    // blocks.blocked_id auth.users'a bağlı; profiles ile ayrı sorguda eşlenir.
    final profiles = await _client
        .from('profiles')
        .select('id, username, display_name, avatar_path')
        .inFilter('id', ids);
    final byId = {
      for (final row in profiles)
        row['id'] as String: BlockedUser.fromJson(row),
    };
    return [for (final id in ids) ?byId[id]];
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
