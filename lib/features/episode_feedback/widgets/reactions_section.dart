import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';

const _emoji = {
  ReactionType.funny: '😂',
  ReactionType.love: '😍',
  ReactionType.shocked: '😮',
  ReactionType.sad: '😢',
  ReactionType.angry: '😡',
  ReactionType.bored: '😴',
};

String reactionLabel(AppLocalizations l10n, ReactionType type) =>
    switch (type) {
      ReactionType.funny => l10n.reactionFunny,
      ReactionType.love => l10n.reactionLove,
      ReactionType.shocked => l10n.reactionShocked,
      ReactionType.sad => l10n.reactionSad,
      ReactionType.angry => l10n.reactionAngry,
      ReactionType.bored => l10n.reactionBored,
    };

/// F9: 6 tepki; tepki verildikten sonra her birinin yüzdesi.
class ReactionsSection extends ConsumerWidget {
  const ReactionsSection({super.key, required this.episodeId});

  final int episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(reactionsProvider(episodeId))
        .when(
          data: (state) {
            final percentages = state.mine == null
                ? null
                : reactionPercentages(state.counts);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reactionsTitle, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: AppSpacing.posterGridColumns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: AppSpacing.reactionTileAspectRatio,
                  children: [
                    for (final type in ReactionType.values)
                      _ReactionTile(
                        type: type,
                        selected: state.mine == type,
                        percent: percentages?[type],
                        onTap: () => _tap(context, ref, type),
                      ),
                  ],
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(reactionsProvider(episodeId)),
          ),
        );
  }

  Future<void> _tap(
    BuildContext context,
    WidgetRef ref,
    ReactionType type,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).saveFailed;
    try {
      await ref.read(reactionsProvider(episodeId).notifier).tap(type);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ReactionTile extends StatelessWidget {
  const _ReactionTile({
    required this.type,
    required this.selected,
    required this.percent,
    required this.onTap,
  });

  final ReactionType type;
  final bool selected;

  /// null: kullanıcı henüz tepki vermedi (F9c yüzdeler sonra görünür).
  final int? percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = percent;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.accent : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
        child: InkWell(
          key: Key('reaction.${type.name}'),
          borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _emoji[type]!,
                style: const TextStyle(fontSize: AppSpacing.reactionEmojiSize),
              ),
              Text(
                reactionLabel(l10n, type),
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.onAccent : AppColors.textPrimary,
                ),
              ),
              if (value != null)
                Text(
                  l10n.percent(value),
                  key: Key('reaction.${type.name}.percent'),
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? AppColors.onAccent
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
