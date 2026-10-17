import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/profile_avatar.dart';

/// Profil sekmesi. Kapak, istatistikler ve dizi satırı Aşama 4'te (F8) gelir.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabProfile),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: profile.when(
        data: (profile) => _ProfileHeader(profile: profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final avatarPath = profile.avatarPath;
    final country = profile.countryCode;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ProfileAvatar(
            url: avatarPath == null
                ? null
                : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (country != null)
          Text(
            countryFlag(country),
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
        Text(
          profile.displayName,
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        Text(
          '@${profile.username}',
          style: AppTextStyles.bodySecondary,
          textAlign: TextAlign.center,
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.bio,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Center(
          child: OutlinedButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            child: Text(l10n.profileEdit),
          ),
        ),
      ],
    );
  }
}
