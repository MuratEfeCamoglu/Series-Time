import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/logic.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';

/// Diziler sayfasının Yaklaşan bölümü (F7): ilk [upcomingPreviewCount] bölüm, "Tümünü göster"
/// ile 90 günün hepsi; tarih başlıklarıyla. Sliver olarak döner.
class UpcomingSection extends ConsumerStatefulWidget {
  const UpcomingSection({super.key});

  @override
  ConsumerState<UpcomingSection> createState() => _UpcomingSectionState();
}

class _UpcomingSectionState extends ConsumerState<UpcomingSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final header = SliverToBoxAdapter(
      child: SectionHeader(title: l10n.tabUpcoming),
    );
    return ref
        .watch(upcomingProvider)
        .when(
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
                        l10n.upcomingEmpty,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  ),
                ],
              );
            }
            final now = DateTime.now();
            final collapsible = items.length > upcomingPreviewCount;
            final visible = _expanded || !collapsible
                ? items
                : items.take(upcomingPreviewCount).toList();
            return SliverMainAxisGroup(
              slivers: [
                header,
                for (final group in groupUpcoming(visible))
                  SliverMainAxisGroup(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
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
                          }, style: AppTextStyles.bodySecondary),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: group.episodes.length,
                        itemBuilder: (context, index) =>
                            _UpcomingRow(episode: group.episodes[index]),
                      ),
                    ],
                  ),
                if (collapsible)
                  SliverToBoxAdapter(
                    child: Center(
                      child: TextButton(
                        key: const Key('upcoming.toggle'),
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          _expanded
                              ? l10n.upcomingShowLess
                              : l10n.upcomingShowAll,
                        ),
                      ),
                    ),
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
                  onRetry: () => ref.invalidate(upcomingProvider),
                ),
              ),
            ],
          ),
        );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.episode});

  final UpcomingEpisode episode;

  @override
  Widget build(BuildContext context) {
    final name = episode.episodeName;
    // Sıradaki kartıyla aynı boyut: sahne görseli, yoksa arka plan, o da yoksa afiş (F7).
    final still = episode.stillPath ?? episode.backdropPath;
    final image = still == null
        ? tmdbImageUrl(episode.posterPath, TmdbImageSize.w342)
        : tmdbImageUrl(still, TmdbImageSize.w300);
    return Card(
      key: Key('upcoming.${episode.episodeId}'),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.showDetail(episode.showId)),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.watchlistImageWidth,
              height:
                  AppSpacing.watchlistImageWidth / AppSpacing.stillAspectRatio,
              child: image == null
                  ? ColoredBox(
                      color: AppColors.surfaceAlt,
                      child: Icon(
                        Icons.movie_outlined,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          ColoredBox(color: AppColors.surfaceAlt),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.showName,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      episodeLabel(episode.seasonNumber, episode.episodeNumber),
                      style: AppTextStyles.bodySecondary,
                    ),
                    if (name != null && name.isNotEmpty)
                      Text(
                        name,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
