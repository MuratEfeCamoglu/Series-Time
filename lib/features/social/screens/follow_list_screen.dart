import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../logic.dart';
import '../providers.dart';

/// F12(c): takipçi / takip edilen listesi, 30'arlı sayfalar, kaydırdıkça yüklenir.
class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.username,
    required this.list,
  });

  final String username;
  final FollowList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = list == FollowList.followers
        ? l10n.followersTitle
        : l10n.followingTitle;
    final profile = ref.watch(profileByUsernameProvider(username));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: profile.when(
        data: (profile) => _FollowList(
          listKey: (userId: profile.id, list: list),
          emptyMessage: list == FollowList.followers
              ? l10n.followersEmpty
              : l10n.followingEmpty,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileByUsernameProvider(username)),
        ),
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  const _FollowList({required this.listKey, required this.emptyMessage});

  final ({String userId, FollowList list}) listKey;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(followListProvider(listKey))
        .when(
          data: (state) {
            if (state.entries.isEmpty) {
              return EmptyState(
                message: emptyMessage,
                icon: Icons.people_outline,
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter <
                    AppSpacing.loadMoreThreshold) {
                  ref
                      .read(followListProvider(listKey).notifier)
                      .loadMore()
                      .ignore();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: state.entries.length + (state.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.entries.length) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final entry = state.entries[index];
                  final avatarPath = entry.avatarPath;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    leading: ProfileAvatar(
                      size: AppSpacing.minTapTarget,
                      url: avatarPath == null
                          ? null
                          : ref
                                .read(profileRepositoryProvider)
                                .avatarUrl(avatarPath),
                    ),
                    title: Text(entry.displayName, style: AppTextStyles.body),
                    subtitle: Text(
                      '@${entry.username}',
                      style: AppTextStyles.bodySecondary,
                    ),
                    onTap: () =>
                        context.push(AppRoutes.userProfile(entry.username)),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(followListProvider(listKey)),
          ),
        );
  }
}
