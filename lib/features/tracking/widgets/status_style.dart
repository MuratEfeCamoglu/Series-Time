import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../logic.dart';

/// F6(j) grup rengi (ISKELET.md §3.7).
Color statusColor(ShowStatus status) => switch (status) {
  ShowStatus.finished => AppColors.statusFinished,
  ShowStatus.upToDate => AppColors.statusUpToDate,
  ShowStatus.watching => AppColors.statusWatching,
  ShowStatus.paused => AppColors.statusPaused,
  ShowStatus.dropped => AppColors.statusDropped,
  ShowStatus.watchlist => AppColors.statusWatchlist,
};

String statusLabel(AppLocalizations l10n, ShowStatus status) =>
    switch (status) {
      ShowStatus.finished => l10n.statusFinished,
      ShowStatus.upToDate => l10n.statusUpToDate,
      ShowStatus.watching => l10n.statusWatching,
      ShowStatus.paused => l10n.statusPaused,
      ShowStatus.dropped => l10n.statusDropped,
      ShowStatus.watchlist => l10n.statusWatchlist,
    };

/// Grup renginde ilerleme çubuğu; İzleme Listesi'nde boş ve beyaz konturlu (F6b, F6j).
class StatusProgressBar extends StatelessWidget {
  const StatusProgressBar({
    super.key,
    required this.status,
    required this.watchedCount,
    required this.airedCount,
  });

  final ShowStatus status;
  final int watchedCount;
  final int airedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ProgressBar(
      value: statusProgress(status, watchedCount, airedCount),
      color: statusColor(status),
      outlined: status == ShowStatus.watchlist,
      semanticsLabel: l10n.statusProgressLabel(
        statusLabel(l10n, status),
        watchedCount,
        airedCount,
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status});

  final ShowStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.statusDotSize,
      height: AppSpacing.statusDotSize,
      decoration: BoxDecoration(
        color: statusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }
}
