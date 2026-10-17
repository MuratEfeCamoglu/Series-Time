import '../../../core/app_locale.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../auth/providers.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/data/models.dart';
import '../../shows/providers.dart';
import '../logic.dart';
import '../providers.dart';

/// `/suggest` (F18): kategori çipleri, "İzlediklerine benzer" ve türe göre öneri ızgarası.
class SuggestScreen extends ConsumerWidget {
  const SuggestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedGenresProvider);
    // F18(e): listeye eklenen dizi sunucuyu beklemeden ızgaradan kalkar.
    final myShowIds = {
      for (final entry
          in ref.watch(myShowsProvider).value ?? const <UserShow>[])
        entry.show.id,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.suggestTitle)),
      body: NotificationListener<ScrollNotification>(
        // F18(d): aşağı kaydırınca sonraki sayfa.
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.axis == Axis.vertical &&
              metrics.extentAfter < AppSpacing.loadMoreThreshold) {
            ref.read(suggestionsProvider.notifier).loadMore().ignore();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _GenreChips()),
            _SimilarSection(excludedIds: myShowIds),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(l10n.suggestByGenre, style: AppTextStyles.title),
              ),
            ),
            if (selected.value?.isEmpty ?? false)
              SliverToBoxAdapter(
                child: EmptyState(
                  key: const Key('suggest.pickGenre'),
                  message: l10n.suggestPickGenre,
                  icon: Icons.category_outlined,
                ),
              )
            else
              _SuggestionsGrid(excludedIds: myShowIds),
          ],
        ),
      ),
    );
  }
}

class _GenreChips extends ConsumerWidget {
  const _GenreChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedGenresProvider).value ?? const <int>{};
    return ref
        .watch(genresProvider)
        .when(
          data: (genres) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final genre in genres)
                  FilterChip(
                    key: Key('genre.${genre.id}'),
                    label: Text(
                      genreLabel(
                        id: genre.id,
                        cachedName: genre.name,
                        english: AppLocale.isEnglish,
                      ),
                    ),
                    selected: selected.contains(genre.id),
                    selectedColor: AppColors.accent,
                    checkmarkColor: AppColors.onAccent,
                    labelStyle: TextStyle(
                      color: selected.contains(genre.id)
                          ? AppColors.onAccent
                          : AppColors.textPrimary,
                    ),
                    onSelected: (_) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final accepted = await ref
                          .read(selectedGenresProvider.notifier)
                          .toggle(genre.id);
                      if (!accepted) {
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l10n.suggestMaxGenres)),
                          );
                      }
                    },
                  ),
              ],
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(genresProvider),
          ),
        );
  }
}

class _SimilarSection extends ConsumerWidget {
  const _SimilarSection({required this.excludedIds});

  final Set<int> excludedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final similar = ref.watch(similarShowsProvider).value;
    // F18(f): hiç bölüm izlenmemişse (veya öneri yoksa) bölüm gösterilmez.
    if (similar == null) return const SliverToBoxAdapter();
    final shows = withoutShows(similar.shows, excludedIds);
    if (shows.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.suggestSimilarTitle(similar.source.name),
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.posterRowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: shows.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _SuggestionPoster(show: shows[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsGrid extends ConsumerWidget {
  const _SuggestionsGrid({required this.excludedIds});

  final Set<int> excludedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(suggestionsProvider)
        .when(
          data: (state) {
            final shows = withoutShows(state.shows, excludedIds);
            if (shows.isEmpty && !state.hasMore) {
              return SliverToBoxAdapter(
                child: EmptyState(message: l10n.suggestEmpty),
              );
            }
            return SliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppSpacing.posterGridColumns,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: AppSpacing.posterAspectRatio,
                        ),
                    itemCount: shows.length,
                    itemBuilder: (context, index) =>
                        _SuggestionPoster(show: shows[index]),
                  ),
                ),
                if (state.loadingMore)
                  const SliverPadding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: ErrorView(
              error: error,
              onRetry: () => ref.invalidate(suggestionsProvider),
            ),
          ),
        );
  }
}

/// Afiş + "+" kısayolu (F18e). Afişe dokunmak dizi detayını açar.
class _SuggestionPoster extends ConsumerWidget {
  const _SuggestionPoster({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        PosterCard(
          title: show.name,
          posterPath: show.posterPath,
          onTap: () => context.push(AppRoutes.showDetail(show.id)),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: IconButton.filled(
            key: Key('suggest.add.${show.id}'),
            tooltip: l10n.suggestAddShow(show.name),
            icon: const Icon(Icons.add),
            onPressed: () async {
              if (ref.read(isGuestProvider)) return showGuestGate(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(myShowsProvider.notifier).add(show);
              } catch (_) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.saveFailed)),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
