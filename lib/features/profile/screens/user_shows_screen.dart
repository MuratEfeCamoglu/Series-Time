import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../../shows/data/models.dart';
import '../logic.dart';
import '../providers.dart';

/// "Tümü" (F8e): kullanıcının tüm dizileri, 3'lü ızgarada, son izlenene göre.
class UserShowsScreen extends ConsumerWidget {
  const UserShowsScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final AsyncValue<List<UserShow>> shows = switch (ref.watch(
      profileByUsernameProvider(username),
    )) {
      AsyncData(:final value) => ref.watch(userShowsProvider(value.id)),
      AsyncError(:final error, :final stackTrace) => AsyncError(
        error,
        stackTrace,
      ),
      _ => const AsyncLoading(),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileMyShows)),
      body: shows.when(
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              message: l10n.profileNoShows,
              icon: Icons.live_tv_outlined,
            );
          }
          final sorted = sortByLastWatched(entries);
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppSpacing.posterGridColumns,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: AppSpacing.posterAspectRatio,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final show = sorted[index].show;
              return PosterCard(
                title: show.name,
                posterPath: show.posterPath,
                onTap: () => context.push(AppRoutes.showDetail(show.id)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileByUsernameProvider(username)),
        ),
      ),
    );
  }
}
