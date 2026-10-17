import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../providers.dart';

/// F8(j): dizi detayında kalp; yalnızca listedeki dizide görünür, en fazla 4 favori.
class ShowFavoriteButton extends ConsumerWidget {
  const ShowFavoriteButton({super.key, required this.showId});

  final int showId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(myShowProgressProvider).value ?? const [];
    final entry = entries.where((e) => e.showId == showId).firstOrNull;
    if (entry == null) return const SizedBox.shrink();
    final favorite = entry.isFavorite;
    return IconButton(
      key: const Key('showDetail.favorite'),
      tooltip: favorite ? l10n.favoriteRemove : l10n.favoriteAdd,
      isSelected: favorite,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: const Icon(Icons.favorite, color: AppColors.danger),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          final saved = await ref
              .read(myShowProgressProvider.notifier)
              .setFavorite(showId, !favorite);
          if (!saved) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.favoritesLimit)),
            );
          }
        } catch (_) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
        }
      },
    );
  }
}
