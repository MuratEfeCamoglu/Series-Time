import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../data/models.dart';
import '../providers.dart';

/// `/notifications` (F13): son 90 gün, en yeniden eskiye. Açılınca hepsi okundu olur.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ref
          .watch(notificationsProvider)
          .when(
            data: (items) => items.isEmpty
                ? EmptyState(
                    message: l10n.notificationsEmpty,
                    icon: Icons.notifications_none,
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _NotificationTile(notification: items[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
          ),
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
      NotificationType.badgeEarned => l10n.notificationBadgeEarned(
        n.badgeName ?? n.entityId ?? '',
      ),
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
          ? const Icon(Icons.emoji_events, color: AppColors.accent)
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
