import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/logic.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';

/// Diziler › Yaklaşan (F7): 90 gün içindeki bölümler, tarih başlıklarıyla.
class UpcomingTab extends ConsumerWidget {
  const UpcomingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(upcomingProvider)
        .when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                message: l10n.upcomingEmpty,
                icon: Icons.event_outlined,
              );
            }
            final now = DateTime.now();
            return RefreshIndicator(
              onRefresh: () => ref.refresh(upcomingProvider.future),
              child: CustomScrollView(
                slivers: [
                  for (final group in groupUpcoming(items))
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Text(switch (upcomingDayKind(
                              group.date,
                              now,
                            )) {
                              UpcomingDay.today => l10n.upcomingToday,
                              UpcomingDay.tomorrow => l10n.upcomingTomorrow,
                              UpcomingDay.later => formatDayMonthWeekday(
                                group.date,
                              ),
                            }, style: AppTextStyles.title),
                          ),
                        ),
                        SliverList.builder(
                          itemCount: group.episodes.length,
                          itemBuilder: (context, index) =>
                              _UpcomingRow(episode: group.episodes[index]),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(upcomingProvider),
          ),
        );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.episode});

  final UpcomingEpisode episode;

  @override
  Widget build(BuildContext context) {
    final code = episodeCode(episode.seasonNumber, episode.episodeNumber);
    final name = episode.episodeName;
    return ListTile(
      leading: SizedBox(
        width: AppSpacing.posterThumbWidth,
        child: PosterCard(
          title: episode.showName,
          posterPath: episode.posterPath,
        ),
      ),
      title: Text(episode.showName, style: AppTextStyles.body),
      subtitle: Text(
        name == null || name.isEmpty ? code : '$code · $name',
        style: AppTextStyles.bodySecondary,
      ),
      onTap: () => context.push(AppRoutes.showDetail(episode.showId)),
    );
  }
}
