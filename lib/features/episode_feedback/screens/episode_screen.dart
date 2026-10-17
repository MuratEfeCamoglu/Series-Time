import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';

/// Bölüm Sonrası ekranı (`/episode/:id`). Tepki, yıldız oylaması ve yorumlar Aşama 5'te
/// (F9–F11) gelir; Aşama 3'te yalnızca işaretleme sonrası yönlendirme hedefidir (F5f).
class EpisodeScreen extends StatelessWidget {
  const EpisodeScreen({super.key, required this.episodeId});

  final int episodeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.episodeTitle)),
      body: EmptyState(
        message: l10n.episodeFeedbackSoon,
        icon: Icons.forum_outlined,
      ),
    );
  }
}
