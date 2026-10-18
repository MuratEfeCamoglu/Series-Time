import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_spacing.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/show_result_tile.dart';
import '../widgets/user_result_tile.dart';

enum DiscoverMode { shows, users }

/// Keşfet › Ara (F3a–c, F3e–f): dizi/kullanıcı araması; kutu açılışta odaklanır.
class DiscoverSearchScreen extends ConsumerStatefulWidget {
  const DiscoverSearchScreen({super.key});

  @override
  ConsumerState<DiscoverSearchScreen> createState() =>
      _DiscoverSearchScreenState();
}

class _DiscoverSearchScreenState extends ConsumerState<DiscoverSearchScreen> {
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
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(searchDebounce, () => setState(() => _query = trimmed));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoverSearchTooltip)),
      body: Column(
        children: [
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
              autofocus: true,
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
    if (_query.isEmpty) return const SizedBox.shrink();
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
