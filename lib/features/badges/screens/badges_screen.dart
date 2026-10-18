import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers.dart';
import '../../profile/providers.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/badge_medal.dart';
import '../widgets/badge_texts.dart';

/// `/badges` (F14): dizi/sezon rozetleri, tür rozetleri ve genel rozetler; kazanılanlar
/// renkli, kazanılmayanlar gri ve koşuluyla. Oturum sahibi kazandığı rozete dokunarak
/// profil vitrinine ekler/çıkarır (en fazla 6).
/// [username] verilirse o kullanıcının rafı, yoksa oturum sahibininki.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = username;
    final myId = ref.read(authRepositoryProvider).currentUserId;
    final userId = name == null
        ? AsyncValue.data(myId)
        : ref.watch(profileByUsernameProvider(name)).whenData((p) => p.id);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgesTitle)),
      body: switch (userId) {
        AsyncData(:final value?) => _Shelf(userId: value, isMe: value == myId),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileByUsernameProvider(name!)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Shelf extends ConsumerWidget {
  const _Shelf({required this.userId, required this.isMe});

  final String userId;
  final bool isMe;

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    BadgeRef badge, {
    String? showName,
    String? posterPath,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final added = await ref
          .read(featuredBadgesProvider(userId).notifier)
          .toggle(badge, showName: showName, posterPath: posterPath);
      if (!added) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.badgesShowcaseFull)));
      }
    } catch (error) {
      // Hata kullanıcıya genel iletiyle gösterilir; ayrıntı günlüğe yazılır.
      debugPrint('Vitrin kaydedilemedi: $error');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failureMessage(l10n, error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final featured = {
      for (final f
          in ref.watch(featuredBadgesProvider(userId)).value ??
              const <FeaturedBadge>[])
        BadgeRef.fromFeatured(f),
    };
    return ref
        .watch(badgeShelfProvider(userId))
        .when(
          data: (rack) => CustomScrollView(
            slivers: [
              if (isMe)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.badgesShowcaseHint(featured.length),
                      key: const Key('badges.showcaseHint'),
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: '${l10n.badgesShowSection} (${rack.shows.length})',
                ),
              ),
              if (rack.shows.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.badgesShowEmpty,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppSpacing.medalGridColumns,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: AppSpacing.medalTileAspectRatio,
                        ),
                    itemCount: rack.shows.length,
                    itemBuilder: (context, index) {
                      final badge = rack.shows[index];
                      final key = BadgeRef.show(
                        badge.showId,
                        badge.seasonNumber,
                      );
                      final title = showBadgeTitle(
                        l10n,
                        badge.showName,
                        badge.seasonNumber,
                      );
                      return EntranceAnimation(
                        index: index,
                        child: _MedalTile(
                          key: Key(
                            'showBadge.${badge.showId}.${badge.seasonNumber}',
                          ),
                          medal: ShowBadgeMedal(
                            posterPath: badge.posterPath,
                            seasonNumber: badge.seasonNumber,
                            label: title,
                          ),
                          title: title,
                          showcased: featured.contains(key),
                          onTap: isMe
                              ? () => _toggle(
                                  context,
                                  ref,
                                  key,
                                  showName: badge.showName,
                                  posterPath: badge.posterPath,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: SectionHeader(title: l10n.badgesGenreSection),
              ),
              SliverList.builder(
                itemCount: rack.genres.length,
                itemBuilder: (context, index) {
                  final group = rack.genres[index];
                  return _GenreRow(
                    genreId: group.genreId,
                    tiers: group.tiers,
                    featured: featured,
                    onToggle: isMe
                        ? (code) =>
                              _toggle(context, ref, BadgeRef.general(code))
                        : null,
                  );
                },
              ),
              SliverToBoxAdapter(
                child: SectionHeader(title: l10n.badgesGeneralSection),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                sliver: SliverList.builder(
                  itemCount: rack.general.length,
                  itemBuilder: (context, index) {
                    final (:badge, :earnedAt) = rack.general[index];
                    final earned = earnedAt != null;
                    final ref0 = BadgeRef.general(badge.code);
                    final title = badgeTitle(l10n, badge.code, badge.name);
                    return Card(
                      key: Key('badge.${badge.code}'),
                      color: AppColors.surface,
                      child: ListTile(
                        leading: GeneralBadgeMedal(
                          badge: badge,
                          earned: earned,
                          size: AppSpacing.emptyStateIconSize,
                          label: earned ? title : l10n.badgeLocked,
                        ),
                        title: Text(
                          title,
                          style: earned
                              ? AppTextStyles.body
                              : AppTextStyles.bodySecondary,
                        ),
                        subtitle: Text(
                          earned
                              ? l10n.badgeEarnedOn(
                                  formatLongDate(earnedAt.toLocal()),
                                )
                              : badgeCondition(
                                  l10n,
                                  badge.code,
                                  badge.description,
                                ),
                          style: AppTextStyles.caption,
                        ),
                        trailing: featured.contains(ref0)
                            ? Icon(
                                Icons.push_pin,
                                color: AppColors.accent,
                                semanticLabel: l10n.badgeShowcased,
                              )
                            : null,
                        onTap: isMe && earned
                            ? () => _toggle(context, ref, ref0)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(badgeShelfProvider(userId)),
          ),
        );
  }
}

/// Bir türün 1, 5 ve 10 kademeli rozetleri yan yana.
class _GenreRow extends StatelessWidget {
  const _GenreRow({
    required this.genreId,
    required this.tiers,
    required this.featured,
    required this.onToggle,
  });

  final int genreId;
  final List<ShelfEntry> tiers;
  final Set<BadgeRef> featured;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final toggle = onToggle;
    return Padding(
      key: Key('genreBadges.$genreId'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(genreName(genreId), style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final (:badge, :earnedAt) in tiers)
                Expanded(
                  child: _MedalTile(
                    key: Key('badge.${badge.code}'),
                    medal: GeneralBadgeMedal(
                      badge: badge,
                      earned: earnedAt != null,
                      label: earnedAt != null
                          ? badgeTitle(l10n, badge.code, badge.name)
                          : l10n.badgeLocked,
                    ),
                    title: badgeTitle(l10n, badge.code, badge.name),
                    subtitle: earnedAt == null
                        ? badgeCondition(l10n, badge.code, badge.description)
                        : null,
                    showcased: featured.contains(BadgeRef.general(badge.code)),
                    onTap: toggle != null && earnedAt != null
                        ? () => toggle(badge.code)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Madalya, altında adı; vitrindeyse vurgu renkli iğne işareti. Dokununca vitrine
/// eklenir/çıkarılır (yalnızca oturum sahibinin kazandığı rozette).
class _MedalTile extends StatelessWidget {
  const _MedalTile({
    super.key,
    required this.medal,
    required this.title,
    required this.showcased,
    required this.onTap,
    this.subtitle,
  });

  final Widget medal;
  final String title;
  final String? subtitle;
  final bool showcased;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sub = subtitle;
    return PressScale(
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SelectionBounce(active: showcased, child: medal),
                  if (showcased)
                    Positioned(
                      right: -AppSpacing.xs,
                      top: -AppSpacing.xs,
                      child: Icon(
                        Icons.push_pin,
                        color: AppColors.accent,
                        size: AppSpacing.md + AppSpacing.xs,
                        semanticLabel: l10n.badgeShowcased,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sub != null)
                Text(
                  sub,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
