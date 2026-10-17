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

/// Sayfadan dönen seçim; [show] null ise "Otomatik" (V9: son izlenen dizinin arka planı).
class CoverSelection {
  const CoverSelection({this.show, this.path});

  final Show? show;
  final String? path;
}

/// F2 kapak seçimi: önce dizi (listeden veya aramayla), sonra o dizinin arka plan görselleri.
class CoverPickerSheet extends ConsumerStatefulWidget {
  const CoverPickerSheet({super.key, required this.selectedPath});

  final String? selectedPath;

  @override
  ConsumerState<CoverPickerSheet> createState() => _CoverPickerSheetState();
}

class _CoverPickerSheetState extends ConsumerState<CoverPickerSheet> {
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
              show?.name ?? l10n.coverPickerTitle,
              style: AppTextStyles.title,
            ),
            subtitle: show == null
                ? Text(l10n.coverPickerHint, style: AppTextStyles.caption)
                : null,
          ),
          if (show == null) ...[
            ListTile(
              key: const Key('cover.none'),
              title: Text(l10n.coverNone),
              trailing: widget.selectedPath == null
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => Navigator.pop(context, const CoverSelection()),
            ),
            Expanded(
              child: ShowChooser(
                onSelected: (show) => setState(() => _show = show),
              ),
            ),
          ] else
            Expanded(
              child: _Backdrops(show: show, selectedPath: widget.selectedPath),
            ),
        ],
      ),
    );
  }
}

class _Backdrops extends ConsumerWidget {
  const _Backdrops({required this.show, required this.selectedPath});

  final Show show;
  final String? selectedPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(showBackdropsProvider(show.id))
        .when(
          data: (paths) => paths.isEmpty
              ? Center(
                  child: Text(
                    l10n.coverNoImages,
                    style: AppTextStyles.bodySecondary,
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppSpacing.coverGridColumns,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: AppSpacing.coverThumbAspectRatio,
                  ),
                  itemCount: paths.length,
                  itemBuilder: (context, index) {
                    final path = paths[index];
                    final selected = path == selectedPath;
                    return Semantics(
                      label: show.name,
                      selected: selected,
                      button: true,
                      child: InkWell(
                        key: Key('cover.image.$index'),
                        onTap: () => Navigator.pop(
                          context,
                          CoverSelection(show: show, path: path),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.posterRadius,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: tmdbImageUrl(
                                  path,
                                  TmdbImageSize.w300,
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(showBackdropsProvider(show.id)),
          ),
        );
  }
}
