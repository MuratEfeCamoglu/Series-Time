import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'models.dart';

const _tmdbProxy = 'tmdb-proxy';

/// Bölüm sonrası: tepki (F9), bölümün yıldızı (F10), yorum ve beğeni (F11).
class EpisodeFeedbackRepository {
  EpisodeFeedbackRepository(this._client);

  final SupabaseClient _client;

  Future<EpisodeInfo> fetchEpisodeInfo(int episodeId) => _guard(() async {
    final row = await _client
        .from('episodes')
        .select('*, shows(name)')
        .eq('id', episodeId)
        .single();
    return EpisodeInfo.fromJson(row);
  });

  Future<ReactionType?> fetchMyReaction(int episodeId) => _guard(() async {
    final row = await _client
        .from('reactions')
        .select('emoji')
        .eq('user_id', _userId)
        .eq('episode_id', episodeId)
        .maybeSingle();
    return reactionFromName(row?['emoji'] as String?);
  });

  Future<Map<ReactionType, int>> fetchReactionCounts(int episodeId) =>
      _guard(() async {
        final rows = await _client.rpc(
          'get_episode_reaction_stats',
          params: {'episode_id': episodeId},
        ) as List;
        return {
          for (final row in rows.cast<Map<String, dynamic>>())
            ?reactionFromName(row['emoji'] as String): row['count'] as int,
        };
      });

  /// [reaction] null ise tepki kaldırılır (F9b).
  Future<void> setReaction(int episodeId, ReactionType? reaction) =>
      _guard(() async {
        if (reaction == null) {
          await _client
              .from('reactions')
              .delete()
              .eq('user_id', _userId)
              .eq('episode_id', episodeId);
          return;
        }
        await _client.from('reactions').upsert({
          'user_id': _userId,
          'episode_id': episodeId,
          'emoji': reaction.name,
        });
      });

  /// F10(a): TMDB sırasıyla en fazla 20 kişi (`tmdb-proxy` `episode_credits`).
  Future<List<CastMember>> fetchCredits(int episodeId) => _guard(() async {
    final response = await _client.functions.invoke(
      _tmdbProxy,
      body: {'action': 'episode_credits', 'episodeId': episodeId},
    );
    final data = response.data as Map<String, dynamic>;
    return [
      for (final row in data['credits'] as List)
        CastMember.fromJson(row as Map<String, dynamic>),
    ];
  });

  Future<int?> fetchMyStarVote(int episodeId) => _guard(() async {
    final row = await _client
        .from('star_votes')
        .select('person_id')
        .eq('user_id', _userId)
        .eq('episode_id', episodeId)
        .maybeSingle();
    return row?['person_id'] as int?;
  });

  Future<List<StarStat>> fetchStarStats(int episodeId) => _guard(() async {
    final rows = await _client.rpc(
      'get_episode_star_stats',
      params: {'episode_id': episodeId},
    ) as List;
    return [
      for (final row in rows) StarStat.fromJson(row as Map<String, dynamic>),
    ];
  });

  Future<void> voteStar(int episodeId, int personId) => _guard(() async {
    await _client.from('star_votes').upsert({
      'user_id': _userId,
      'episode_id': episodeId,
      'person_id': personId,
    });
  });

  /// F11(d): [before] öncesindeki en fazla 20 yorum, en yeniden eskiye.
  Future<List<EpisodeComment>> fetchComments(
    int episodeId, {
    DateTime? before,
  }) => _guard(() async {
    final rows = await _client.rpc(
      'get_episode_comments',
      params: {
        'episode_id': episodeId,
        'before': before?.toUtc().toIso8601String(),
      },
    ) as List;
    return [
      for (final row in rows)
        EpisodeComment.fromJson(row as Map<String, dynamic>),
    ];
  });

  Future<void> postComment(
    int episodeId, {
    required String body,
    required bool isSpoiler,
  }) => _guard(() async {
    await _client.from('comments').insert({
      'user_id': _userId,
      'episode_id': episodeId,
      'body': body.trim(),
      'is_spoiler': isSpoiler,
    });
  });

  Future<void> deleteComment(String commentId) => _guard(() async {
    await _client.from('comments').delete().eq('id', commentId);
  });

  Future<void> setLike(String commentId, {required bool liked}) =>
      _guard(() async {
        if (liked) {
          await _client.from('comment_likes').insert({
            'user_id': _userId,
            'comment_id': commentId,
          });
        } else {
          await _client
              .from('comment_likes')
              .delete()
              .eq('user_id', _userId)
              .eq('comment_id', commentId);
        }
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
