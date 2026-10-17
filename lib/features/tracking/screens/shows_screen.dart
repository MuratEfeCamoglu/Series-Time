import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../auth/providers.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/on_the_air_row.dart';
import '../widgets/upcoming_tab.dart';
import '../widgets/watchlist_tab.dart';

/// Diziler sekmesi: Şu an yayında (F6i), İzleme Listesi (F6) ve Yaklaşan (F7).
class ShowsScreen extends ConsumerWidget {
  const ShowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tabShows)),
        body: const Column(
          children: [
            OnTheAirRow(),
            Expanded(child: GuestGate()),
          ],
        ),
      );
    }
    final layout = ref.watch(watchlistLayoutProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabShows),
          actions: [
            IconButton(
              key: const Key('watchlist.layout'),
              tooltip: layout == WatchlistLayout.grid
                  ? l10n.watchlistShowList
                  : l10n.watchlistShowGrid,
              icon: Icon(
                layout == WatchlistLayout.grid
                    ? Icons.view_list
                    : Icons.grid_view,
              ),
              onPressed: () =>
                  ref.read(watchlistLayoutProvider.notifier).toggle(),
            ),
          ],
        ),
        // F6(i): "Şu an yayında" sekmelerin üstünde, uygulama açılınca ilk görünen yer.
        body: Column(
          children: [
            const OnTheAirRow(),
            TabBar(
              tabs: [
                Tab(text: l10n.tabWatchlist),
                Tab(text: l10n.tabUpcoming),
              ],
            ),
            const Expanded(
              child: TabBarView(children: [WatchlistTab(), UpcomingTab()]),
            ),
          ],
        ),
      ),
    );
  }
}
