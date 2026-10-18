import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../logic.dart';

// Kazanılmamış rozet gri gösterilir (F14): görselin renkleri ışıklılığa indirgenir.
const _grayscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.5, 0, //
]);

/// Tür rozetinin simgesi türe uygun seçilir (TMDB tür kimliği).
IconData genreIcon(int genreId) => switch (genreId) {
  10759 => Icons.explore,
  16 => Icons.animation,
  35 => Icons.sentiment_very_satisfied,
  80 => Icons.local_police,
  99 => Icons.public,
  18 => Icons.theater_comedy,
  10751 => Icons.family_restroom,
  10762 => Icons.child_care,
  9648 => Icons.fingerprint,
  10763 => Icons.newspaper,
  10764 => Icons.videocam,
  10765 => Icons.rocket_launch,
  10766 => Icons.favorite,
  10767 => Icons.mic,
  10768 => Icons.gavel,
  37 => Icons.landscape,
  _ => Icons.movie,
};

/// Kademe rengi: 1 bronz, 5 gümüş, 10 altın.
Color tierColor(int tier) => switch (tier) {
  >= 10 => AppColors.badgeGold,
  >= 5 => AppColors.badgeSilver,
  _ => AppColors.badgeBronze,
};

/// Yuvarlak madalya: renkli halka içinde [child]; kazanılmamışsa gri.
class _Medal extends StatelessWidget {
  const _Medal({
    required this.size,
    required this.ring,
    required this.earned,
    required this.child,
    this.label,
  });

  final double size;
  final Color ring;
  final bool earned;
  final Widget child;

  /// Alt kenardaki küçük etiket (sezon numarası, kademe).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label;
    final medal = SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [ring, ring.withValues(alpha: 0.55), ring],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(size * AppSpacing.medalRingFactor),
                child: ClipOval(child: child),
              ),
            ),
          ),
          if (text != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: -AppSpacing.xs,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ring,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      text,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return earned
        ? medal
        : ColorFiltered(colorFilter: _grayscale, child: medal);
  }
}

/// Dizi veya sezon rozeti: afişten madalyon. Dizinin tamamı altın halka ve kupa etiketi,
/// sezon gümüş halka ve "S2" etiketi (F14).
class ShowBadgeMedal extends StatelessWidget {
  const ShowBadgeMedal({
    super.key,
    required this.posterPath,
    required this.seasonNumber,
    required this.label,
    this.size = AppSpacing.medalSize,
  });

  final String? posterPath;
  final int seasonNumber;

  /// Ekran okuyucu etiketi (dizi adı ve sezon).
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = tmdbImageUrl(posterPath, TmdbImageSize.w342);
    final whole = seasonNumber == 0;
    return Semantics(
      label: label,
      image: true,
      child: _Medal(
        size: size,
        ring: whole ? AppColors.badgeGold : AppColors.badgeSilver,
        earned: true,
        label: whole ? l10n.showBadgeFinal : l10n.seasonShort(seasonNumber),
        child: url == null
            ? ColoredBox(
                color: AppColors.surfaceAlt,
                child: Icon(Icons.live_tv, color: AppColors.textSecondary),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                // Afişin üst kısmı (genelde yüzler/başlık) madalyonda görünsün.
                alignment: Alignment.topCenter,
                errorWidget: (_, _, _) =>
                    ColoredBox(color: AppColors.surfaceAlt),
              ),
      ),
    );
  }
}

/// Genel rozet: tür rozeti türe uygun simge ve kademe rengiyle çizilir; diğerleri
/// `assets/badges/<icon>.png` görselidir (V16).
class GeneralBadgeMedal extends StatelessWidget {
  const GeneralBadgeMedal({
    super.key,
    required this.badge,
    required this.earned,
    required this.label,
    this.size = AppSpacing.medalSize,
  });

  final BadgeInfo badge;
  final bool earned;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final genre = parseGenreBadge(badge.code);
    if (genre != null) {
      final color = tierColor(genre.tier);
      return Semantics(
        label: label,
        image: true,
        child: _Medal(
          size: size,
          ring: color,
          earned: earned,
          label: '${genre.tier}',
          child: ColoredBox(
            color: AppColors.surfaceAlt,
            child: Icon(
              genreIcon(genre.genreId),
              color: color,
              size: size * AppSpacing.medalIconFactor,
            ),
          ),
        ),
      );
    }
    final image = Image.asset(
      'assets/badges/${badge.icon}.png',
      width: size,
      height: size,
      semanticLabel: label,
      // Tanımı yeni eklenmiş, görseli henüz olmayan rozet için genel simge.
      errorBuilder: (_, _, _) => Icon(Icons.emoji_events, size: size),
    );
    return earned
        ? image
        : ColorFiltered(colorFilter: _grayscale, child: image);
  }
}
