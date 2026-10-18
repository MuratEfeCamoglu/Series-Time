import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';

/// F10: bölümün yıldızı. Adaylar TMDB kadrosundan ilk 20 kişi; oy verdikten sonra
/// en çok oy alan 5 kişi yüzdeleriyle. Kadro yoksa yalnızca ileti (F10d).
class StarSection extends ConsumerWidget {
  const StarSection({super.key, required this.episodeId});

  final int episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final credits = ref.watch(creditsProvider(episodeId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.starTitle, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        credits.when(
          data: (cast) => cast.isEmpty
              ? Text(l10n.starNoCast, style: AppTextStyles.bodySecondary)
              : _Voting(episodeId: episodeId, cast: cast),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(creditsProvider(episodeId)),
          ),
        ),
      ],
    );
  }
}

class _Voting extends ConsumerWidget {
  const _Voting({required this.episodeId, required this.cast});

  final int episodeId;
  final List<CastMember> cast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vote = ref.watch(starVoteProvider(episodeId));
    final state = vote.value;
    final myVote = state?.myVote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSpacing.castRowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final member = cast[index];
              return _CastCard(
                member: member,
                selected: member.personId == myVote,
                onTap: state == null
                    ? null
                    : () => _vote(context, ref, member.personId),
              );
            },
          ),
        ),
        if (myVote != null && state != null && state.top.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.starResultsTitle, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          for (final stat in state.top.take(topStarCount))
            _StarResult(stat: stat, mine: stat.personId == myVote),
        ],
      ],
    );
  }

  Future<void> _vote(BuildContext context, WidgetRef ref, int personId) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).saveFailed;
    try {
      await ref.read(starVoteProvider(episodeId).notifier).vote(personId);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _CastCard extends StatelessWidget {
  const _CastCard({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final CastMember member;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final character = member.character;
    return Semantics(
      label: AppLocalizations.of(context).starVoteFor(member.name),
      selected: selected,
      button: true,
      child: PressScale(
        child: SelectionBounce(
          active: selected,
          child: InkWell(
            key: Key('star.${member.personId}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
            child: SizedBox(
              width: AppSpacing.castCardWidth,
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                        width: AppSpacing.progressIndicatorStroke,
                      ),
                    ),
                    child: ProfileAvatar(
                      size: AppSpacing.castPhotoSize,
                      url: tmdbImageUrl(member.profilePath, TmdbImageSize.w185),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    member.name,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (character != null)
                    Text(
                      character,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarResult extends StatelessWidget {
  const _StarResult({required this.stat, required this.mine});

  final StarStat stat;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = votePercent(stat.votes, stat.totalVotes);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.name,
                  style: mine
                      ? AppTextStyles.body.copyWith(color: AppColors.accent)
                      : AppTextStyles.body,
                ),
              ),
              Text(l10n.percent(percent), style: AppTextStyles.bodySecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ProgressBar(value: percent / 100),
        ],
      ),
    );
  }
}
