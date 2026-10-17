import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../shows/data/models.dart';
import '../../shows/logic.dart';
import '../../shows/screens/season_screen.dart';
import '../../tracking/providers.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/comments_section.dart';
import '../widgets/reactions_section.dart';
import '../widgets/star_section.dart';

/// Bölüm Sonrası ekranı (`/episode/:id`): sahne görseli, İzlendi düğmesi, tepki (F9),
/// bölümün yıldızı (F10), yorumlar (F11).
class EpisodeScreen extends ConsumerStatefulWidget {
  const EpisodeScreen({super.key, required this.episodeId});

  final int episodeId;

  @override
  ConsumerState<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends ConsumerState<EpisodeScreen> {
  // F11(c): "Yine de göster" bu ekranda kalıcıdır; ekran kapanınca kapı yeniden kapanır.
  bool _gateRevealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // F19(c): Bölüm Sonrası (tepki, oy, yorum) hesap ister.
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.episodeTitle)),
        body: const GuestGate(),
      );
    }
    final info = ref.watch(episodeInfoProvider(widget.episodeId));
    return Scaffold(
      body: info.when(
        data: (info) => _EpisodeBody(
          info: info,
          gateRevealed: _gateRevealed,
          onShowAnyway: () => setState(() => _gateRevealed = true),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => SafeArea(
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: BackButton()),
              Expanded(
                child: ErrorView(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(episodeInfoProvider(widget.episodeId)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeBody extends ConsumerWidget {
  const _EpisodeBody({
    required this.info,
    required this.gateRevealed,
    required this.onShowAnyway,
  });

  final EpisodeInfo info;
  final bool gateRevealed;
  final VoidCallback onShowAnyway;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final episode = info.episode;
    final watched = ref
        .watch(watchedEpisodesProvider(episode.showId))
        .value
        ?.contains(episode.id);
    final still = tmdbImageUrl(episode.stillPath, TmdbImageSize.original);
    final name = episode.name;
    final airDate = episode.airDate;
    final runtime = episode.runtime;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: AppSpacing.episodeHeaderHeight,
          title: Text(info.showName),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (still == null)
                  const ColoredBox(color: AppColors.surface)
                else
                  CachedNetworkImage(
                    key: const Key('episode.still'),
                    imageUrl: still,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        const ColoredBox(color: AppColors.surface),
                  ),
                // Başlık ve geri düğmesi görselin üstünde okunabilsin.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.scrimTop,
                        AppColors.scrimClear,
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              Text(
                episodeLabel(episode.seasonNumber, episode.episodeNumber),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (name != null && name.isNotEmpty)
                Text(name, style: AppTextStyles.headline),
              Text(
                [
                  if (airDate != null) formatLongDate(airDate),
                  if (runtime != null) l10n.episodeRuntime(runtime),
                ].join(' · '),
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              _WatchedButton(episode: episode, watched: watched),
              const SizedBox(height: AppSpacing.lg),
              ReactionsSection(episodeId: episode.id),
              const SizedBox(height: AppSpacing.lg),
              StarSection(episodeId: episode.id),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.commentsTitle, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              CommentComposer(episodeId: episode.id),
              const SizedBox(height: AppSpacing.md),
              CommentsList(
                episodeId: episode.id,
                gateClosed: isSpoilerGateClosed(
                  watched: watched,
                  revealed: gateRevealed,
                ),
                onShowAnyway: onShowAnyway,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Büyük "İzlendi" düğmesi (F5a): bölüm bu ekrandan da işaretlenip geri alınabilir.
class _WatchedButton extends ConsumerWidget {
  const _WatchedButton({required this.episode, required this.watched});

  final Episode episode;

  /// null: izleme kayıtları henüz yüklenmedi.
  final bool? watched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final released = isReleased(episode, DateTime.now());
    final isWatched = watched;
    // F5(d): yayınlanmamış bölüm işaretlenemez.
    final onPressed = !released || isWatched == null
        ? null
        : () => runMarking(
            context,
            ref
                .read(watchedEpisodesProvider(episode.showId).notifier)
                .toggle(episode),
          );
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: isWatched == true
          ? FilledButton.icon(
              key: const Key('episode.watched'),
              onPressed: onPressed,
              icon: const Icon(Icons.check_circle),
              label: Text(l10n.episodeWatched),
            )
          : OutlinedButton.icon(
              key: const Key('episode.watched'),
              onPressed: onPressed,
              icon: const Icon(Icons.check),
              label: Text(l10n.episodeMarkAsWatched),
            ),
    );
  }
}
