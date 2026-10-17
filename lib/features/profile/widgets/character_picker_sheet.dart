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
import 'profile_avatar.dart';
import 'show_chooser.dart';

/// F2 karakter avatarı: önce dizi, sonra o dizinin oyuncu/karakter fotoğrafları.
/// Seçilen kişinin TMDB profil görseli yolunu döner.
class CharacterPickerSheet extends ConsumerStatefulWidget {
  const CharacterPickerSheet({super.key});

  @override
  ConsumerState<CharacterPickerSheet> createState() =>
      _CharacterPickerSheetState();
}

class _CharacterPickerSheetState extends ConsumerState<CharacterPickerSheet> {
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
              show?.name ?? l10n.characterPickerTitle,
              style: AppTextStyles.title,
            ),
          ),
          Expanded(
            child: show == null
                ? ShowChooser(
                    onSelected: (show) => setState(() => _show = show),
                  )
                : _Cast(show: show),
          ),
        ],
      ),
    );
  }
}

class _Cast extends ConsumerWidget {
  const _Cast({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(showCastProvider(show.id))
        .when(
          data: (cast) {
            // Fotoğrafı olmayan kişi avatar olamaz.
            final withPhoto = [
              for (final m in cast)
                if (m.profilePath != null) m,
            ];
            if (withPhoto.isEmpty) {
              return Center(
                child: Text(
                  l10n.showCastEmpty,
                  style: AppTextStyles.bodySecondary,
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppSpacing.posterGridColumns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: AppSpacing.characterTileAspectRatio,
              ),
              itemCount: withPhoto.length,
              itemBuilder: (context, index) {
                final member = withPhoto[index];
                final character = member.character;
                return InkWell(
                  key: Key('character.${member.personId}'),
                  borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
                  onTap: () => Navigator.pop(context, member.profilePath),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        size: AppSpacing.characterAvatarSize,
                        url: tmdbImageUrl(
                          member.profilePath,
                          TmdbImageSize.w185,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        character ?? member.name,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (character != null)
                        Text(
                          member.name,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(showCastProvider(show.id)),
          ),
        );
  }
}
