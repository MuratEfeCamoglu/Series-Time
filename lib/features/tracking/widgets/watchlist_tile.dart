import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/tmdb_image.dart';
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
      return _ListCard(item: item, progress: progress, check: check);
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
    // F5(f): yalnızca işaretler; Bölüm Sonrası ekranına geçmez.
    try {
      await ref.read(watchlistProvider.notifier).markNext(item);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// Liste kartı (F6b): solda yatay görsel, dizi adı etiketi, "S05 | B01 +38", sezon başı
/// etiketi, bölüm adı, ilerleme; sağda onay düğmesi.
class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.item,
    required this.progress,
    required this.check,
  });

  final WatchlistItem item;
  final Widget progress;
  final Widget check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final episodeName = item.nextEpisodeName;
    final remaining = remainingAfterNext(item);
    // Sahne görseli yoksa dizinin arka planı; ikisi de w300 boyutunda bulunur.
    final image = tmdbImageUrl(
      item.nextStillPath ?? item.backdropPath,
      TmdbImageSize.w300,
    );
    void openShow() => context.push(AppRoutes.showDetail(item.showId));

    return Card(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: AppSpacing.watchlistImageWidth,
              child: InkWell(
                onTap: openShow,
                child: image == null
                    ? const ColoredBox(
                        color: AppColors.surfaceAlt,
                        child: Icon(
                          Icons.movie_outlined,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            const ColoredBox(color: AppColors.surfaceAlt),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShowPill(name: item.name, onTap: openShow),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          episodeLabel(
                            item.nextSeasonNumber,
                            item.nextEpisodeNumber,
                          ),
                          style: AppTextStyles.title,
                        ),
                        if (remaining > 0)
                          Text(
                            l10n.remainingEpisodes(remaining),
                            style: AppTextStyles.caption,
                          ),
                        if (isSeasonPremiere(item.nextEpisodeNumber))
                          _Badge(text: l10n.seasonPremiere),
                      ],
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
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(child: check),
            ),
          ],
        ),
      ),
    );
  }
}

/// Çerçeveli dizi adı etiketi ve ">" — dokununca dizi detayı.
class _ShowPill extends StatelessWidget {
  const _ShowPill({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs / 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: AppSpacing.md,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
