import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../providers.dart';

/// F15(c): Ayarlar › Engellenenler ve engeli kaldırma.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsersTitle)),
      body: ref
          .watch(blockedUsersProvider)
          .when(
            data: (users) => users.isEmpty
                ? EmptyState(message: l10n.blockedUsersEmpty, icon: Icons.block)
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final avatarPath = user.avatarPath;
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
                        title: Text(
                          user.displayName,
                          style: AppTextStyles.body,
                        ),
                        subtitle: Text(
                          '@${user.username}',
                          style: AppTextStyles.bodySecondary,
                        ),
                        trailing: OutlinedButton(
                          key: Key('unblock.${user.userId}'),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref
                                  .read(blockedUsersProvider.notifier)
                                  .unblock(user.userId);
                            } catch (_) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(l10n.saveFailed)),
                              );
                            }
                          },
                          child: Text(l10n.unblock),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(blockedUsersProvider),
            ),
          ),
    );
  }
}
