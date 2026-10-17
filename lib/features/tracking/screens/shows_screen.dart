import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../../shows/providers.dart';

/// Diziler sekmesi. Şimdilik listedeki diziler (F4b); İzleme Listesi ve Yaklaşan
/// sekmeleri Aşama 3'te (F6, F7) bu ekranın yerini alır.
class ShowsScreen extends ConsumerWidget {
  const ShowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabShows)),
      body: ref
          .watch(myShowsProvider)
          .when(
            data: (entries) => entries.isEmpty
                ? EmptyState(
                    message: l10n.showsEmpty,
                    icon: Icons.live_tv_outlined,
                    actionLabel: l10n.showsGoToDiscover,
                    onAction: () => context.go(AppRoutes.discover),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppSpacing.posterGridColumns,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: AppSpacing.posterAspectRatio,
                        ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final show = entries[index].show;
                      return PosterCard(
                        title: show.name,
                        posterPath: show.posterPath,
                        onTap: () =>
                            context.push(AppRoutes.showDetail(show.id)),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(myShowsProvider),
            ),
          ),
    );
  }
}
