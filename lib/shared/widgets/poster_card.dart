import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/tmdb_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'motion.dart';

/// 2:3 oranlı, köşeleri yuvarlatılmış dizi afişi. Afiş yoksa dizi adı yazılı boş kart.
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.title,
    required this.posterPath,
    this.size = TmdbImageSize.w342,
    this.onTap,
    this.heroTag,
  });

  final String title;
  final String? posterPath;
  final TmdbImageSize size;
  final VoidCallback? onTap;

  /// Verilirse afiş dizi detayındaki afişe büyüyerek geçer (Hero). Aynı sayfada
  /// benzersiz olmalı; bu yüzden bölüm önekiyle verilir (ör. "popular-1399").
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final url = tmdbImageUrl(posterPath, size);
    final placeholder = ColoredBox(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    final tag = heroTag;
    final card = Semantics(
      label: title,
      button: onTap != null,
      child: AspectRatio(
        aspectRatio: AppSpacing.posterAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
          child: Material(
            color: AppColors.surfaceAlt,
            child: InkWell(
              onTap: onTap,
              child: url == null
                  ? placeholder
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => placeholder,
                      errorWidget: (_, _, _) => placeholder,
                    ),
            ),
          ),
        ),
      ),
    );
    return PressScale(
      enabled: onTap != null,
      child: tag == null ? card : Hero(tag: tag, child: card),
    );
  }
}
