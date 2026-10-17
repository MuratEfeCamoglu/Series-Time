import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tmdb_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../shows/data/models.dart';
import '../../shows/providers.dart';
import 'show_chooser.dart';

/// F2 dizi görselinden avatar: önce dizi (listeden veya aramayla), sonra o dizinin arka plan
/// ve afiş görselleri. Seçilen görselin TMDB yolunu döner; kırpma sonra yapılır.
class AvatarImagePickerSheet extends ConsumerStatefulWidget {
  const AvatarImagePickerSheet({super.key});

  @override
  ConsumerState<AvatarImagePickerSheet> createState() =>
      _AvatarImagePickerSheetState();
}

class _AvatarImagePickerSheetState
    extends ConsumerState<AvatarImagePickerSheet> {
  Show? _show;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final show = _show;
    return FractionallySizedBox(
      heightFactor: AppSpacing.sheetHeightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: show == null
                ? null
                : IconButton(
                    icon: const BackButtonIcon(),
                    onPressed: () => setState(() => _show = null),
                  ),
            title: Text(
              show?.name ?? l10n.avatarPickerTitle,
              style: AppTextStyles.title,
            ),
          ),
          Expanded(
            child: show == null
                ? ShowChooser(
                    onSelected: (show) => setState(() => _show = show),
                  )
                : _Images(show: show),
          ),
        ],
      ),
    );
  }
}

class _Images extends ConsumerWidget {
  const _Images({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(showImagesProvider(show.id))
        .when(
          data: (images) {
            final paths = [...images.backdrops, ...images.posters];
            if (paths.isEmpty) {
              return Center(
                child: Text(
                  l10n.avatarNoImages,
                  style: AppTextStyles.bodySecondary,
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppSpacing.posterGridColumns,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
              ),
              itemCount: paths.length,
              itemBuilder: (context, index) => Semantics(
                label: show.name,
                button: true,
                child: InkWell(
                  key: Key('avatarImage.$index'),
                  onTap: () => Navigator.pop(context, paths[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.posterRadius,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: tmdbImageUrl(paths[index], TmdbImageSize.w300)!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          ColoredBox(color: AppColors.surfaceAlt),
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(showImagesProvider(show.id)),
          ),
        );
  }
}
