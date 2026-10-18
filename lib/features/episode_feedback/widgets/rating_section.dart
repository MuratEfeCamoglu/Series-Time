import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../logic.dart';
import '../providers.dart';

/// F20(a): 5 yıldız, buçuklu. Yıldızın sol yarısına dokunmak buçuk puan verir.
class RatingSection extends ConsumerWidget {
  const RatingSection({super.key, required this.episodeId});

  final int episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(ratingProvider(episodeId))
        .when(
          data: (summary) {
            final mine = summary.myRating;
            final average = summary.average;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.ratingTitle, style: AppTextStyles.title),
                    ),
                    if (mine != null)
                      Text(
                        formatRating(mine),
                        key: const Key('rating.mine'),
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (var i = 0; i < maxRatingStars; i++)
                      _Star(
                        index: i,
                        fill: starFill(mine, i),
                        onRate: (value) => _rate(context, ref, value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  average == null
                      ? l10n.ratingNone
                      : l10n.ratingAverage(
                          formatRating(average),
                          summary.ratingCount,
                        ),
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(ratingProvider(episodeId)),
          ),
        );
  }

  Future<void> _rate(BuildContext context, WidgetRef ref, double value) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).saveFailed;
    try {
      await ref.read(ratingProvider(episodeId).notifier).rate(value);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.index, required this.fill, required this.onRate});

  final int index;
  final StarFill fill;
  final ValueChanged<double> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.ratingStar(index + 1),
      child: GestureDetector(
        key: Key('rating.star.$index'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => onRate(
          ratingFromTap(
            starIndex: index,
            leftHalf: details.localPosition.dx < AppSpacing.ratingStarSize / 2,
          ),
        ),
        child: SelectionBounce(
          active: fill != StarFill.empty,
          child: Icon(
            switch (fill) {
              StarFill.full => Icons.star,
              StarFill.half => Icons.star_half,
              StarFill.empty => Icons.star_border,
            },
            size: AppSpacing.ratingStarSize,
            color: fill == StarFill.empty
                ? AppColors.textSecondary
                : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

/// F20(b): bölümü beğen; sayı sunucuyu beklemeden değişir.
class EpisodeLikeButton extends ConsumerWidget {
  const EpisodeLikeButton({super.key, required this.episodeId});

  final int episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(ratingProvider(episodeId)).value;
    final liked = summary?.liked ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('episode.like'),
          tooltip: liked ? l10n.episodeUnlike : l10n.episodeLike,
          onPressed: summary == null
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(ratingProvider(episodeId).notifier)
                        .toggleLike();
                  } catch (_) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.saveFailed)),
                    );
                  }
                },
          icon: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            color: liked ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        Text(
          '${summary?.likeCount ?? 0}',
          key: const Key('episode.likeCount'),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
