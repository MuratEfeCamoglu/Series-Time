import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/section_pill.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import 'watchlist_tile.dart';

/// Diziler sayfasının Sıradaki bölümü (F6a–g); sliver olarak döner.
class WatchlistSection extends ConsumerWidget {
  const WatchlistSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final layout = ref.watch(watchlistLayoutProvider);
    final header = SliverToBoxAdapter(
      child: SectionHeader(title: l10n.tabWatchlist),
    );
    return ref
        .watch(watchlistProvider)
        .when(
          // İşaretleme sonrası yenilemede eski liste ekranda kalır, iskelet gösterilmez.
          skipLoadingOnRefresh: true,
          data: (items) {
            if (items.isEmpty) {
              return SliverMainAxisGroup(
                slivers: [
                  header,
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.watchlistAllCaughtUp,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  ),
                ],
              );
            }
            final split = splitWatchlist(items, DateTime.now());
            return SliverMainAxisGroup(
              slivers: [
                header,
                if (split.upNext.isNotEmpty)
                  ..._section(l10n.watchlistUpNext, split.upNext, layout),
                if (split.notStarted.isNotEmpty)
                  ..._section(
                    l10n.watchlistNotStarted,
                    split.notStarted,
                    layout,
                  ),
                if (split.notRecently.isNotEmpty)
                  ..._section(
                    l10n.watchlistNotRecently,
                    split.notRecently,
                    layout,
                  ),
              ],
            );
          },
          loading: () => SliverMainAxisGroup(
            slivers: [
              header,
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, _) => SliverMainAxisGroup(
            slivers: [
              header,
              SliverToBoxAdapter(
                child: ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(watchlistProvider),
                ),
              ),
            ],
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
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      sliver: SliverToBoxAdapter(child: SectionPill(title: title)),
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
