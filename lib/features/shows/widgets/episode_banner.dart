import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../tracking/providers.dart';
import '../data/models.dart';
import '../logic.dart';
import '../screens/season_screen.dart';

/// Geniş bölüm bandı: sahne görseli, üstünde "S01 | B03 · ad" ve tarih (F4a görsel düzen).
/// [trailing] sağ alttaki işaret düğmesi; [label] verilirse bölüm yerine o yazılır
/// ("Hepsini izledin!").
class EpisodeBanner extends StatelessWidget {
  const EpisodeBanner({
    super.key,
    required this.episode,
    this.label,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final Episode? episode;
  final String? label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = episode;
    final image = tmdbImageUrl(e?.stillPath, TmdbImageSize.w780);
    final name = e?.name;
    final airDate = e?.airDate;
    final title =
        label ??
        [
          if (e != null) episodeLabel(e.seasonNumber, e.episodeNumber),
          if (name != null && name.isNotEmpty) name,
        ].join(' · ');

    return SizedBox(
      height: AppSpacing.nextEpisodeBannerHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
        child: Material(
          color: AppColors.surfaceAlt,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                // Yazı görselin üstünde okunabilsin.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.scrimClear, AppColors.scrimTop],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: label == null
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: label == null
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.center,
                          crossAxisAlignment: label == null
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.title.copyWith(
                                color: label == null
                                    ? AppColors.textPrimary
                                    : AppColors.accent,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (label == null)
                              Text(
                                airDate == null
                                    ? l10n.episodeNoAirDate
                                    : formatLongDate(airDate),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sezon listesindeki bölüm bandı (F4a, F5): sağdaki yuvarlak kutu işaretler (F4e),
/// banda dokunmak Bölüm Sonrası ekranını açar, uzun basmak "Buraya kadar izledim" sunar.
class EpisodeBannerTile extends ConsumerWidget {
  const EpisodeBannerTile({
    super.key,
    required this.episode,
    required this.seasonEpisodes,
    required this.watched,
  });

  final Episode episode;
  final List<Episode> seasonEpisodes;

  /// null: izleme kayıtları henüz yüklenmedi.
  final bool? watched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final released = isReleased(episode, DateTime.now());
    final isGuest = ref.watch(isGuestProvider);
    final notifier = ref.read(watchedEpisodesProvider(episode.showId).notifier);
    final isWatched = watched;
    void gate() => showGuestGate(context);

    final ValueChanged<bool?>? onChanged;
    if (!released || (!isGuest && isWatched == null)) {
      // F5(d): yayınlanmamış bölüm işaretlenemez.
      onChanged = null;
    } else if (isGuest) {
      onChanged = (_) => gate();
    } else {
      onChanged = (_) {
        runMarking(context, notifier.toggle(episode));
        // F5(f): tek bölüm işaretlenince (geri alınınca değil) Bölüm Sonrası açılır.
        if (isWatched == false) context.push(AppRoutes.episode(episode.id));
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: EpisodeBanner(
        key: Key('episode.banner.${episode.id}'),
        episode: episode,
        onTap: isGuest
            ? gate
            : () => context.push(AppRoutes.episode(episode.id)),
        onLongPress: isGuest || !released || isWatched == null
            ? null
            : () => showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => SafeArea(
                  child: ListTile(
                    key: const Key('episode.markUntil'),
                    leading: const Icon(Icons.playlist_add_check),
                    title: Text(l10n.episodeMarkUntil),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      runMarking(
                        context,
                        notifier.markUntil(episode, seasonEpisodes),
                      );
                    },
                  ),
                ),
              ),
        trailing: Transform.scale(
          scale: AppSpacing.bannerCheckScale,
          child: Checkbox(
            key: Key('episode.check.${episode.id}'),
            semanticLabel: l10n.episodeMarkWatched,
            shape: const CircleBorder(),
            side: const BorderSide(
              color: AppColors.textPrimary,
              width: AppSpacing.checkButtonBorder,
            ),
            value: !isGuest && (isWatched ?? false),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
