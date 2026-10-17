import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/logic.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';

/// İzleme Listesi öğesi (F6b, F6d): afiş, sıradaki bölüm kodu, ilerleme çubuğu ve onay düğmesi.
class WatchlistTile extends ConsumerWidget {
  const WatchlistTile({super.key, required this.item, required this.layout});

  final WatchlistItem item;
  final WatchlistLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = episodeCode(item.nextSeasonNumber, item.nextEpisodeNumber);
    final progress = ProgressBar(
      value: watchProgress(item.watchedCount, item.airedCount),
    );
    final check = _CheckButton(item: item, code: code);
    final poster = PosterCard(
      title: item.name,
      posterPath: item.posterPath,
      onTap: () => context.push(AppRoutes.showDetail(item.showId)),
    );

    if (layout == WatchlistLayout.list) {
      final episodeName = item.nextEpisodeName;
      return Card(
        color: AppColors.surface,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(width: AppSpacing.watchlistPosterWidth, child: poster),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // toUpperCase Türkçe değil (i → I); vurgu renk ve kalınlıkla.
                      item.name,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      episodeLabel(
                        item.nextSeasonNumber,
                        item.nextEpisodeNumber,
                      ),
                      style: AppTextStyles.title,
                    ),
                    if (episodeName != null && episodeName.isNotEmpty)
                      Text(
                        episodeName,
                        style: AppTextStyles.bodySecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    progress,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              check,
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              poster,
              Positioned(right: 0, bottom: 0, child: check),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        progress,
        const SizedBox(height: AppSpacing.xs),
        Text(code, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

class _CheckButton extends ConsumerWidget {
  const _CheckButton({required this.item, required this.code});

  final WatchlistItem item;
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final done = item.pending;
    return Semantics(
      button: true,
      label: l10n.markNextEpisode(code),
      child: SizedBox.square(
        dimension: AppSpacing.checkButtonSize,
        child: Material(
          shape: CircleBorder(
            side: BorderSide(
              color: done ? AppColors.accent : AppColors.textPrimary,
              width: AppSpacing.checkButtonBorder,
            ),
          ),
          color: done ? AppColors.accent : AppColors.background,
          child: InkWell(
            key: Key('watchlist.check.${item.showId}'),
            customBorder: const CircleBorder(),
            // İşaret sunucuya giderken ikinci dokunuş aynı bölümü yeniden göndermesin.
            onTap: done ? null : () => _markNext(context, ref),
            child: Icon(
              Icons.check,
              color: done ? AppColors.onAccent : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markNext(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).saveFailed;
    final mark = ref.read(watchlistProvider.notifier).markNext(item);
    // F5(f): tek bölüm işaretlenince Bölüm Sonrası ekranı açılır.
    context.push(AppRoutes.episode(item.nextEpisodeId));
    try {
      await mark;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
