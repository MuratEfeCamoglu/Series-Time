import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_spacing.dart';
import '../data/models.dart';
import '../logic.dart';
import 'status_style.dart';

/// Gruplara göre filtre çipleri (F6j); [selected] null ise "Tümü".
class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ShowStatus? selected;
  final ValueChanged<ShowStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget chip(ShowStatus? status) => ChoiceChip(
      key: Key('statusFilter.${status?.name ?? 'all'}'),
      avatar: status == null ? null : StatusDot(status: status),
      label: Text(
        status == null ? l10n.statusFilterAll : statusLabel(l10n, status),
      ),
      selected: selected == status,
      showCheckmark: false,
      onSelected: (_) => onSelected(status),
    );
    // Yalnızca 7 çip: tembel liste gerekmez.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (final status in [null, ...showStatusOrder]) chip(status),
        ],
      ),
    );
  }
}

/// Afiş ve altında grup renginde çubuk (Dizilerim, profil, Tümü).
class ShowProgressPoster extends StatelessWidget {
  const ShowProgressPoster({super.key, required this.show, this.heroScope});

  final ShowProgress show;

  /// Verilirse afiş detaya Hero ile geçer; etiket `scope-showId` biçimindedir.
  final String? heroScope;

  @override
  Widget build(BuildContext context) {
    final status = showStatusOf(
      tmdbStatus: show.showStatus,
      airedCount: show.airedCount,
      watchedCount: show.watchedCount,
      manual: show.manualStatus,
    );
    final scope = heroScope;
    final tag = scope == null ? null : '$scope-${show.showId}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PosterCard(
            title: show.name,
            posterPath: show.posterPath,
            heroTag: tag,
            onTap: () =>
                context.push(AppRoutes.showDetail(show.showId), extra: tag),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        StatusProgressBar(
          key: Key('statusBar.${show.showId}'),
          status: status,
          watchedCount: show.watchedCount,
          airedCount: show.airedCount,
        ),
      ],
    );
  }
}

/// 3'lü tembel ızgara (F6h).
class ShowProgressGrid extends StatelessWidget {
  const ShowProgressGrid({super.key, required this.shows, this.heroScope});

  final List<ShowProgress> shows;

  /// Hero etiketi öneki; alt menü sekmeleri aynı anda bellekte durduğu için her
  /// liste kendi önekini verir (ör. "watching", "myShows").
  final String? heroScope;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSpacing.posterGridColumns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: AppSpacing.progressGridAspectRatio,
      ),
      itemCount: shows.length,
      itemBuilder: (context, index) => EntranceAnimation(
        index: index,
        child: ShowProgressPoster(
          key: ValueKey(shows[index].showId),
          show: shows[index],
          heroScope: heroScope,
        ),
      ),
    );
  }
}

/// Yatay afiş satırı (Son izlenenler, Şu an izlediklerim).
class ShowProgressRow extends StatelessWidget {
  const ShowProgressRow({
    super.key,
    required this.shows,
    this.height = AppSpacing.posterRowHeight,
    this.heroScope,
  });

  final List<ShowProgress> shows;
  final double height;

  /// Bkz. [ShowProgressGrid.heroScope].
  final String? heroScope;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: shows.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => SizedBox(
          width: height * AppSpacing.posterAspectRatio,
          child: EntranceAnimation(
            index: index,
            child: ShowProgressPoster(
              key: ValueKey(shows[index].showId),
              show: shows[index],
              heroScope: heroScope,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kaydırılan sayfanın içindeki 3'lü tembel ızgara (profil Dizilerim, F6h).
class SliverShowProgressGrid extends StatelessWidget {
  const SliverShowProgressGrid({
    super.key,
    required this.shows,
    this.columns = AppSpacing.posterGridColumns,
    this.heroScope,
  });

  final List<ShowProgress> shows;
  final int columns;

  /// Bkz. [ShowProgressGrid.heroScope].
  final String? heroScope;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: AppSpacing.progressGridAspectRatio,
        ),
        itemCount: shows.length,
        itemBuilder: (context, index) => EntranceAnimation(
          index: index,
          child: ShowProgressPoster(
            key: ValueKey(shows[index].showId),
            show: shows[index],
            heroScope: heroScope,
          ),
        ),
      ),
    );
  }
}
