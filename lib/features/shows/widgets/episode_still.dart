import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/tmdb_image.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Bölümün TMDB sahne görseli (F4a): kullanıcı kararıyla izlenmemiş bölümde de net gösterilir.
/// Görsel yoksa düz zemin üzerinde simge.
class EpisodeStill extends StatelessWidget {
  const EpisodeStill({
    super.key,
    required this.stillPath,
    required this.semanticLabel,
    this.size = TmdbImageSize.w300,
  });

  final String? stillPath;
  final String semanticLabel;
  final TmdbImageSize size;

  @override
  Widget build(BuildContext context) {
    final url = tmdbImageUrl(stillPath, size);
    const placeholder = ColoredBox(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
      ),
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      child: AspectRatio(
        aspectRatio: AppSpacing.stillAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
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
    );
  }
}
