import '../../shows/data/models.dart';

/// F9(a): 6 sabit tepki; adlar `reaction_emoji` enum değerleriyle aynıdır.
enum ReactionType { funny, love, shocked, sad, angry, bored }

ReactionType? reactionFromName(String? name) =>
    name == null ? null : ReactionType.values.asNameMap()[name];

/// `episodes` satırı ve dizinin adı (`select('*, shows(name)')`).
class EpisodeInfo {
  const EpisodeInfo({required this.episode, required this.showName});

  factory EpisodeInfo.fromJson(Map<String, dynamic> json) => EpisodeInfo(
    episode: Episode.fromJson(json),
    showName: (json['shows'] as Map<String, dynamic>)['name'] as String,
  );

  final Episode episode;
  final String showName;
}

/// `episode_credits` satırı (F10a).
class CastMember {
  const CastMember({
    required this.personId,
    required this.name,
    required this.order,
    this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
    personId: json['person_id'] as int,
    name: json['name'] as String,
    character: json['character'] as String?,
    profilePath: json['profile_path'] as String?,
    order: json['order'] as int,
  );

  final int personId;
  final String name;
  final String? character;
  final String? profilePath;
  final int order;
}

/// `get_episode_star_stats()` satırı (F10c).
class StarStat {
  const StarStat({
    required this.personId,
    required this.name,
    required this.votes,
    required this.totalVotes,
    this.character,
    this.profilePath,
  });

  factory StarStat.fromJson(Map<String, dynamic> json) => StarStat(
    personId: json['person_id'] as int,
    // Kadro yenilenince kişi kadrodan çıkmış olabilir (oy korunur, ad boş gelir).
    name: json['name'] as String? ?? '',
    character: json['character'] as String?,
    profilePath: json['profile_path'] as String?,
    votes: json['votes'] as int,
    totalVotes: json['total_votes'] as int,
  );

  final int personId;
  final String name;
  final String? character;
  final String? profilePath;
  final int votes;
  final int totalVotes;
}

/// `get_episode_comments()` satırı (F11).
class EpisodeComment {
  const EpisodeComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.body,
    required this.isSpoiler,
    required this.createdAt,
    required this.likeCount,
    required this.likedByMe,
    this.avatarPath,
  });

  factory EpisodeComment.fromJson(Map<String, dynamic> json) => EpisodeComment(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    avatarPath: json['avatar_path'] as String?,
    body: json['body'] as String,
    isSpoiler: json['is_spoiler'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
    likeCount: json['like_count'] as int,
    likedByMe: json['liked_by_me'] as bool,
  );

  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarPath;
  final String body;
  final bool isSpoiler;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  EpisodeComment withLike({required bool liked}) => EpisodeComment(
    id: id,
    userId: userId,
    username: username,
    displayName: displayName,
    avatarPath: avatarPath,
    body: body,
    isSpoiler: isSpoiler,
    createdAt: createdAt,
    likeCount: likeCount + (liked == likedByMe ? 0 : (liked ? 1 : -1)),
    likedByMe: liked,
  );
}
