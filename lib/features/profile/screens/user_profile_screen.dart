import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../auth/providers.dart';
import '../providers.dart';
import '../widgets/profile_view.dart';

/// `/user/:username` (F12a): başka kullanıcının profili, F8 ile aynı düzen. Tüm profiller
/// herkese açıktır (V10). Kendi kullanıcı adına gelinirse kendi profili gösterilir.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text('@$username')),
        body: const GuestGate(),
      );
    }
    final myId = ref.read(authRepositoryProvider).currentUserId;
    return ref
        .watch(profileByUsernameProvider(username))
        .when(
          data: (profile) => Scaffold(
            body: ProfileView(profile: profile, isMe: profile.id == myId),
          ),
          loading: () => Scaffold(
            appBar: AppBar(title: Text('@$username')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: Text(l10n.tabProfile)),
            body: ErrorView(
              error: error,
              onRetry: () =>
                  ref.invalidate(profileByUsernameProvider(username)),
            ),
          ),
        );
  }
}
