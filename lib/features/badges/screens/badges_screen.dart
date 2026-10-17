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
import '../widgets/badge_texts.dart';

// Kazanılmamış rozet gri gösterilir (F14): görselin renkleri ışıklılığa indirgenir.
const _grayscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.5, 0, //
]);

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
                  leading: _BadgeImage(
                    // `icon` kolonu assets/badges/ altındaki dosya adıdır (V16).
                    asset: 'assets/badges/${badge.icon}.png',
                    earned: earned,
                    semanticLabel: earned
                        ? badgeTitle(l10n, badge.code, badge.name)
                        : l10n.badgeLocked,
                  ),
                  title: Text(
                    badgeTitle(l10n, badge.code, badge.name),
                    style: earned
                        ? AppTextStyles.body
                        : AppTextStyles.bodySecondary,
                  ),
                  subtitle: Text(
                    earned
                        ? l10n.badgeEarnedOn(formatLongDate(earnedAt.toLocal()))
                        : badgeCondition(l10n, badge.code, badge.description),
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

class _BadgeImage extends StatelessWidget {
  const _BadgeImage({
    required this.asset,
    required this.earned,
    required this.semanticLabel,
  });

  final String asset;
  final bool earned;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: AppSpacing.emptyStateIconSize,
      height: AppSpacing.emptyStateIconSize,
      semanticLabel: semanticLabel,
      // Tanımı yeni eklenmiş, görseli henüz olmayan rozet için genel simge.
      errorBuilder: (_, _, _) =>
          const Icon(Icons.emoji_events, size: AppSpacing.emptyStateIconSize),
    );
    return earned
        ? image
        : ColorFiltered(colorFilter: _grayscale, child: image);
  }
}
