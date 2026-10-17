import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/guest_gate.dart';
import '../../../theme/app_spacing.dart';
import '../../auth/providers.dart';
import '../../tracking/providers.dart';
import '../logic.dart';
import '../providers.dart';
import '../widgets/episode_banner.dart';

/// Sezonun bölümleri (F4a, F5) bant olarak; derin bağlantı ve bildirimlerden açılır.
/// Dizi detayında aynı bantlar sezon kartının altında açılır.
class SeasonScreen extends ConsumerWidget {
  const SeasonScreen({
    super.key,
    required this.showId,
    required this.seasonNumber,
    this.title,
  });

  final int showId;
  final int seasonNumber;

  /// Önceki ekrandan gelen sezon adı; derin bağlantıyla açılınca yoktur.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final key = (showId: showId, seasonNumber: seasonNumber);
    final episodes = ref.watch(seasonEpisodesProvider(key));
    final watched = ref.watch(watchedEpisodesProvider(showId));
    final loaded = episodes.value;
    final now = DateTime.now();
    final isGuest = ref.watch(isGuestProvider);
    final canMarkAll =
        loaded != null &&
        watched.hasValue &&
        loaded.any((e) => isReleased(e, now));

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? l10n.seasonTitle(seasonNumber)),
        actions: [
          IconButton(
            key: const Key('season.markAll'),
            tooltip: l10n.seasonMarkAll,
            icon: const Icon(Icons.done_all),
            // F19(c): misafir işaretleyemez; düğme hesap çağrısını açar.
            onPressed: isGuest
                ? () => showGuestGate(context)
                : canMarkAll
                ? () => runMarking(
                    context,
                    ref
                        .read(watchedEpisodesProvider(showId).notifier)
                        .markSeason(seasonNumber, loaded),
                  )
                : null,
          ),
        ],
      ),
      body: episodes.when(
        data: (episodes) => episodes.isEmpty
            ? EmptyState(message: l10n.seasonNoEpisodes)
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: episodes.length,
                itemBuilder: (context, index) => EpisodeBannerTile(
                  episode: episodes[index],
                  seasonEpisodes: episodes,
                  watched: watched.value?.contains(episodes[index].id),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(seasonEpisodesProvider(key)),
        ),
      ),
    );
  }
}

/// İşaretleme hatasında F5(e) iletisi; iyimser durum sağlayıcıda zaten geri alınmıştır.
Future<void> runMarking(BuildContext context, Future<void> mutation) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).saveFailed;
  try {
    await mutation;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
