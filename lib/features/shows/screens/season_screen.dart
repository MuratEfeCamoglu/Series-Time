import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_text_styles.dart';
import '../data/models.dart';
import '../providers.dart';

/// Sezonun bölümleri (F4a): no, ad, yayın tarihi.
// İzlendi onay kutusu ve satıra dokununca `/episode/:id` Aşama 3'te (F5) eklenir.
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
    return Scaffold(
      appBar: AppBar(title: Text(title ?? l10n.seasonTitle(seasonNumber))),
      body: ref
          .watch(seasonEpisodesProvider(key))
          .when(
            data: (episodes) => episodes.isEmpty
                ? EmptyState(message: l10n.seasonNoEpisodes)
                : ListView.builder(
                    itemCount: episodes.length,
                    itemBuilder: (context, index) =>
                        _EpisodeTile(episode: episodes[index]),
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

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final airDate = episode.airDate;
    return ListTile(
      leading: Text('${episode.episodeNumber}', style: AppTextStyles.title),
      title: Text(episode.name ?? '', style: AppTextStyles.body),
      subtitle: Text(
        airDate == null ? l10n.episodeNoAirDate : formatLongDate(airDate),
        style: AppTextStyles.bodySecondary,
      ),
    );
  }
}
