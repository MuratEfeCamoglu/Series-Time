import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';
import 'badge_medal.dart';
import 'badge_texts.dart';

/// Profildeki "Rozet vitrini" (F14): kullanıcının seçtiği en fazla 6 rozet, 6 eşit sütunda.
/// Kendi profilinde boşsa ipucu, başkasının profilinde boşsa bölüm gizli. Dokununca rozet ekranı.
class BadgeShowcase extends ConsumerWidget {
  const BadgeShowcase({
    super.key,
    required this.userId,
    required this.username,
    required this.isMe,
  });

  final String userId;
  final String username;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final featured =
        ref.watch(featuredBadgesProvider(userId)).value ??
        const <FeaturedBadge>[];
    if (featured.isEmpty && !isMe) return const SizedBox.shrink();
    final definitions = {
      for (final b in ref.watch(badgesProvider).value ?? const <BadgeInfo>[])
        b.code: b,
    };
    void open() =>
        context.push(isMe ? AppRoutes.badges() : AppRoutes.badges(username));

    return Column(
      key: const Key('profile.showcase'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.profileShowcase),
        if (featured.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: InkWell(
              onTap: open,
              child: Text(
                l10n.profileShowcaseHint,
                style: AppTextStyles.bodySecondary,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: InkWell(
              onTap: open,
              child: Row(
                children: [
                  for (var i = 0; i < maxFeaturedBadges; i++)
                    Expanded(
                      child: i < featured.length
                          ? EntranceAnimation(
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: FittedBox(
                                    child: _medal(
                                      l10n,
                                      featured[i],
                                      definitions,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _medal(
    AppLocalizations l10n,
    FeaturedBadge badge,
    Map<String, BadgeInfo> definitions,
  ) {
    final code = badge.badgeCode;
    if (code == null) {
      final season = badge.seasonNumber ?? 0;
      return ShowBadgeMedal(
        key: Key('showcase.show.${badge.showId}.$season'),
        posterPath: badge.posterPath,
        seasonNumber: season,
        label: showBadgeTitle(l10n, badge.showName ?? '', season),
      );
    }
    final info =
        definitions[code] ??
        BadgeInfo(code: code, name: code, description: '', icon: code);
    return GeneralBadgeMedal(
      key: Key('showcase.badge.$code'),
      badge: info,
      earned: true,
      label: badgeTitle(l10n, code, info.name),
    );
  }
}
