import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/poster_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/data/models.dart';
import '../../notifications/logic.dart';
import '../../notifications/providers.dart';
import '../../shows/providers.dart';
import '../../social/providers.dart';
import '../../social/widgets/follow_button.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import 'profile_actions_menu.dart';
import 'profile_avatar.dart';

/// F8 profil düzeni. Başka kullanıcının profili de (F12) bu düzeni kullanır; o zaman
/// "Düzenle" yerine "Takip et", zil yerine şikayet/engelle menüsü gelir.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key, required this.profile, required this.isMe});

  final Profile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shows = isMe
        ? ref.watch(myShowsProvider)
        : ref.watch(userShowsProvider(profile.id));
    final sortedShows = sortByLastWatched(shows.value ?? const []);
    final cover = tmdbImageUrl(
      profileCoverPath(profile, sortedShows),
      TmdbImageSize.w780,
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: AppSpacing.profileCoverHeight,
          actions: [
            if (isMe) ...[
              const _NotificationBell(),
              IconButton(
                tooltip: l10n.settingsTitle,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ] else
              ProfileActionsMenu(profile: profile),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: cover == null
                ? const ColoredBox(color: AppColors.surface)
                : CachedNetworkImage(
                    key: const Key('profile.cover'),
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        const ColoredBox(color: AppColors.surface),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: _Header(profile: profile, isMe: isMe),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(child: _Stats(userId: profile.id)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.profileMyShows, style: AppTextStyles.title),
                ),
                TextButton(
                  key: const Key('profile.seeAll'),
                  onPressed: () =>
                      context.push(AppRoutes.userShows(profile.username)),
                  child: Text(l10n.profileSeeAll),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _ShowsRow(shows: sortedShows)),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }
}

/// F8(b): sarı zil ve okunmamış bildirim sayısı (F13).
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return IconButton(
      key: const Key('profile.bell'),
      tooltip: AppLocalizations.of(context).profileNotifications,
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        label: Text(unreadBadgeLabel(unread)),
        isLabelVisible: unread > 0,
        child: const Icon(Icons.notifications, color: AppColors.accent),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.profile, required this.isMe});

  final Profile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final avatarPath = profile.avatarPath;
    final country = profile.countryCode;
    return Column(
      children: [
        ProfileAvatar(
          url: avatarPath == null
              ? null
              : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (country != null)
          Text(countryFlag(country), style: AppTextStyles.title),
        Text(
          profile.displayName,
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('@${profile.username}', style: AppTextStyles.bodySecondary),
            IconButton(
              key: const Key('profile.share'),
              tooltip: l10n.profileShare,
              icon: const Icon(Icons.ios_share),
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  // F8(g): derin bağlantı; uygulamada açılması Aşama 6'da (F12) bağlanır.
                  text: l10n.profileShareText(
                    'sezonluk://user/${profile.username}',
                  ),
                ),
              ),
            ),
          ],
        ),
        if (profile.bio.isNotEmpty) ...[
          Text(
            profile.bio,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (isMe)
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            child: Text(l10n.profileEdit),
          )
        else
          FollowButton(userId: profile.id),
        const SizedBox(height: AppSpacing.md),
        _Counts(profile: profile, isMe: isMe),
      ],
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
    final stats = ref.watch(userStatsProvider(userId));
    final value = stats.value;
    final time = value == null ? null : splitWatchTime(value.watchMinutes);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            key: const Key('profile.watchTime'),
            title: l10n.statWatchTimeTitle,
            value: time == null
                ? null
                : l10n.statWatchTimeValue(time.months, time.days, time.hours),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            key: const Key('profile.episodes'),
            title: l10n.statEpisodesTitle,
            value: value?.watchedEpisodes.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({super.key, required this.title, required this.value});

  final String title;

  /// null: yükleniyor.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value;
    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            if (text == null)
              const LinearProgressIndicator()
            else
              Text(text, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}

class _ShowsRow extends StatelessWidget {
  const _ShowsRow({required this.shows});

  final List<UserShow> shows;

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(
          AppLocalizations.of(context).profileNoShows,
          style: AppTextStyles.bodySecondary,
        ),
      );
    }
    return SizedBox(
      height: AppSpacing.posterRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: shows.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final show = shows[index].show;
          return PosterCard(
            title: show.name,
            posterPath: show.posterPath,
            onTap: () => context.push(AppRoutes.showDetail(show.id)),
          );
        },
      ),
    );
  }
}
