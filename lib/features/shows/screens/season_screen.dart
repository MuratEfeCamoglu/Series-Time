import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../tracking/providers.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/episode_still.dart';

/// Sezonun bölümleri (F4a, F5): no, ad, yayın tarihi, izlendi onay kutusu.
/// Onay kutusu işaretler (F4e); satırın geri kalanı Bölüm Sonrası ekranını açar.
/// Satıra uzun basmak "Buraya kadar izledim" seçeneğini gösterir.
class SeasonScreen extends ConsumerWidget {
  const SeasonScreen({
    super.key,
    required this.showId,
    required this.seasonNumber,
    this.title,
  });

  final int showId;
  final int seasonNumber;

  /// Önceki ekrandan gelen sezon adı; derin bağlantıyla açılınca yoktur.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final key = (showId: showId, seasonNumber: seasonNumber);
    final episodes = ref.watch(seasonEpisodesProvider(key));
    final watched = ref.watch(watchedEpisodesProvider(showId));
    final loaded = episodes.value;
    final now = DateTime.now();
    final isGuest = ref.watch(isGuestProvider);
    final canMarkAll =
        loaded != null &&
        watched.hasValue &&
        loaded.any((e) => isReleased(e, now));

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? l10n.seasonTitle(seasonNumber)),
        actions: [
          IconButton(
            key: const Key('season.markAll'),
            tooltip: l10n.seasonMarkAll,
            icon: const Icon(Icons.done_all),
            // F19(c): misafir işaretleyemez; düğme hesap çağrısını açar.
            onPressed: isGuest
                ? () => showGuestGate(context)
                : canMarkAll
                ? () => runMarking(
                    context,
                    ref
                        .read(watchedEpisodesProvider(showId).notifier)
                        .markSeason(seasonNumber, loaded),
                  )
                : null,
          ),
        ],
      ),
      body: episodes.when(
        data: (episodes) => episodes.isEmpty
            ? EmptyState(message: l10n.seasonNoEpisodes)
            : ListView.builder(
                itemCount: episodes.length,
                itemBuilder: (context, index) => _EpisodeTile(
                  episode: episodes[index],
                  seasonEpisodes: episodes,
                  watched: watched.value?.contains(episodes[index].id),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(seasonEpisodesProvider(key)),
        ),
      ),
    );
  }
}

/// İşaretleme hatasında F5(e) iletisi; iyimser durum sağlayıcıda zaten geri alınmıştır.
Future<void> runMarking(BuildContext context, Future<void> mutation) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).saveFailed;
  try {
    await mutation;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({
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
    final airDate = episode.airDate;
    final released = isReleased(episode, DateTime.now());
    final notifier = ref.read(watchedEpisodesProvider(episode.showId).notifier);
    final isWatched = watched;
    if (ref.watch(isGuestProvider)) {
      void gate() => showGuestGate(context);
      return ListTile(
        leading: _EpisodeLeading(episode: episode),
        title: Text(episode.name ?? '', style: AppTextStyles.body),
        subtitle: Text(
          airDate == null ? l10n.episodeNoAirDate : formatLongDate(airDate),
          style: AppTextStyles.bodySecondary,
        ),
        trailing: Checkbox(
          key: Key('episode.check.${episode.id}'),
          semanticLabel: l10n.episodeMarkWatched,
          value: false,
          onChanged: released ? (_) => gate() : null,
        ),
        onTap: gate,
      );
    }

    return ListTile(
      leading: _EpisodeLeading(episode: episode),
      title: Text(episode.name ?? '', style: AppTextStyles.body),
      subtitle: Text(
        airDate == null ? l10n.episodeNoAirDate : formatLongDate(airDate),
        style: AppTextStyles.bodySecondary,
      ),
      trailing: Checkbox(
        key: Key('episode.check.${episode.id}'),
        semanticLabel: l10n.episodeMarkWatched,
        value: isWatched ?? false,
        // F5(d): yayınlanmamış bölüm işaretlenemez.
        onChanged: !released || isWatched == null
            ? null
            : (_) {
                runMarking(context, notifier.toggle(episode));
                // F5(f): tek bölüm işaretlenince (geri alınınca değil) Bölüm Sonrası açılır.
                if (!isWatched) context.push(AppRoutes.episode(episode.id));
              },
      ),
      onTap: () => context.push(AppRoutes.episode(episode.id)),
      onLongPress: !released || isWatched == null
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
    );
  }
}

/// Bölüm numarası ve sahne görseli (F4a).
class _EpisodeLeading extends StatelessWidget {
  const _EpisodeLeading({required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: AppSpacing.stillThumbWidth,
      child: Stack(
        children: [
          EpisodeStill(
            stillPath: episode.stillPath,
            semanticLabel: l10n.episodeStill(
              episodeCode(episode.seasonNumber, episode.episodeNumber),
            ),
          ),
          Positioned(
            left: AppSpacing.xs,
            bottom: AppSpacing.xs,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '${episode.episodeNumber}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
