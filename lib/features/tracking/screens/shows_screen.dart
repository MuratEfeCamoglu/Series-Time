import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_spacing.dart';
import '../../auth/providers.dart';
import '../../shows/providers.dart';
import '../logic.dart';
import '../providers.dart';
import '../../social/providers.dart';
import '../widgets/poster_home.dart';
import '../widgets/show_progress_grid.dart';
import '../widgets/upcoming_section.dart';
import '../widgets/watchlist_section.dart';

/// Diziler sekmesi tek sayfa (F6): Liste/Izgara'da Son izlenen diziler, Sıradaki ve Yaklaşan (F7);
/// Afiş görünümünde [PosterHome] (F6k).
class ShowsScreen extends ConsumerWidget {
  const ShowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tabShows)),
        body: const GuestGate(),
      );
    }
    final layout = ref.watch(watchlistLayoutProvider);
    final hasShows = ref.watch(myShowsProvider).value?.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabShows),
        actions: [
          // F6(c): Liste, Izgara ve Afiş görünümleri.
          PopupMenuButton<WatchlistLayout>(
            key: const Key('watchlist.layout'),
            tooltip: l10n.layoutMenu,
            icon: Icon(switch (layout) {
              WatchlistLayout.list => Icons.view_list,
              WatchlistLayout.grid => Icons.grid_view,
              WatchlistLayout.poster => Icons.view_carousel_outlined,
            }),
            onSelected: (choice) =>
                ref.read(watchlistLayoutProvider.notifier).select(choice),
            itemBuilder: (context) => [
              for (final (choice, label) in [
                (WatchlistLayout.list, l10n.layoutList),
                (WatchlistLayout.grid, l10n.layoutGrid),
                (WatchlistLayout.poster, l10n.layoutPoster),
              ])
                CheckedPopupMenuItem(
                  key: Key('layout.${choice.name}'),
                  value: choice,
                  checked: layout == choice,
                  child: Text(label),
                ),
            ],
          ),
        ],
      ),
      body: hasShows == false
          ? EmptyState(
              message: l10n.showsEmpty,
              icon: Icons.live_tv_outlined,
              actionLabel: l10n.showsGoToDiscover,
              onAction: () => context.go(AppRoutes.discover),
            )
          : RefreshIndicator(
              onRefresh: () {
                ref
                  ..invalidate(myShowProgressProvider)
                  ..invalidate(upcomingProvider)
                  ..invalidate(friendsActivityProvider);
                return ref.refresh(watchlistProvider.future);
              },
              child: layout == WatchlistLayout.poster
                  ? const PosterHome()
                  : const CustomScrollView(
                      slivers: [
                        _RecentShows(),
                        WatchlistSection(),
                        UpcomingSection(),
                        SliverPadding(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                        ),
                      ],
                    ),
            ),
    );
  }
}

/// "Son izlenen diziler" satırı; hiç izleme yoksa gösterilmez (F6).
class _RecentShows extends ConsumerWidget {
  const _RecentShows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shows = recentlyWatchedShows(
      ref.watch(myShowProgressProvider).value ?? const [],
    );
    if (shows.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Column(
        key: const Key('shows.recent'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: AppLocalizations.of(context).recentShowsTitle),
          ShowProgressRow(shows: shows),
        ],
      ),
    );
  }
}
