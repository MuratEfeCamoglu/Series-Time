import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../notifications/logic.dart';
import '../../notifications/providers.dart';
import '../../shows/providers.dart';
import '../../social/providers.dart';
import '../../social/widgets/follow_button.dart';
import '../../tracking/data/models.dart';
import '../../tracking/providers.dart';
import '../../tracking/widgets/show_progress_grid.dart';
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

    final avatarPath = profile.avatarPath;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          // Avatarın yarısı kapağın altına taşar (F8c).
          expandedHeight:
              AppSpacing.profileCoverHeight + AppSpacing.profileNameStrip,
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
            background: _CoverHeader(
              profile: profile,
              coverUrl: cover,
              avatarUrl: avatarPath == null
                  ? null
                  : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
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
        SliverToBoxAdapter(
          child: _ShowsRow(
            shows:
                (isMe
                        ? ref.watch(myShowProgressProvider)
                        : ref.watch(showProgressProvider(profile.id)))
                    .value ??
                const [],
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }
}

/// F8(a, c): kapak; solda alt kenarına taşan avatar, sağında ad, bayrak ve kullanıcı adı.
class _CoverHeader extends StatelessWidget {
  const _CoverHeader({
    required this.profile,
    required this.coverUrl,
    required this.avatarUrl,
  });

  final Profile profile;
  final String? coverUrl;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = coverUrl;
    final country = profile.countryCode;
    // Avatarın merkezi kapağın alt kenarında durur.
    const avatarBottom =
        AppSpacing.profileNameStrip -
        AppSpacing.avatarLarge / 2 -
        AppSpacing.avatarRing;
    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppSpacing.profileCoverHeight,
            child: url == null
                ? const ColoredBox(color: AppColors.surface)
                : CachedNetworkImage(
                    key: const Key('profile.cover'),
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        const ColoredBox(color: AppColors.surface),
                  ),
          ),
          Positioned(
            left: AppSpacing.md,
            bottom: avatarBottom,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.avatarRing),
                child: ProfileAvatar(
                  key: const Key('profile.avatar'),
                  url: avatarUrl,
                ),
              ),
            ),
          ),
          Positioned(
            left:
                AppSpacing.md +
                AppSpacing.avatarLarge +
                AppSpacing.avatarRing * 2 +
                AppSpacing.sm,
            right: AppSpacing.md,
            bottom: 0,
            height: AppSpacing.profileNameStrip,
            // Şerit sabit yükseklikte; çok büyük sistem yazı boyutunda taşmasın.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: AppSpacing.profileNameMaxTextScale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.displayName,
                          style: AppTextStyles.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (country != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(countryFlag(country), style: AppTextStyles.title),
                      ],
                    ],
                  ),
                  Text(
                    '@${profile.username}',
                    style: AppTextStyles.bodySecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.isMe});

  final Profile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('profile.share'),
              tooltip: l10n.profileShare,
              icon: const Icon(Icons.ios_share),
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  // F8(g): derin bağlantı; uygulamada açılması app_links onayını bekliyor.
                  text: l10n.profileShareText(
                    'sezonluk://user/${profile.username}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (isMe)
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.editProfile),
                child: Text(l10n.profileEdit),
              )
            else
              FollowButton(userId: profile.id),
          ],
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(profile.bio, style: AppTextStyles.body),
        ],
        _Links(profile: profile),
        const SizedBox(height: AppSpacing.md),
        _Counts(profile: profile, isMe: isMe),
      ],
    );
  }
}

/// F8(i): genel bağlantı simgesi ve servis adı; marka logosu kullanılmaz.
class _Links extends StatelessWidget {
  const _Links({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final letterboxd = profile.letterboxdUsername;
    final instagram = profile.instagramUsername;
    if (letterboxd == null && instagram == null) return const SizedBox.shrink();

    Widget link(Key key, String label, String url) => OutlinedButton.icon(
      key: key,
      icon: const Icon(Icons.link),
      label: Text(label),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final opened = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.errorLinkOpen)));
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (letterboxd != null)
            link(
              const Key('profile.letterboxd'),
              l10n.linkLetterboxd,
              letterboxdUrl(letterboxd),
            ),
          if (instagram != null)
            link(
              const Key('profile.instagram'),
              l10n.linkInstagram,
              instagramUrl(instagram),
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

  /// RPC sırası: son izlenen önce (F8e).
  final List<ShowProgress> shows;

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
        itemBuilder: (context, index) => SizedBox(
          width: AppSpacing.posterRowHeight * AppSpacing.posterAspectRatio,
          child: ShowProgressPoster(
            key: ValueKey(shows[index].showId),
            show: shows[index],
          ),
        ),
      ),
    );
  }
}
