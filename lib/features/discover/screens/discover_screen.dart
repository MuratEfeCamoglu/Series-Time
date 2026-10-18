import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../providers.dart';
import '../widgets/on_the_air_row.dart';
import '../widgets/suggest_card.dart';

/// Keşfet sekmesi (F3): üstte kompakt öneri bandı, "Şu an yayında" ve en ünlü diziler;
/// arama üst çubuktaki simgeyle ayrı sayfada açılır (kullanıcı kararı 2026-10-18).
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabDiscover),
        actions: [
          IconButton(
            key: const Key('discover.searchButton'),
            tooltip: l10n.discoverSearchTooltip,
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.discoverSearch),
          ),
        ],
      ),
      body: const _PopularGrid(),
    );
  }
}

class _PopularGrid extends ConsumerWidget {
  const _PopularGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final popular = ref.watch(popularShowsProvider);
    return NotificationListener<ScrollNotification>(
      // F3(d): aşağı kaydırınca en ünlü dizilerin sonraki sayfası.
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.vertical &&
            metrics.extentAfter < AppSpacing.loadMoreThreshold) {
          ref.read(popularShowsProvider.notifier).loadMore().ignore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SuggestCard()),
          // F3(g): "Şu an yayında" öneri bandının altında, en ünlü dizilerin üstünde.
          const SliverToBoxAdapter(child: OnTheAirRow()),
          ...popular.when(
            data: (state) => [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    l10n.discoverPopularTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppSpacing.posterGridColumns,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: AppSpacing.posterAspectRatio,
                  ),
                  itemCount: state.shows.length,
                  itemBuilder: (context, index) {
                    final show = state.shows[index];
                    return PosterCard(
                      title: show.name,
                      posterPath: show.posterPath,
                      onTap: () => context.push(AppRoutes.showDetail(show.id)),
                    );
                  },
                ),
              ),
              if (state.loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
            loading: () => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
            error: (error, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(popularShowsProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
