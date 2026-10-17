import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../notifications/providers.dart';
import '../social/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'logic.dart';

final episodeFeedbackRepositoryProvider = Provider<EpisodeFeedbackRepository>(
  (ref) => EpisodeFeedbackRepository(ref.watch(supabaseClientProvider)),
);

final episodeInfoProvider = FutureProvider.autoDispose.family<EpisodeInfo, int>(
  (ref, episodeId) =>
      ref.watch(episodeFeedbackRepositoryProvider).fetchEpisodeInfo(episodeId),
);

class ReactionState {
  const ReactionState({required this.mine, required this.counts});

  final ReactionType? mine;
  final Map<ReactionType, int> counts;
}

/// F9: tepki iyimser güncellenir; hata olursa önceki duruma döner.
class ReactionsNotifier extends AsyncNotifier<ReactionState> {
  ReactionsNotifier(this.episodeId);

  final int episodeId;

  @override
  Future<ReactionState> build() async {
    final repository = ref.read(episodeFeedbackRepositoryProvider);
    final (mine, counts) = await (
      repository.fetchMyReaction(episodeId),
      repository.fetchReactionCounts(episodeId),
    ).wait;
    return ReactionState(mine: mine, counts: counts);
  }

  Future<void> tap(ReactionType tapped) async {
    final previous = await future;
    final next = nextReaction(previous.mine, tapped);
    state = AsyncData(
      ReactionState(
        mine: next,
        counts: applyReactionChange(previous.counts, previous.mine, next),
      ),
    );
    try {
      await ref
          .read(episodeFeedbackRepositoryProvider)
          .setReaction(episodeId, next);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final reactionsProvider = AsyncNotifierProvider.autoDispose
    .family<ReactionsNotifier, ReactionState, int>(ReactionsNotifier.new);

final creditsProvider = FutureProvider.autoDispose
    .family<List<CastMember>, int>(
      (ref, episodeId) =>
          ref.watch(episodeFeedbackRepositoryProvider).fetchCredits(episodeId),
    );

class StarVoteState {
  const StarVoteState({required this.myVote, required this.top});

  final int? myVote;
  final List<StarStat> top;
}

/// F10: oy hemen işaretlenir; sonuçlar sunucudan yeniden çekilir.
class StarVoteNotifier extends AsyncNotifier<StarVoteState> {
  StarVoteNotifier(this.episodeId);

  final int episodeId;

  @override
  Future<StarVoteState> build() async {
    final repository = ref.read(episodeFeedbackRepositoryProvider);
    final (myVote, top) = await (
      repository.fetchMyStarVote(episodeId),
      repository.fetchStarStats(episodeId),
    ).wait;
    return StarVoteState(myVote: myVote, top: top);
  }

  Future<void> vote(int personId) async {
    final previous = await future;
    state = AsyncData(StarVoteState(myVote: personId, top: previous.top));
    final repository = ref.read(episodeFeedbackRepositoryProvider);
    try {
      await repository.voteStar(episodeId, personId);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    state = AsyncData(
      StarVoteState(
        myVote: personId,
        top: await repository.fetchStarStats(episodeId),
      ),
    );
  }
}

final starVoteProvider = AsyncNotifierProvider.autoDispose
    .family<StarVoteNotifier, StarVoteState, int>(StarVoteNotifier.new);

class CommentsState {
  const CommentsState({
    required this.comments,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<EpisodeComment> comments;
  final bool hasMore;
  final bool loadingMore;

  CommentsState copyWith({
    List<EpisodeComment>? comments,
    bool? hasMore,
    bool? loadingMore,
  }) => CommentsState(
    comments: comments ?? this.comments,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// F11: 20'şerli sayfalar; silme ve beğeni iyimser.
class CommentsNotifier extends AsyncNotifier<CommentsState> {
  CommentsNotifier(this.episodeId);

  final int episodeId;

  EpisodeFeedbackRepository get _repository =>
      ref.read(episodeFeedbackRepositoryProvider);

  @override
  Future<CommentsState> build() async {
    final first = await _repository.fetchComments(episodeId);
    return CommentsState(
      comments: first,
      hasMore: hasMoreComments(first.length),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _repository.fetchComments(
        episodeId,
        before: current.comments.last.createdAt,
      );
      state = AsyncData(
        CommentsState(
          comments: [...current.comments, ...next],
          hasMore: hasMoreComments(next.length),
        ),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Sunucu doğrulaması (hız sınırı, kelime filtresi) gerektiği için iyimser değildir;
  /// hata [AppFailure] olarak ekrana döner.
  Future<void> post({required String body, required bool isSpoiler}) async {
    await _repository.postComment(episodeId, body: body, isSpoiler: isSpoiler);
    // İlk yorum rozeti ve bildirimi (F14, F13) gelmiş olabilir.
    ref
      ..invalidate(profileCountsProvider)
      ..invalidate(unreadCountProvider);
    final first = await _repository.fetchComments(episodeId);
    state = AsyncData(
      CommentsState(comments: first, hasMore: hasMoreComments(first.length)),
    );
  }

  Future<void> delete(String commentId) => _mutate(
    (comments) => [
      for (final c in comments)
        if (c.id != commentId) c,
    ],
    () => _repository.deleteComment(commentId),
  );

  Future<void> toggleLike(EpisodeComment comment) => _mutate(
    (comments) => [
      for (final c in comments)
        c.id == comment.id ? c.withLike(liked: !comment.likedByMe) : c,
    ],
    () => _repository.setLike(comment.id, liked: !comment.likedByMe),
  );

  /// F15(a, b): şikayet edilen yorum ve engellenen kişinin yorumları hemen kalkar.
  void hideLocally(bool Function(EpisodeComment comment) hidden) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        comments: [
          for (final c in current.comments)
            if (!hidden(c)) c,
        ],
      ),
    );
  }

  Future<void> _mutate(
    List<EpisodeComment> Function(List<EpisodeComment> comments) optimistic,
    Future<void> Function() request,
  ) async {
    final previous = await future;
    state = AsyncData(
      previous.copyWith(comments: optimistic(previous.comments)),
    );
    try {
      await request();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsNotifier, CommentsState, int>(CommentsNotifier.new);

/// F20: puan ve beğeni. Puan iyimser değişir, ortalama sunucudan yenilenir; beğeni sayısı
/// iyimser değişir (F20c).
class RatingNotifier extends AsyncNotifier<RatingSummary> {
  RatingNotifier(this.episodeId);

  final int episodeId;

  EpisodeFeedbackRepository get _repository =>
      ref.read(episodeFeedbackRepositoryProvider);

  @override
  Future<RatingSummary> build() => _repository.fetchRatingSummary(episodeId);

  Future<void> rate(double tapped) async {
    final previous = await future;
    final next = nextRating(previous.myRating, tapped);
    state = AsyncData(previous.copyWith(myRating: () => next));
    try {
      await _repository.setRating(episodeId, next);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    state = AsyncData(await _repository.fetchRatingSummary(episodeId));
  }

  Future<void> toggleLike() async {
    final previous = await future;
    final liked = !previous.liked;
    state = AsyncData(
      previous.copyWith(
        liked: liked,
        likeCount: previous.likeCount + (liked ? 1 : -1),
      ),
    );
    try {
      await _repository.setEpisodeLike(episodeId, liked: liked);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final ratingProvider = AsyncNotifierProvider.autoDispose
    .family<RatingNotifier, RatingSummary, int>(RatingNotifier.new);
