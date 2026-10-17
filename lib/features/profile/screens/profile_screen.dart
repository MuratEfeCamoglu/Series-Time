import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers.dart';
import '../widgets/profile_view.dart';

/// Profil sekmesi: oturum sahibinin profili (F8).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(myProfileProvider)
        .when(
          data: (profile) =>
              Scaffold(body: ProfileView(profile: profile, isMe: true)),
          loading: () => Scaffold(
            appBar: AppBar(title: Text(l10n.tabProfile)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: Text(l10n.tabProfile)),
            body: ErrorView(
              error: error,
              onRetry: () => ref.invalidate(myProfileProvider),
            ),
          ),
        );
  }
}
