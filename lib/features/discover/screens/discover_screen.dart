import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/show_result_tile.dart';
import '../widgets/suggest_card.dart';
import '../widgets/user_result_tile.dart';

enum DiscoverMode { shows, users }

/// Keşfet sekmesi (F3): dizi/kullanıcı araması ve boş aramada trend diziler.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  DiscoverMode _mode = DiscoverMode.shows;
  // Yazma durduktan [searchDebounce] sonra güncellenir; istek bu değerle atılır (F3b).
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      // Kutu temizlenince trendler beklemeden geri gelir.
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(searchDebounce, () => setState(() => _query = trimmed));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabDiscover)),
      body: Column(
        children: [
          const SuggestCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<DiscoverMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: DiscoverMode.shows,
                    label: Text(l10n.discoverSegmentShows),
                  ),
                  ButtonSegment(
                    value: DiscoverMode.users,
                    label: Text(l10n.discoverSegmentUsers),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    setState(() => _mode = selection.single),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              key: const Key('discover.search'),
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: _mode == DiscoverMode.shows
                    ? l10n.discoverSearchShowsHint
                    : l10n.discoverSearchUsersHint,
              ),
            ),
          ),
          Expanded(child: _results(l10n)),
        ],
      ),
    );
  }

  Widget _results(AppLocalizations l10n) {
    if (_query.isEmpty) {
      return _mode == DiscoverMode.shows
          ? const _PopularGrid()
          : const SizedBox.shrink();
    }
    if (!canSearch(_query)) {
      return EmptyState(
        message: l10n.discoverSearchMinChars,
        icon: Icons.keyboard,
      );
    }
    return switch (_mode) {
      DiscoverMode.shows => _ShowResults(query: _query),
      DiscoverMode.users => _UserResults(query: _query),
    };
  }
}

class _PopularGrid extends ConsumerWidget {
  const _PopularGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(popularShowsProvider)
        .when(
          data: (shows) => CustomScrollView(
            slivers: [
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
                  itemCount: shows.length,
                  itemBuilder: (context, index) {
                    final show = shows[index];
                    return PosterCard(
                      title: show.name,
                      posterPath: show.posterPath,
                      onTap: () => context.push(AppRoutes.showDetail(show.id)),
                    );
                  },
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(popularShowsProvider),
          ),
        );
  }
}

class _ShowResults extends ConsumerWidget {
  const _ShowResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(showSearchProvider(query))
        .when(
          data: (shows) => shows.isEmpty
              ? EmptyState(message: AppLocalizations.of(context).noResults)
              : ListView.builder(
                  itemCount: shows.length,
                  itemBuilder: (context, index) =>
                      ShowResultTile(show: shows[index]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(showSearchProvider(query)),
          ),
        );
  }
}

class _UserResults extends ConsumerWidget {
  const _UserResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(userSearchProvider(query))
        .when(
          data: (users) => users.isEmpty
              ? EmptyState(message: AppLocalizations.of(context).noResults)
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) =>
                      UserResultTile(profile: users[index]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(userSearchProvider(query)),
          ),
        );
  }
}
