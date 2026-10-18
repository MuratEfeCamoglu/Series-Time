import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';
import '../../../core/app_locale.dart';
import '../../../core/format.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../badges/widgets/badge_showcase.dart';
import '../../shows/logic.dart';
import '../../shows/providers.dart';
import '../../social/providers.dart';
import '../../social/widgets/follow_button.dart';
import '../../tracking/data/models.dart';
import '../../tracking/logic.dart';
import '../../tracking/providers.dart';
import '../../tracking/widgets/show_progress_grid.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import 'profile_actions_menu.dart';
import 'profile_avatar.dart';
import 'social_link_button.dart';

/// F8 profil düzeni. Başka kullanıcının profili de (F12) bu düzeni kullanır; o zaman
/// Ayarlar yerine "Takip et" ve şikayet/engelle menüsü gelir.
/// Sıra (F8e): başlık → biyografi/bağlantılar → Favoriler → Şu an izlediklerim →
/// Son etkinlik → Dizilerim → istatistikler ve sayılar.
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key, required this.profile, required this.isMe});

  final Profile profile;
  final bool isMe;

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  ShowStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = widget.profile;
    final isMe = widget.isMe;
    final userShows = isMe
        ? ref.watch(myShowsProvider)
        : ref.watch(userShowsProvider(profile.id));
    final cover = tmdbImageUrl(
      profileCoverPath(profile, sortByLastWatched(userShows.value ?? const [])),
      TmdbImageSize.w780,
    );
    final avatarPath = profile.avatarPath;
    final progress =
        (isMe
                ? ref.watch(myShowProgressProvider)
                : ref.watch(showProgressProvider(profile.id)))
            .value ??
        const <ShowProgress>[];
    final favorites = favoriteShows(progress);
    final watching = currentlyWatching(progress);
    final recent =
        ref.watch(recentActivityProvider(profile.id)).value ??
        const <RecentEpisode>[];
    final filtered = filterByStatus(progress, _filter);
    final ratings =
        ref.watch(ratingDistributionProvider(profile.id)).value ??
        const <RatingCount>[];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: AppSpacing.profileHeaderHeight,
          actions: [
            if (isMe) ...[
              _ShareButton(username: profile.username),
              // Profili düzenleme yalnızca Ayarlar'dan açılır (kullanıcı kararı 2026-10-18).
              IconButton(
                key: const Key('profile.settings'),
                tooltip: l10n.settingsTitle,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ] else ...[
              FollowButton(userId: profile.id),
              _ShareButton(username: profile.username),
              ProfileActionsMenu(profile: profile),
            ],
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _HeaderBackground(
              profile: profile,
              coverUrl: cover,
              avatarUrl: avatarPath == null
                  ? null
                  : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(child: _Bio(profile: profile)),
        ),
        // F8(e): istatistikler avatarın altında, Favorilerin üstünde.
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _Stats(userId: profile.id)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: _Counts(profile: profile, isMe: isMe),
          ),
        ),
        // F14: seçilen rozetler istatistiklerin altında (kullanıcı kararı 2026-10-18).
        SliverToBoxAdapter(
          child: BadgeShowcase(
            userId: profile.id,
            username: profile.username,
            isMe: isMe,
          ),
        ),
        if (favorites.isNotEmpty || isMe) ...[
          SliverToBoxAdapter(
            child: SectionHeader(title: l10n.profileFavorites),
          ),
          SliverToBoxAdapter(
            child: favorites.isEmpty
                ? _Hint(l10n.profileFavoritesHint)
                : _Favorites(shows: favorites),
          ),
        ],
        if (watching.isNotEmpty || isMe) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: l10n.profileWatching,
              actionLabel: l10n.profileSeeAll,
              actionKey: const Key('profile.seeAll'),
              onAction: () => context.push(
                AppRoutes.userShows(
                  profile.username,
                  status: ShowStatus.watching.name,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: watching.isEmpty
                ? _Hint(l10n.profileWatchingEmpty)
                : ShowProgressRow(
                    shows: watching,
                    height: AppSpacing.profilePosterRowHeight,
                    heroScope: 'watching',
                  ),
          ),
        ],
        if (recent.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(title: l10n.profileRecentActivity),
          ),
          SliverToBoxAdapter(child: _RecentActivity(episodes: recent)),
        ],
        if (ratings.isNotEmpty || isMe) ...[
          SliverToBoxAdapter(child: SectionHeader(title: l10n.profileRatings)),
          SliverToBoxAdapter(
            child: ratings.isEmpty
                ? _Hint(l10n.profileRatingsEmpty)
                : _RatingsChart(counts: ratings),
          ),
        ],
        SliverToBoxAdapter(child: SectionHeader(title: l10n.profileMyShows)),
        if (progress.isEmpty)
          SliverToBoxAdapter(child: _Hint(l10n.profileNoShows))
        else ...[
          SliverToBoxAdapter(
            child: StatusFilterChips(
              selected: _filter,
              onSelected: (status) => setState(() => _filter = status),
            ),
          ),
          if (filtered.isEmpty)
            SliverToBoxAdapter(child: _Hint(l10n.statusFilterEmpty))
          else
            SliverShowProgressGrid(
              shows: filtered,
              columns: AppSpacing.profileGridColumns,
              heroScope: 'myShows',
            ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }
}

/// F8(a, c): soluk kapak üstünde solda avatar; sağında ad, bayrak, kullanıcı adı, kayıt tarihi
/// ve takipçi sayısı.
class _HeaderBackground extends ConsumerWidget {
  const _HeaderBackground({
    required this.profile,
    required this.coverUrl,
    required this.avatarUrl,
  });

  final Profile profile;
  final String? coverUrl;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final url = coverUrl;
    final country = profile.countryCode;
    final followers = ref
        .watch(profileCountsProvider(profile.id))
        .value
        ?.followers;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url == null)
          ColoredBox(color: AppColors.surface)
        else
          CachedNetworkImage(
            key: const Key('profile.cover'),
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => ColoredBox(color: AppColors.surface),
          ),
        // Kapak net görünür; yalnızca üstte simgeler, altta yazılar okunsun diye kararır
        // (kullanıcı kararı 2026-10-18).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.coverScrim,
                AppColors.scrimClear,
                AppColors.scrimClear,
                AppColors.background,
              ],
              stops: const [0, 0.25, 0.5, 1],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: AppSpacing.profileNameMaxTextScale,
            child: Row(
              children: [
                ProfileAvatar(
                  key: const Key('profile.avatar'),
                  url: avatarUrl,
                  size: AppSpacing.profileAvatarSize,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.displayName,
                              style: AppTextStyles.profileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (country != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              countryFlag(country),
                              style: AppTextStyles.profileName,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@${profile.username}',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.profileSince(formatLongDate(profile.createdAt)),
                        style: AppTextStyles.caption,
                      ),
                      InkWell(
                        key: const Key('profile.headerFollowers'),
                        onTap: () =>
                            context.push(AppRoutes.followers(profile.username)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group,
                                size: AppSpacing.md,
                                color: AppColors.accent,
                                semanticLabel: l10n.statFollowers,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                followers == null ? '–' : '$followers',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: const Key('profile.share'),
      tooltip: l10n.profileShare,
      icon: const Icon(Icons.ios_share),
      onPressed: () => SharePlus.instance.share(
        ShareParams(
          // F8(g): derin bağlantı; uygulamada açılması app_links onayını bekliyor.
          text: l10n.profileShareText('sezonluk://user/$username'),
        ),
      ),
    );
  }
}

class _Bio extends StatelessWidget {
  const _Bio({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(profile.bio, style: AppTextStyles.body),
          ),
        _Links(profile: profile),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}

/// F8(j): en fazla 4 favori, eşit sütunlarda.
class _Favorites extends StatelessWidget {
  const _Favorites({required this.shows});

  final List<ShowProgress> shows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < maxFavorites; i++)
            Expanded(
              child: i < shows.length
                  ? AspectRatio(
                      aspectRatio: AppSpacing.posterAspectRatio,
                      child: PosterCard(
                        key: Key('profile.favorite.${shows[i].showId}'),
                        title: shows[i].name,
                        posterPath: shows[i].posterPath,
                        heroTag: 'favorite-${shows[i].showId}',
                        onTap: () => context.push(
                          AppRoutes.showDetail(shows[i].showId),
                          extra: 'favorite-${shows[i].showId}',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// F8(k): son izlenen bölümler, bölümün sahne görseliyle; dokununca Bölüm Sonrası ekranı.
class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.episodes});

  final List<RecentEpisode> episodes;

  @override
  Widget build(BuildContext context) {
    const imageHeight =
        AppSpacing.recentStillWidth / AppSpacing.stillAspectRatio;
    return SizedBox(
      height: imageHeight + AppSpacing.xs + AppSpacing.xl + AppSpacing.md,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: episodes.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          final still = episode.stillPath ?? episode.backdropPath;
          final url = still == null
              ? tmdbImageUrl(episode.posterPath, TmdbImageSize.w342)
              : tmdbImageUrl(still, TmdbImageSize.w300);
          return SizedBox(
            key: Key('profile.recent.${episode.episodeId}'),
            width: AppSpacing.recentStillWidth,
            child: InkWell(
              onTap: () => context.push(AppRoutes.episode(episode.episodeId)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.posterRadius,
                    ),
                    child: SizedBox(
                      height: imageHeight,
                      width: AppSpacing.recentStillWidth,
                      child: url == null
                          ? ColoredBox(color: AppColors.surfaceAlt)
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  ColoredBox(color: AppColors.surfaceAlt),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    episodeLabel(episode.seasonNumber, episode.episodeNumber),
                    style: AppTextStyles.body,
                    maxLines: 1,
                  ),
                  Text(
                    episode.showName,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Links extends StatelessWidget {
  const _Links({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final letterboxd = profile.letterboxdUsername;
    final instagram = profile.instagramUsername;
    if (letterboxd == null && instagram == null) return const SizedBox.shrink();
    // F8(i): yalnızca logolu simgeler; bağlantı metni gösterilmez (kullanıcı kararı 2026-10-18).
    return Row(
      children: [
        if (letterboxd != null)
          SocialLinkButton(
            key: const Key('profile.letterboxd'),
            platform: SocialPlatform.letterboxd,
            username: letterboxd,
            url: letterboxdUrl(letterboxd),
          ),
        if (instagram != null)
          SocialLinkButton(
            key: const Key('profile.instagram'),
            platform: SocialPlatform.instagram,
            username: instagram,
            url: instagramUrl(instagram),
          ),
      ],
    );
  }
}

/// F8(l): verilen puanların 0,5–5 arası 10 sütunlu dağılımı; en yüksek sütun tam boy.
class _RatingsChart extends StatelessWidget {
  const _RatingsChart({required this.counts});

  final List<RatingCount> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final histogram = ratingHistogram(counts);
    final highest = histogram.fold(
      0,
      (max, b) => b.count > max ? b.count : max,
    );
    final average = averageRating(counts)!;
    String label(double rating) => rating == rating.roundToDouble()
        ? '${rating.toInt()}'
        : AppLocale.decimal(rating);
    return Padding(
      key: const Key('profile.ratings'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileRatingsSummary(
              totalRatings(counts),
              AppLocale.decimal(average),
            ),
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.ratingChartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in histogram)
                  Expanded(
                    child: Semantics(
                      label: l10n.ratingBarLabel(label(bar.rating), bar.count),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.ratingBarGap / 2,
                        ),
                        // Sütunlar ilk görünüşte tabandan yükselir.
                        child: TweenAnimationBuilder<double>(
                          // Boş sütun da ince bir çizgi olarak görünsün.
                          tween: Tween(
                            begin: 0,
                            end: bar.count == 0
                                ? AppSpacing.ratingBarGap /
                                      AppSpacing.ratingChartHeight
                                : bar.count / highest,
                          ),
                          duration: motionDuration(context, AppMotion.progress),
                          curve: Curves.easeOutCubic,
                          builder: (context, factor, child) =>
                              FractionallySizedBox(
                                key: Key('profile.ratingBar.${bar.rating}'),
                                alignment: Alignment.bottomCenter,
                                heightFactor: factor,
                                child: child,
                              ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: bar.count == 0
                                  ? AppColors.border
                                  : AppColors.accent,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppSpacing.ratingBarGap),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final bar in histogram)
                  Expanded(
                    child: Text(
                      bar.rating == bar.rating.roundToDouble()
                          ? label(bar.rating)
                          : '',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// F8(f): takipçi, takip edilen ve rozet sayıları; dokununca ilgili liste açılır.
class _Counts extends ConsumerWidget {
  const _Counts({required this.profile, required this.isMe});

  final Profile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final counts = ref.watch(profileCountsProvider(profile.id)).value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Count(
          key: const Key('profile.followers'),
          value: counts?.followers,
          label: l10n.statFollowers,
          onTap: () => context.push(AppRoutes.followers(profile.username)),
        ),
        _Count(
          key: const Key('profile.following'),
          value: counts?.following,
          label: l10n.statFollowing,
          onTap: () => context.push(AppRoutes.following(profile.username)),
        ),
        _Count(
          key: const Key('profile.badges'),
          value: counts?.badges,
          label: l10n.statBadges,
          onTap: () =>
              context.push(AppRoutes.badges(isMe ? null : profile.username)),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    super.key,
    required this.value,
    required this.label,
    required this.onTap,
  });

  /// null: yükleniyor.
  final int? value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTapTarget * 2,
          minHeight: AppSpacing.minTapTarget,
        ),
        child: Column(
          children: [
            Text(value == null ? '–' : '$value', style: AppTextStyles.title),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(userStatsProvider(userId)).value;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: EntranceAnimation(
              index: 0,
              child: _StatCard(
                key: const Key('profile.watchTime'),
                icon: Icons.schedule,
                title: l10n.statWatchTimeTitle,
                value: value?.watchMinutes,
                semanticsLabel: (minutes) {
                  final time = splitWatchTime(minutes);
                  return l10n.statWatchTimeValue(
                    time.months,
                    time.days,
                    time.hours,
                  );
                },
                builder: (minutes) {
                  final time = splitWatchTime(minutes);
                  return Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      _StatNumber(value: time.months, unit: l10n.unitMonths),
                      _StatNumber(value: time.days, unit: l10n.unitDays),
                      _StatNumber(value: time.hours, unit: l10n.unitHours),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: EntranceAnimation(
              index: 1,
              child: _StatCard(
                key: const Key('profile.episodes'),
                icon: Icons.play_circle_outline,
                title: l10n.statEpisodesTitle,
                value: value?.watchedEpisodes,
                semanticsLabel: (count) => '$count',
                builder: (count) =>
                    _StatNumber(value: count, unit: l10n.unitEpisodes),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// F8(d) istatistik kartı: paletin vurgu rengine göre renk geçişli zemin, ikon ve
/// sıfırdan sayarak gelen değer (kullanıcı kararı 2026-10-18).
class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.builder,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String title;

  /// null: yükleniyor.
  final int? value;
  final Widget Function(int value) builder;

  /// Ekran okuyucu tam değeri tek seferde okusun diye.
  final String Function(int value) semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final target = value;
    final accent = AppColors.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.statCardRadius),
        border: Border.all(
          color: accent.withValues(alpha: AppColors.statBorderAlpha),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: AppColors.statGlowAlpha),
            AppColors.surface,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: AppColors.statGlowAlpha),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      icon,
                      size: AppSpacing.statIconSize,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title, style: AppTextStyles.caption, maxLines: 2),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (target == null)
              const LinearProgressIndicator()
            else
              Semantics(
                label: semanticsLabel(target),
                excludeSemantics: true,
                child: CountUp(
                  value: target,
                  builder: (context, current) => builder(current),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Büyük vurgu renkli sayı ve yanında küçük birim ("12 gün").
class _StatNumber extends StatelessWidget {
  const _StatNumber({required this.value, required this.unit});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$value',
            style: AppTextStyles.statNumber.copyWith(color: AppColors.accent),
          ),
          TextSpan(text: ' $unit', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
