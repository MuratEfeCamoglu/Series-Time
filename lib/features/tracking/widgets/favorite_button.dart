import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
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
      // F22(c): kalp dolarken kısa bir ölçek animasyonu.
      icon: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : AppMotion.toggle,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: favorite
            ? const Icon(
                Icons.favorite,
                key: ValueKey(true),
                color: AppColors.danger,
              )
            : const Icon(Icons.favorite_border, key: ValueKey(false)),
      ),
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
