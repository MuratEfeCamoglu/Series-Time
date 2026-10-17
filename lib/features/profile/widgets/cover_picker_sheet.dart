import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/providers.dart';

/// Sayfadan dönen seçim; [showId] null ise "Otomatik" (V9).
class CoverSelection {
  const CoverSelection(this.showId);

  final int? showId;
}

/// F2 kapak seçimi: kullanıcının listesindeki dizilerin TMDB arka planları (V9, yükleme yok).
class CoverPickerSheet extends ConsumerWidget {
  const CoverPickerSheet({super.key, required this.selectedShowId});

  final int? selectedShowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shows = [
      for (final entry in ref.watch(myShowsProvider).value ?? const [])
        if (entry.show.backdropPath != null) entry.show,
    ];
    return FractionallySizedBox(
      heightFactor: AppSpacing.sheetHeightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.coverPickerTitle, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.coverPickerHint, style: AppTextStyles.caption),
              ],
            ),
          ),
          ListTile(
            key: const Key('cover.none'),
            title: Text(l10n.coverNone),
            trailing: selectedShowId == null
                ? const Icon(Icons.check, color: AppColors.accent)
                : null,
            onTap: () => Navigator.pop(context, const CoverSelection(null)),
          ),
          Expanded(
            child: shows.isEmpty
                ? Center(
                    child: Text(
                      l10n.coverPickerEmpty,
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppSpacing.coverGridColumns,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: AppSpacing.coverThumbAspectRatio,
                        ),
                    itemCount: shows.length,
                    itemBuilder: (context, index) {
                      final show = shows[index];
                      final selected = show.id == selectedShowId;
                      return Semantics(
                        label: show.name,
                        selected: selected,
                        button: true,
                        child: InkWell(
                          key: Key('cover.${show.id}'),
                          onTap: () =>
                              Navigator.pop(context, CoverSelection(show.id)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.posterRadius,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  // TMDB arka plan boyutları w300/w780/w1280; w342 yoktur.
                                  imageUrl: tmdbImageUrl(
                                    show.backdropPath,
                                    TmdbImageSize.w780,
                                  )!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const ColoredBox(
                                    color: AppColors.surfaceAlt,
                                  ),
                                ),
                                if (selected)
                                  const Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(AppSpacing.xs),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
