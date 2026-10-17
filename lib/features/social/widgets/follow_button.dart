import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers.dart';

/// F12(a, b): "Takip et / Takip ediliyor". Dokununca sayı beklemeden değişir.
class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final following = ref.watch(followProvider(userId)).value;
    Future<void> toggle() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(followProvider(userId).notifier).toggle();
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
      }
    }

    if (following == true) {
      return OutlinedButton(
        key: const Key('profile.follow'),
        onPressed: toggle,
        child: Text(l10n.following),
      );
    }
    return FilledButton(
      key: const Key('profile.follow'),
      // Durum yüklenmeden dokunulursa yanlış yönde istek gider.
      onPressed: following == null ? null : toggle,
      child: Text(l10n.follow),
    );
  }
}
