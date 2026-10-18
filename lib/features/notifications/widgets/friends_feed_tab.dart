import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/app_locale.dart';
import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../badges/providers.dart';
import '../../badges/widgets/badge_texts.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../shows/logic.dart';
import '../../social/data/models.dart';
import '../../social/providers.dart';

/// Bildirimler › Arkadaşlar (F13f): takip edilenlerin izlemeleri, puanları ve rozetleri.
class FriendsFeedTab extends ConsumerWidget {
  const FriendsFeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(friendsFeedProvider)
        .when(
          data: (items) => items.isEmpty
              ? EmptyState(
                  message: l10n.friendsFeedEmpty,
                  icon: Icons.group_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(friendsFeedProvider.future),
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => EntranceAnimation(
                      index: index,
                      child: _FeedTile(item: items[index]),
                    ),
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(friendsFeedProvider),
          ),
        );
  }
}

class _FeedTile extends ConsumerWidget {
  const _FeedTile({required this.item});

  final FriendFeedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final show = item.showName ?? '';
    final season = item.seasonNumber;
    final episode = item.episodeNumber;
    final code = season == null || episode == null
        ? ''
        : episodeLabel(season, episode);
    final badges = ref.watch(badgesProvider).value ?? const [];
    final text = switch (item.kind) {
      FriendFeedKind.watched when item.episodeCount > 1 => l10n.feedWatchedMany(
        item.username,
        item.episodeCount,
        show,
      ),
      FriendFeedKind.watched => l10n.feedWatchedOne(item.username, show, code),
      FriendFeedKind.rated => l10n.feedRated(
        item.username,
        show,
        code,
        AppLocale.decimal(item.rating ?? 0),
      ),
      FriendFeedKind.badge => l10n.feedBadge(
        item.username,
        badgeTitle(
          l10n,
          item.badgeCode ?? '',
          badges.where((b) => b.code == item.badgeCode).firstOrNull?.name ??
              item.badgeCode ??
              '',
        ),
      ),
    };
    final episodeId = item.episodeId;
    final avatar = item.avatarPath;
    return ListTile(
      key: Key('feed.${item.kind.name}.${item.userId}.${item.happenedAt}'),
      leading: InkWell(
        onTap: () => context.push(AppRoutes.userProfile(item.username)),
        child: ProfileAvatar(
          size: AppSpacing.minTapTarget,
          url: avatar == null
              ? null
              : ref.read(profileRepositoryProvider).avatarUrl(avatar),
        ),
      ),
      title: Text(text, style: AppTextStyles.body),
      subtitle: Text(
        formatLongDate(item.happenedAt.toLocal()),
        style: AppTextStyles.caption,
      ),
      trailing: item.kind == FriendFeedKind.badge
          ? Icon(Icons.emoji_events, color: AppColors.accent)
          : SizedBox(
              width: AppSpacing.posterThumbWidth,
              child: PosterCard(title: show, posterPath: item.posterPath),
            ),
      onTap: switch (item.kind) {
        FriendFeedKind.badge => () => context.push(
          AppRoutes.badges(item.username),
        ),
        _ when episodeId != null => () => context.push(
          AppRoutes.episode(episodeId),
        ),
        _ => null,
      },
    );
  }
}
