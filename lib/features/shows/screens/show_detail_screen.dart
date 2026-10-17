import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/section_pill.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../tracking/logic.dart';
import '../../tracking/providers.dart';
import '../../tracking/widgets/favorite_button.dart';
import '../../tracking/widgets/status_sheet.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/episode_banner.dart';
import 'season_screen.dart';

/// Dizi detayı (F4): arka plan, afiş, ad, yıl, durum, listeye ekleme/çıkarma; Hakkında
/// (özet) ve Bölümler (sıradaki bölüm, sezon kartları) sekmeleri.
class ShowDetailScreen extends ConsumerWidget {
  const ShowDetailScreen({super.key, required this.showId});

  final int showId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ref
          .watch(showDetailProvider(showId))
          .when(
            data: (detail) => _DetailBody(detail: detail),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => SafeArea(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(),
                  ),
                  Expanded(
                    child: ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(showDetailProvider(showId)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

/// Hakkında / Bölümler sekmeleri; açılışta Bölümler seçilidir.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final ShowDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final show = detail.show;
    final seasons = splitSeasons(detail.seasons);
    final backdrop = tmdbImageUrl(show.backdropPath, TmdbImageSize.w780);
    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: AppSpacing.detailBackdropHeight,
            title: Text(show.name),
            flexibleSpace: FlexibleSpaceBar(
              background: backdrop == null
                  ? const ColoredBox(color: AppColors.surface)
                  : CachedNetworkImage(
                      imageUrl: backdrop,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const ColoredBox(color: AppColors.surface),
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: _Header(
                show: show,
                seasonNumbers: [
                  for (final s in seasons.regular) s.seasonNumber,
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                tabs: [
                  Tab(text: l10n.showTabAbout),
                  Tab(text: l10n.showTabEpisodes),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _AboutTab(show: show),
            _EpisodesTab(
              showId: show.id,
              regular: seasons.regular,
              specials: seasons.specials,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: AppColors.background, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _Header extends ConsumerWidget {
  const _Header({required this.show, required this.seasonNumbers});

  final Show show;
  final List<int> seasonNumbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mine = ref.watch(myShowEntryProvider(show.id));
    final year = show.firstAirDate?.year;
    final status = switch (showRunStatus(show.status)) {
      ShowRunStatus.ongoing => l10n.showStatusOngoing,
      ShowRunStatus.ended => l10n.showStatusEnded,
      ShowRunStatus.unknown => null,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSpacing.detailPosterWidth,
          child: PosterCard(
            key: const Key('showDetail.poster'),
            title: show.name,
            posterPath: mine?.posterPath ?? show.posterPath,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(show.name, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [?year?.toString(), ?status].join(' · '),
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MyShowsButton(show: show, seasonNumbers: seasonNumbers),
                  // F4(b): listedeki dizinin grubu buradan değiştirilir (F6j).
                  ShowStatusButton(showId: show.id),
                  ShowFavoriteButton(showId: show.id),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutTab extends ConsumerWidget {
  const _AboutTab({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (show.overview.isNotEmpty) ...[
          Text(show.overview, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(l10n.showCastTitle, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        ref
            .watch(showCastProvider(show.id))
            .when(
              data: (cast) => cast.isEmpty
                  ? Text(l10n.showCastEmpty, style: AppTextStyles.bodySecondary)
                  : SizedBox(
                      height: AppSpacing.castRowHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cast.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) =>
                            _CastPerson(member: cast[index]),
                      ),
                    ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(showCastProvider(show.id)),
              ),
            ),
        // F4(f): yalnızca listedeki dizinin afişi seçilebilir.
        if (ref.watch(myShowEntryProvider(show.id)) != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.posterPickerTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          _PosterPicker(show: show),
        ],
      ],
    );
  }
}

/// F4(f): dizinin TMDB afişleri; seçilen işaretli, "Varsayılan" TMDB afişine döner.
class _PosterPicker extends ConsumerWidget {
  const _PosterPicker({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(myShowEntryProvider(show.id))?.customPosterPath;
    Future<void> choose(String? path) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(myShowsProvider.notifier).setPoster(show.id, path);
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
      }
    }

    return ref
        .watch(showImagesProvider(show.id))
        .when(
          data: (images) {
            final paths = [
              ?show.posterPath,
              for (final p in images.posters)
                if (p != show.posterPath) p,
            ];
            if (paths.isEmpty) {
              return Text(
                l10n.posterPickerEmpty,
                style: AppTextStyles.bodySecondary,
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppSpacing.posterGridColumns,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: AppSpacing.posterAspectRatio,
              ),
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final path = paths[index];
                // TMDB afişi seçimi "Varsayılan"dır (null kaydedilir).
                final isDefault = path == show.posterPath;
                final isSelected = isDefault
                    ? selected == null || selected == path
                    : selected == path;
                return Semantics(
                  selected: isSelected,
                  button: true,
                  label: isDefault ? l10n.posterDefault : show.name,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PosterCard(
                        key: Key('posterPicker.$index'),
                        title: show.name,
                        posterPath: path,
                        onTap: () => choose(isDefault ? null : path),
                      ),
                      if (isDefault)
                        Positioned(
                          left: AppSpacing.xs,
                          bottom: AppSpacing.xs,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.xs,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              child: Text(
                                l10n.posterDefault,
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ),
                        ),
                      if (isSelected)
                        const IgnorePointer(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xs),
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(showImagesProvider(show.id)),
          ),
        );
  }
}

class _CastPerson extends StatelessWidget {
  const _CastPerson({required this.member});

  final ShowCastMember member;

  @override
  Widget build(BuildContext context) {
    final character = member.character;
    return SizedBox(
      key: Key('cast.${member.personId}'),
      width: AppSpacing.castCardWidth,
      child: Column(
        children: [
          ProfileAvatar(
            size: AppSpacing.castPhotoSize,
            url: tmdbImageUrl(member.profilePath, TmdbImageSize.w185),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            member.name,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (character != null)
            Text(
              character,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// Bölümler sekmesi: "Sıradaki" bandı ve açılır sezon kartları (F4a, F5b).
class _EpisodesTab extends ConsumerWidget {
  const _EpisodesTab({
    required this.showId,
    required this.regular,
    required this.specials,
  });

  final int showId;
  final List<Season> regular;
  final List<Season> specials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final episodes = ref.watch(showEpisodesProvider(showId)).value ?? const [];
    final watched =
        ref.watch(watchedEpisodesProvider(showId)).value ?? const {};
    final now = DateTime.now();
    final next = nextUnwatchedEpisode(episodes, watched, now);
    final hasAired = episodes.any((e) => isAired(e, now));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        // Bölümler henüz önbellekte yoksa (liste dışı dizi) bant gösterilmez.
        if (next != null || hasAired) ...[
          SectionPill(title: l10n.showNextEpisode),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: EpisodeBanner(
              key: const Key('showDetail.next'),
              episode: next,
              label: next == null ? l10n.showAllWatched : null,
              onTap: next == null
                  ? null
                  : ref.read(isGuestProvider)
                  ? () => showGuestGate(context)
                  : () => context.push(AppRoutes.episode(next.id)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        SectionPill(title: l10n.showAllEpisodes),
        const SizedBox(height: AppSpacing.sm),
        for (final season in [...regular, ...specials])
          _SeasonCard(
            key: ValueKey(season.id),
            season: season,
            cachedEpisodes: [
              for (final e in episodes)
                if (e.seasonNumber == season.seasonNumber) e,
            ],
            watched: watched,
          ),
      ],
    );
  }
}

/// "1. Sezon ⌄ 13/13 ✓" kartı: dokununca bölümler altında açılır/kapanır, yuvarlak
/// düğme sezonu işaretler (F5b).
class _SeasonCard extends ConsumerStatefulWidget {
  const _SeasonCard({
    super.key,
    required this.season,
    required this.cachedEpisodes,
    required this.watched,
  });

  final Season season;

  /// Önbellekteki bölümler; sezon hiç açılmadıysa boş olabilir.
  final List<Episode> cachedEpisodes;
  final Set<int> watched;

  @override
  ConsumerState<_SeasonCard> createState() => _SeasonCardState();
}

class _SeasonCardState extends ConsumerState<_SeasonCard> {
  bool _expanded = false;

  ({int showId, int seasonNumber}) get _key =>
      (showId: widget.season.showId, seasonNumber: widget.season.seasonNumber);

  Future<void> _markSeason() async {
    if (ref.read(isGuestProvider)) return showGuestGate(context);
    // Bölümler önbellekte yoksa önce çekilir; RPC yalnızca önbellekteki bölümleri işaretler.
    final seasonEpisodes = widget.cachedEpisodes.isNotEmpty
        ? widget.cachedEpisodes
        : await ref.read(seasonEpisodesProvider(_key).future);
    if (!mounted) return;
    await runMarking(
      context,
      ref
          .read(watchedEpisodesProvider(widget.season.showId).notifier)
          .markSeason(widget.season.seasonNumber, seasonEpisodes),
    );
    ref.invalidate(showEpisodesProvider(widget.season.showId));
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    // Açılınca TMDB'den çekilen bölümler sezon sayılarını da günceller.
    if (_expanded && widget.cachedEpisodes.isEmpty) {
      ref
          .read(seasonEpisodesProvider(_key).future)
          .then((_) => ref.invalidate(showEpisodesProvider(_key.showId)))
          .ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final season = widget.season;
    final progress = seasonProgress(
      widget.cachedEpisodes,
      widget.watched,
      DateTime.now(),
    );
    final total = widget.cachedEpisodes.isEmpty
        ? (season.episodeCount ?? 0)
        : progress.released;
    final complete = total > 0 && progress.watched == total;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            key: Key('season.${season.seasonNumber}'),
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: _toggle,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            season.name ??
                                l10n.seasonTitle(season.seasonNumber),
                            style: AppTextStyles.title,
                          ),
                        ),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          semanticLabel: _expanded
                              ? l10n.seasonCollapse
                              : l10n.seasonExpand,
                        ),
                        const Spacer(),
                        Text(
                          l10n.seasonProgress(progress.watched, total),
                          style: AppTextStyles.bodySecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          key: Key('season.markAll.${season.seasonNumber}'),
                          tooltip: complete
                              ? l10n.seasonCompleted
                              : l10n.seasonMarkAll,
                          onPressed: complete ? null : _markSeason,
                          icon: Icon(
                            complete
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: complete
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProgressBar(value: total == 0 ? 0 : progress.watched / total),
                ],
              ),
            ),
          ),
          if (_expanded)
            ref
                .watch(seasonEpisodesProvider(_key))
                .when(
                  data: (episodes) => episodes.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            l10n.seasonNoEpisodes,
                            style: AppTextStyles.bodySecondary,
                          ),
                        )
                      : Column(
                          children: [
                            for (final episode in episodes)
                              EpisodeBannerTile(
                                episode: episode,
                                seasonEpisodes: episodes,
                                watched: ref
                                    .watch(
                                      watchedEpisodesProvider(season.showId),
                                    )
                                    .value
                                    ?.contains(episode.id),
                              ),
                          ],
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(seasonEpisodesProvider(_key)),
                  ),
                ),
        ],
      ),
    );
  }
}

/// "Ekle" / "Listeden çıkar". Çıkarma onay ister (F4c); hata olursa liste geri alınır.
class _MyShowsButton extends ConsumerWidget {
  const _MyShowsButton({required this.show, required this.seasonNumbers});

  final Show show;
  final List<int> seasonNumbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inList = ref.watch(isInMyShowsProvider(show.id));
    if (!inList) {
      return FilledButton.icon(
        key: const Key('showDetail.add'),
        onPressed: ref.watch(isGuestProvider)
            ? () => showGuestGate(context)
            : () => _run(
                context,
                ref
                    .read(myShowsProvider.notifier)
                    .add(show, seasonNumbers: seasonNumbers),
              ),
        icon: const Icon(Icons.add),
        label: Text(l10n.showAdd),
      );
    }
    return OutlinedButton.icon(
      key: const Key('showDetail.remove'),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.showRemoveConfirmTitle),
            content: Text(l10n.showRemoveConfirmBody(show.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                key: const Key('showDetail.confirmRemove'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.showRemoveConfirmButton),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await _run(context, ref.read(myShowsProvider.notifier).remove(show.id));
      },
      icon: const Icon(Icons.check),
      label: Text(l10n.showRemove),
    );
  }

  Future<void> _run(BuildContext context, Future<void> mutation) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).saveFailed;
    try {
      await mutation;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
