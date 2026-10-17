import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../profile/data/models.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';

/// Kullanıcı arama sonucu satırı; dokununca profili açar (F12a).
class UserResultTile extends ConsumerWidget {
  const UserResultTile({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarPath = profile.avatarPath;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: ProfileAvatar(
        size: AppSpacing.minTapTarget,
        url: avatarPath == null
            ? null
            : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
      ),
      title: Text(profile.displayName, style: AppTextStyles.body),
      subtitle: Text(
        '@${profile.username}',
        style: AppTextStyles.bodySecondary,
      ),
      onTap: () => context.push(AppRoutes.userProfile(profile.username)),
    );
  }
}
