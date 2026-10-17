import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../auth/providers.dart';

/// Ayarlar. Hesap silme (F16) ve Hakkında (F17) Aşama 7'de eklenir.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      // Çıkış sonrası yönlendirici giriş ekranına geçer.
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureMessage(AppLocalizations.of(context), error)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.editProfileTitle),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          ListTile(
            key: const Key('settings.blocked'),
            leading: const Icon(Icons.block),
            title: Text(l10n.blockedUsersTitle),
            onTap: () => context.push(AppRoutes.blockedUsers),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: Text(l10n.signOut),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
