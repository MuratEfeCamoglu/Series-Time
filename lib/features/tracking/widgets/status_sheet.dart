import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import 'status_style.dart';

/// Menüde seçilebilen elle gruplar; diğerleri otomatik hesaplanır (F6j).
const _manualChoices = [
  ShowStatus.paused,
  ShowStatus.dropped,
  ShowStatus.watchlist,
];

/// F6(j) durum menüsü: "Otomatik" ve elle gruplar. Seçim iyimser kaydedilir.
Future<void> showStatusSheet(
  BuildContext context,
  WidgetRef ref, {
  required int showId,
  required ManualShowStatus? manual,
  required ShowStatus auto,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final current = manual == null
      ? null
      : effectiveShowStatus(manual: manual, auto: auto);
  final picked = await showModalBottomSheet<({ShowStatus? status})>(
    context: context,
    builder: (sheetContext) {
      Widget option(ShowStatus? status, ShowStatus dot, String title) =>
          ListTile(
            key: Key('status.option.${status?.name ?? 'auto'}'),
            leading: StatusDot(status: dot),
            title: Text(title),
            trailing: status == current
                ? Icon(Icons.check, color: AppColors.accent)
                : null,
            onTap: () => Navigator.pop(sheetContext, (status: status)),
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.statusMenuTitle, style: AppTextStyles.title),
            ),
            option(null, auto, l10n.statusAuto(statusLabel(l10n, auto))),
            for (final status in _manualChoices)
              option(status, status, statusLabel(l10n, status)),
          ],
        ),
      );
    },
  );
  if (picked == null || picked.status == current) return;
  try {
    await ref
        .read(myShowProgressProvider.notifier)
        .setStatus(showId, picked.status);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
  }
}

/// Dizi detayında grup düğmesi (F4b); dizi listede değilse görünmez.
class ShowStatusButton extends ConsumerWidget {
  const ShowStatusButton({super.key, required this.showId});

  final int showId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(myShowProgressProvider).value ?? const [];
    final entry = entries.where((e) => e.showId == showId).firstOrNull;
    if (entry == null) return const SizedBox.shrink();
    final auto = autoShowStatus(
      tmdbStatus: entry.showStatus,
      airedCount: entry.airedCount,
      watchedCount: entry.watchedCount,
    );
    final status = effectiveShowStatus(manual: entry.manualStatus, auto: auto);
    return OutlinedButton.icon(
      key: const Key('showDetail.status'),
      onPressed: () => showStatusSheet(
        context,
        ref,
        showId: showId,
        manual: entry.manualStatus,
        auto: auto,
      ),
      icon: StatusDot(status: status),
      label: Text(statusLabel(AppLocalizations.of(context), status)),
    );
  }
}
