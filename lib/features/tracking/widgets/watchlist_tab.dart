import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/providers.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import 'watchlist_tile.dart';

/// Diziler › İzleme Listesi (F6).
class WatchlistTab extends ConsumerWidget {
  const WatchlistTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasShows = ref.watch(myShowsProvider).value?.isNotEmpty;
    if (hasShows == false) {
      return EmptyState(
        message: l10n.showsEmpty,
        icon: Icons.live_tv_outlined,
        actionLabel: l10n.showsGoToDiscover,
        onAction: () => context.go(AppRoutes.discover),
      );
    }
    final layout = ref.watch(watchlistLayoutProvider);
    return ref
        .watch(watchlistProvider)
        .when(
          // İşaretleme sonrası yenilemede eski liste ekranda kalır, iskelet gösterilmez.
          skipLoadingOnRefresh: true,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                message: l10n.watchlistAllCaughtUp,
                icon: Icons.check_circle_outline,
              );
            }
            final split = splitWatchlist(items, DateTime.now());
            return RefreshIndicator(
              onRefresh: () => ref.refresh(watchlistProvider.future),
              child: CustomScrollView(
                slivers: [
                  if (split.upNext.isNotEmpty)
                    ..._section(l10n.watchlistUpNext, split.upNext, layout),
                  if (split.notRecently.isNotEmpty)
                    ..._section(
                      l10n.watchlistNotRecently,
                      split.notRecently,
                      layout,
                    ),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(watchlistProvider),
          ),
        );
  }

  List<Widget> _section(
    String title,
    List<WatchlistItem> items,
    WatchlistLayout layout,
  ) => [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      sliver: SliverToBoxAdapter(
        child: Text(title, style: AppTextStyles.title),
      ),
    ),
    // F6(h): ızgara ve liste tembel oluşturulur; 100 dizide yalnızca görünenler çizilir.
    if (layout == WatchlistLayout.grid)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppSpacing.posterGridColumns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: AppSpacing.watchlistGridAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => WatchlistTile(
            key: ValueKey(items[index].showId),
            item: items[index],
            layout: layout,
          ),
        ),
      )
    else
      SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => WatchlistTile(
          key: ValueKey(items[index].showId),
          item: items[index],
          layout: layout,
        ),
      ),
  ];
}
