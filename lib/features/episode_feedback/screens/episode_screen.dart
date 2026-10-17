import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../shows/logic.dart';
import '../../shows/widgets/episode_still.dart';
import '../../tracking/providers.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/comments_section.dart';
import '../widgets/reactions_section.dart';
import '../widgets/star_section.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bölüm Sonrası ekranı (`/episode/:id`): tepki (F9), bölümün yıldızı (F10), yorumlar (F11).
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
    final episode = info.value?.episode;
    final watched = episode == null
        ? null
        : ref
              .watch(watchedEpisodesProvider(episode.showId))
              .value
              ?.contains(episode.id);

    return Scaffold(
      appBar: AppBar(title: Text(info.value?.showName ?? l10n.episodeTitle)),
      body: info.when(
        data: (info) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            EpisodeStill(
              stillPath: info.episode.stillPath,
              size: TmdbImageSize.original,
              semanticLabel: l10n.episodeStill(
                episodeCode(
                  info.episode.seasonNumber,
                  info.episode.episodeNumber,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              episodeCode(
                info.episode.seasonNumber,
                info.episode.episodeNumber,
              ),
              style: AppTextStyles.bodySecondary,
            ),
            if (info.episode.name case final name?)
              Text(name, style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.lg),
            ReactionsSection(episodeId: widget.episodeId),
            const SizedBox(height: AppSpacing.lg),
            StarSection(episodeId: widget.episodeId),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.commentsTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            CommentComposer(episodeId: widget.episodeId),
            const SizedBox(height: AppSpacing.md),
            CommentsList(
              episodeId: widget.episodeId,
              gateClosed: isSpoilerGateClosed(
                watched: watched,
                revealed: _gateRevealed,
              ),
              onShowAnyway: () => setState(() => _gateRevealed = true),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(episodeInfoProvider(widget.episodeId)),
        ),
      ),
    );
  }
}
