import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../auth/providers.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../shows/logic.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import '../../badges/logic.dart';
import '../../badges/widgets/badge_texts.dart';
import '../widgets/friends_feed_tab.dart';

/// Bildirimler sekmesi (F13f): **Ben** (bildirimler ve kendi izlemelerin, son 90 gün; açılınca
/// hepsi okundu) ve **Arkadaşlar**.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tabNotifications)),
        body: const GuestGate(),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabNotifications),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.notificationsMe),
              Tab(text: l10n.notificationsFriends),
            ],
          ),
        ),
        body: const TabBarView(children: [_MeTab(), FriendsFeedTab()]),
      ),
    );
  }
}

class _MeTab extends ConsumerWidget {
  const _MeTab();

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(notificationsProvider)
      ..invalidate(myWatchFeedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifications = ref.watch(notificationsProvider);
    final watches = ref.watch(myWatchFeedProvider);
    final error = notifications.error ?? watches.error;
    if (error != null) {
      return ErrorView(error: error, onRetry: () => _retry(ref));
    }
    if (!notifications.hasValue || !watches.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = mergeMeFeed(notifications.requireValue, watches.requireValue);
    if (items.isEmpty) {
      return EmptyState(
        message: l10n.notificationsEmpty,
        icon: Icons.notifications_none,
      );
    }
    return RefreshIndicator(
      onRefresh: () => Future.wait([
        ref.refresh(notificationsProvider.future),
        ref.refresh(myWatchFeedProvider.future),
      ]),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => EntranceAnimation(
          index: index,
          child: switch (items[index]) {
            NotificationEntry(:final notification) => _NotificationTile(
              notification: notification,
            ),
            WatchEntry(:final watch) => _WatchTile(watch: watch),
          },
        ),
      ),
    );
  }
}

/// Kendi izlemen: sahne görseli, "S01 | B05" ve dizi adı; dokununca Bölüm Sonrası ekranı.
class _WatchTile extends StatelessWidget {
  const _WatchTile({required this.watch});

  final MyWatchItem watch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = watch;
    final still = w.stillPath ?? w.backdropPath;
    final url = still == null
        ? tmdbImageUrl(w.posterPath, TmdbImageSize.w342)
        : tmdbImageUrl(still, TmdbImageSize.w300);
    final text = w.episodeCount > 1
        ? l10n.meWatchedMany(w.episodeCount, w.showName)
        : l10n.meWatchedOne(
            w.showName,
            episodeLabel(w.seasonNumber, w.episodeNumber),
          );
    return ListTile(
      key: Key('me.watch.${w.episodeId}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
        child: SizedBox(
          width: AppSpacing.feedStillWidth,
          height: AppSpacing.feedStillWidth / AppSpacing.stillAspectRatio,
          child: url == null
              ? ColoredBox(color: AppColors.surfaceAlt)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      ColoredBox(color: AppColors.surfaceAlt),
                ),
        ),
      ),
      title: Text(text, style: AppTextStyles.body),
      subtitle: Text(
        formatLongDate(w.happenedAt.toLocal()),
        style: AppTextStyles.caption,
      ),
      onTap: () => context.push(AppRoutes.episode(w.episodeId)),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = notification;
    final actor = n.actorUsername == null
        ? l10n.notificationDeletedUser
        : '@${n.actorUsername}';
    // R7: bildirim metni yorumun içeriğini hiçbir zaman göstermez.
    final text = switch (n.type) {
      NotificationType.newFollower => l10n.notificationNewFollower(actor),
      NotificationType.commentLiked => l10n.notificationCommentLiked(actor),
      NotificationType.badgeEarned => switch (parseShowBadgeEntity(
        n.entityId,
      )) {
        (seasonNumber: 0, showId: _) => l10n.notificationShowBadge(
          n.showName ?? '',
        ),
        (:final seasonNumber, showId: _) => l10n.notificationSeasonBadge(
          n.showName ?? '',
          seasonNumber,
        ),
        null => l10n.notificationBadgeEarned(
          badgeTitle(l10n, n.entityId ?? '', n.badgeName ?? n.entityId ?? ''),
        ),
      },
    };
    final username = n.actorUsername;
    final episodeId = n.episodeId;
    final VoidCallback? onTap = switch (n.type) {
      NotificationType.newFollower when username != null => () => context.push(
        AppRoutes.userProfile(username),
      ),
      NotificationType.commentLiked when episodeId != null =>
        () => context.push(AppRoutes.episode(episodeId)),
      NotificationType.badgeEarned => () => context.push(AppRoutes.badges()),
      _ => null,
    };
    final avatarPath = n.actorAvatarPath;

    return ListTile(
      tileColor: n.isUnread ? AppColors.surface : null,
      leading: n.type == NotificationType.badgeEarned
          ? Icon(Icons.emoji_events, color: AppColors.accent)
          : ProfileAvatar(
              size: AppSpacing.minTapTarget,
              url: avatarPath == null
                  ? null
                  : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
            ),
      title: Text(text, style: AppTextStyles.body),
      subtitle: Text(
        formatLongDate(n.createdAt.toLocal()),
        style: AppTextStyles.caption,
      ),
      onTap: onTap,
    );
  }
}
