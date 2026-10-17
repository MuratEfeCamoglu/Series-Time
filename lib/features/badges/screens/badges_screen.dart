import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../profile/providers.dart';
import '../providers.dart';

// Özgün rozet çizimleri (V16) Aşama 7'de assets/ altına gelir; o zamana kadar simge.
const _icons = {
  'first_episode': Icons.play_circle,
  'episodes_100': Icons.local_movies,
  'episodes_1000': Icons.military_tech,
  'shows_10': Icons.collections_bookmark,
  'first_comment': Icons.chat_bubble,
};

/// `/badges` (F14): kazanılanlar renkli, kazanılmayanlar gri ve koşuluyla.
/// [username] verilirse o kullanıcının rafı, yoksa oturum sahibininki.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = username;
    final userId = name == null
        ? AsyncValue.data(ref.read(authRepositoryProvider).currentUserId)
        : ref.watch(profileByUsernameProvider(name)).whenData((p) => p.id);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgesTitle)),
      body: switch (userId) {
        AsyncData(:final value?) => _Shelf(userId: value),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileByUsernameProvider(name!)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Shelf extends ConsumerWidget {
  const _Shelf({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(badgeShelfProvider(userId))
        .when(
          data: (shelf) => ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: shelf.length,
            itemBuilder: (context, index) {
              final (:badge, :earnedAt) = shelf[index];
              final earned = earnedAt != null;
              return Card(
                key: Key('badge.${badge.code}'),
                color: AppColors.surface,
                child: ListTile(
                  leading: Icon(
                    _icons[badge.code] ?? Icons.emoji_events,
                    size: AppSpacing.emptyStateIconSize,
                    color: earned ? AppColors.accent : AppColors.border,
                    semanticLabel: earned ? null : l10n.badgeLocked,
                  ),
                  title: Text(
                    badge.name,
                    style: earned
                        ? AppTextStyles.body
                        : AppTextStyles.bodySecondary,
                  ),
                  subtitle: Text(
                    earned
                        ? l10n.badgeEarnedOn(formatLongDate(earnedAt.toLocal()))
                        : badge.description,
                    style: AppTextStyles.caption,
                  ),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(badgeShelfProvider(userId)),
          ),
        );
  }
}
