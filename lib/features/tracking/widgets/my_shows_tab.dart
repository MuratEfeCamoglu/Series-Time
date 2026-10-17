import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../logic.dart';
import '../providers.dart';
import 'show_progress_grid.dart';

/// Diziler › Dizilerim (F6j): listedeki tüm diziler, gruplara göre filtrelenir.
class MyShowsTab extends ConsumerStatefulWidget {
  const MyShowsTab({super.key});

  @override
  ConsumerState<MyShowsTab> createState() => _MyShowsTabState();
}

class _MyShowsTabState extends ConsumerState<MyShowsTab> {
  ShowStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(myShowProgressProvider)
        .when(
          skipLoadingOnRefresh: true,
          data: (shows) {
            if (shows.isEmpty) {
              return EmptyState(
                message: l10n.showsEmpty,
                icon: Icons.live_tv_outlined,
                actionLabel: l10n.showsGoToDiscover,
                onAction: () => context.go(AppRoutes.discover),
              );
            }
            final filtered = filterByStatus(shows, _filter);
            return Column(
              children: [
                StatusFilterChips(
                  selected: _filter,
                  onSelected: (status) => setState(() => _filter = status),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          message: l10n.statusFilterEmpty,
                          icon: Icons.filter_list_off,
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.refresh(myShowProgressProvider.future),
                          child: ShowProgressGrid(shows: filtered),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(myShowProgressProvider),
          ),
        );
  }
}
