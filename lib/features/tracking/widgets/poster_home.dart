import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../shows/logic.dart';
import '../../social/data/models.dart';
import '../../social/providers.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import 'status_sheet.dart';
import 'watchlist_tile.dart';

/// F6(k) Afiş görünümü: üstte büyük görsel, bölümlere kaydıran çipler ve yatay afiş satırları.
class PosterHome extends ConsumerStatefulWidget {
  const PosterHome({super.key});

  @override
  ConsumerState<PosterHome> createState() => _PosterHomeState();
}

class _Section {
  _Section(this.id, this.title, this.child);

  final String id;
  final String title;
  final Widget child;
  final key = GlobalKey();
}

class _PosterHomeState extends ConsumerState<PosterHome> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final watchlist = ref.watch(watchlistProvider).value ?? const [];
    final split = splitWatchlist(watchlist, now);
    final upcoming = nextUpcomingPerShow(
      ref.watch(upcomingProvider).value ?? const [],
    );
    final recent = recentlyWatchedShows(
      ref.watch(myShowProgressProvider).value ?? const [],
    );
    final friends = ref.watch(friendsActivityProvider).value ?? const [];

    final sections = [
      if (upcoming.isNotEmpty)
        _Section(
          'upcoming',
          l10n.tabUpcoming,
          _Row(
            itemCount: upcoming.length,
            builder: (index) => _UpcomingPoster(episode: upcoming[index]),
          ),
        ),
      for (final (id, title, items) in [
        ('continue', l10n.watchlistUpNext, split.upNext),
        ('notStarted', l10n.watchlistNotStarted, split.notStarted),
        ('notRecently', l10n.watchlistNotRecently, split.notRecently),
      ])
        if (items.isNotEmpty)
          _Section(
            id,
            title,
            _Row(
              itemCount: items.length,
              builder: (index) => _NextPoster(item: items[index]),
            ),
          ),
      if (recent.isNotEmpty)
        _Section(
          'recent',
          l10n.recentShowsTitle,
          _Row(
            itemCount: recent.length,
            builder: (index) => _BadgedPoster(
              key: ValueKey('home.recent.${recent[index].showId}'),
              title: recent[index].name,
              posterPath: recent[index].posterPath,
              onTap: () =>
                  context.push(AppRoutes.showDetail(recent[index].showId)),
            ),
          ),
        ),
      if (friends.isNotEmpty)
        _Section(
          'friends',
          l10n.friendsActivityTitle,
          _Row(
            itemCount: friends.length,
            extraHeight: AppSpacing.xl + AppSpacing.md,
            builder: (index) => _FriendPoster(activity: friends[index]),
          ),
        ),
    ];

    final featured = split.upNext.firstOrNull ?? split.notRecently.firstOrNull;
    final heroShowId = featured?.showId ?? recent.firstOrNull?.showId;
    final heroBackdrop =
        featured?.backdropPath ?? recent.firstOrNull?.backdropPath;
    final heroName = featured?.name ?? recent.firstOrNull?.name;

    return CustomScrollView(
      // Çiplerle uzak bölüme kaydırılabilsin diye bölümler önceden oluşturulur.
      scrollCacheExtent: const ScrollCacheExtent.viewport(
        AppSpacing.homeCacheViewports,
      ),
      slivers: [
        if (heroShowId != null)
          SliverToBoxAdapter(
            child: _Hero(
              showId: heroShowId,
              name: heroName!,
              backdropPath: heroBackdrop,
            ),
          ),
        if (sections.length > 1)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  for (final section in sections)
                    ActionChip(
                      key: Key('home.chip.${section.id}'),
                      label: Text(section.title),
                      onPressed: () {
                        final target = section.key.currentContext;
                        if (target != null) {
                          Scrollable.ensureVisible(
                            target,
                            duration: kThemeAnimationDuration,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        if (sections.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.watchlistAllCaughtUp,
                style: AppTextStyles.bodySecondary,
              ),
            ),
          ),
        for (final section in sections)
          SliverToBoxAdapter(
            child: Column(
              key: section.key,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(title: section.title),
                section.child,
              ],
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.lg)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.showId,
    required this.name,
    required this.backdropPath,
  });

  final int showId;
  final String name;
  final String? backdropPath;

  @override
  Widget build(BuildContext context) {
    final url = tmdbImageUrl(backdropPath, TmdbImageSize.w780);
    return SizedBox(
      key: const Key('home.hero'),
      height: AppSpacing.homeHeroHeight,
      child: InkWell(
        onTap: () => context.push(AppRoutes.showDetail(showId)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              ColoredBox(color: AppColors.surface)
            else
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => ColoredBox(color: AppColors.surface),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.scrimClear, AppColors.background],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
              child: Text(
                name,
                style: AppTextStyles.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yatay afiş satırı; [extraHeight] afiş altındaki satırlar içindir.
class _Row extends StatelessWidget {
  const _Row({
    required this.itemCount,
    required this.builder,
    this.extraHeight = AppSpacing.lg,
  });

  final int itemCount;
  final Widget Function(int index) builder;
  final double extraHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          AppSpacing.homePosterWidth / AppSpacing.posterAspectRatio +
          AppSpacing.xs +
          extraHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => builder(index),
      ),
    );
  }
}

/// Köşesinde bölüm etiketi olan afiş; altında isteğe bağlı satırlar.
class _BadgedPoster extends StatelessWidget {
  const _BadgedPoster({
    super.key,
    required this.title,
    required this.posterPath,
    required this.onTap,
    this.badge,
    this.onLongPress,
    this.overlay,
    this.below = const [],
  });

  final String title;
  final String? posterPath;
  final VoidCallback onTap;
  final String? badge;
  final VoidCallback? onLongPress;
  final Widget? overlay;
  final List<Widget> below;

  @override
  Widget build(BuildContext context) {
    final label = badge;
    return SizedBox(
      width: AppSpacing.homePosterWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: AspectRatio(
              aspectRatio: AppSpacing.posterAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PosterCard(
                    title: title,
                    posterPath: posterPath,
                    onTap: onTap,
                  ),
                  if (label != null)
                    Positioned(
                      right: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Text(
                            label,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.onAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ?overlay,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...below,
        ],
      ),
    );
  }
}

class _UpcomingPoster extends StatelessWidget {
  const _UpcomingPoster({required this.episode});

  final UpcomingEpisode episode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = switch (upcomingDayKind(episode.airDate, DateTime.now())) {
      UpcomingDay.today => l10n.upcomingToday,
      UpcomingDay.tomorrow => l10n.upcomingTomorrow,
      UpcomingDay.later => formatShortDayMonthWeekday(episode.airDate),
    };
    return _BadgedPoster(
      key: ValueKey('home.upcoming.${episode.episodeId}'),
      title: episode.showName,
      posterPath: episode.posterPath,
      badge: episodeCode(episode.seasonNumber, episode.episodeNumber),
      onTap: () => context.push(AppRoutes.showDetail(episode.showId)),
      below: [Text(date, style: AppTextStyles.bodySecondary, maxLines: 1)],
    );
  }
}

/// İzlemeye devam et: köşede tek dokunuşla işaretleme (F5), uzun basınca durum menüsü (F6j).
class _NextPoster extends ConsumerWidget {
  const _NextPoster({required this.item});

  final WatchlistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = episodeCode(item.nextSeasonNumber, item.nextEpisodeNumber);
    return _BadgedPoster(
      key: ValueKey('home.next.${item.showId}'),
      title: item.name,
      posterPath: item.posterPath,
      badge: code,
      onTap: () => context.push(AppRoutes.showDetail(item.showId)),
      onLongPress: () => showStatusSheet(
        context,
        ref,
        showId: item.showId,
        manual: item.manualStatus,
        auto: autoShowStatus(
          tmdbStatus: item.showStatus,
          airedCount: item.airedCount,
          watchedCount: item.watchedCount,
        ),
      ),
      overlay: Positioned(
        top: 0,
        right: 0,
        child: NextEpisodeCheck(item: item, code: code),
      ),
    );
  }
}

/// Arkadaşın son izlediği bölüm: afiş, avatar, kullanıcı adı ve verdiği puan.
class _FriendPoster extends ConsumerWidget {
  const _FriendPoster({required this.activity});

  final FriendActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final avatar = activity.avatarPath;
    final rating = activity.rating;
    return _BadgedPoster(
      key: ValueKey('home.friend.${activity.userId}'),
      title: activity.showName,
      posterPath: activity.posterPath,
      badge: episodeCode(activity.seasonNumber, activity.episodeNumber),
      onTap: () => context.push(AppRoutes.episode(activity.episodeId)),
      below: [
        InkWell(
          onTap: () => context.push(AppRoutes.userProfile(activity.username)),
          child: Row(
            children: [
              ProfileAvatar(
                size: AppSpacing.lg,
                url: avatar == null
                    ? null
                    : ref.read(profileRepositoryProvider).avatarUrl(avatar),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  activity.username,
                  style: AppTextStyles.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (rating != null)
          Semantics(
            label: l10n.friendRating(rating.toString()),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      rating >= i
                          ? Icons.star
                          : rating >= i - 0.5
                          ? Icons.star_half
                          : Icons.star_border,
                      size: AppSpacing.friendStarSize,
                      color: AppColors.accent,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
