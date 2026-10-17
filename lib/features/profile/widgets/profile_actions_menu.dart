import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../moderation/logic.dart';
import '../../moderation/providers.dart';
import '../../moderation/widgets/report_sheet.dart';
import '../../social/providers.dart';
import '../data/models.dart';

enum _ProfileAction { report, block }

/// Başka kullanıcının profilinde "Şikayet et" ve "Engelle" (F15a, F15b).
class ProfileActionsMenu extends ConsumerWidget {
  const ProfileActionsMenu({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_ProfileAction>(
      key: const Key('profile.menu'),
      tooltip: l10n.profileMenu,
      onSelected: (action) => switch (action) {
        _ProfileAction.report => _report(context),
        _ProfileAction.block => _block(context, ref),
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: _ProfileAction.report, child: Text(l10n.report)),
        PopupMenuItem(value: _ProfileAction.block, child: Text(l10n.block)),
      ],
    );
  }

  Future<void> _report(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).reportSent;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          ReportSheet(target: ReportTarget.profile, targetId: profile.id),
    );
    if (sent == true) messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockConfirmTitle(profile.displayName)),
        content: Text(l10n.blockConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('confirm.ok'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.block),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(blockedUsersProvider.notifier).block(profile.id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
      return;
    }
    // Engel iki yönlü takibi sildi (F15b); takip durumu ve sayılar yenilenir.
    ref
      ..invalidate(followProvider(profile.id))
      ..invalidate(profileCountsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.blockDone(profile.displayName))),
    );
    if (context.mounted && context.canPop()) context.pop();
  }
}
