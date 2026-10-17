import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';

/// Dizi detayı (F4): arka plan, afiş, ad, yıl, durum, özet, sezonlar ve listeye ekleme/çıkarma.
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final ShowDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final show = detail.show;
    final seasons = splitSeasons(detail.seasons);
    final backdrop = tmdbImageUrl(show.backdropPath, TmdbImageSize.w780);
    return CustomScrollView(
      slivers: [
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
          sliver: SliverToBoxAdapter(child: _Header(show: show)),
        ),
        if (seasons.regular.isNotEmpty)
          _SeasonSection(title: l10n.showSeasons, seasons: seasons.regular),
        if (seasons.specials.isNotEmpty)
          _SeasonSection(title: l10n.showSpecials, seasons: seasons.specials),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.lg)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final year = show.firstAirDate?.year;
    final status = switch (showRunStatus(show.status)) {
      ShowRunStatus.ongoing => l10n.showStatusOngoing,
      ShowRunStatus.ended => l10n.showStatusEnded,
      ShowRunStatus.unknown => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppSpacing.detailPosterWidth,
              child: PosterCard(title: show.name, posterPath: show.posterPath),
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
                  _MyShowsButton(show: show),
                ],
              ),
            ),
          ],
        ),
        if (show.overview.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(show.overview, style: AppTextStyles.body),
        ],
      ],
    );
  }
}

/// "Ekle" / "Listeden çıkar". Çıkarma onay ister (F4c); hata olursa liste geri alınır.
class _MyShowsButton extends ConsumerWidget {
  const _MyShowsButton({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inList = ref.watch(isInMyShowsProvider(show.id));
    if (!inList) {
      return FilledButton.icon(
        key: const Key('showDetail.add'),
        onPressed: () =>
            _run(context, ref.read(myShowsProvider.notifier).add(show)),
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

class _SeasonSection extends StatelessWidget {
  const _SeasonSection({required this.title, required this.seasons});

  final String title;
  final List<Season> seasons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(title, style: AppTextStyles.title),
          ),
        ),
        SliverList.builder(
          itemCount: seasons.length,
          itemBuilder: (context, index) {
            final season = seasons[index];
            final count = season.episodeCount;
            return ListTile(
              title: Text(
                season.name ?? l10n.seasonTitle(season.seasonNumber),
                style: AppTextStyles.body,
              ),
              subtitle: count == null
                  ? null
                  : Text(
                      l10n.seasonEpisodeCount(count),
                      style: AppTextStyles.bodySecondary,
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                AppRoutes.season(season.showId, season.seasonNumber),
                extra: season.name,
              ),
            );
          },
        ),
      ],
    );
  }
}
