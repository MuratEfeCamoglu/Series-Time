import '../../../l10n/app_localizations.dart';

/// F21(b): rozet adı ve koşulu arayüz dilinde; bilinmeyen rozet veritabanındaki metinle kalır.
String badgeTitle(AppLocalizations l10n, String code, String fallback) =>
    switch (code) {
      'first_episode' => l10n.badgeFirstEpisodeName,
      'episodes_10' => l10n.badgeEpisodes10Name,
      'episodes_50' => l10n.badgeEpisodes50Name,
      'episodes_100' => l10n.badgeEpisodes100Name,
      'episodes_500' => l10n.badgeEpisodes500Name,
      'episodes_1000' => l10n.badgeEpisodes1000Name,
      'episodes_5000' => l10n.badgeEpisodes5000Name,
      'shows_10' => l10n.badgeShows10Name,
      'shows_25' => l10n.badgeShows25Name,
      'shows_50' => l10n.badgeShows50Name,
      'first_finished' => l10n.badgeFirstFinishedName,
      'finished_5' => l10n.badgeFinished5Name,
      'first_comment' => l10n.badgeFirstCommentName,
      'comments_10' => l10n.badgeComments10Name,
      'comments_50' => l10n.badgeComments50Name,
      _ => fallback,
    };

String badgeCondition(AppLocalizations l10n, String code, String fallback) =>
    switch (code) {
      'first_episode' => l10n.badgeFirstEpisodeDesc,
      'episodes_10' => l10n.badgeEpisodes10Desc,
      'episodes_50' => l10n.badgeEpisodes50Desc,
      'episodes_100' => l10n.badgeEpisodes100Desc,
      'episodes_500' => l10n.badgeEpisodes500Desc,
      'episodes_1000' => l10n.badgeEpisodes1000Desc,
      'episodes_5000' => l10n.badgeEpisodes5000Desc,
      'shows_10' => l10n.badgeShows10Desc,
      'shows_25' => l10n.badgeShows25Desc,
      'shows_50' => l10n.badgeShows50Desc,
      'first_finished' => l10n.badgeFirstFinishedDesc,
      'finished_5' => l10n.badgeFinished5Desc,
      'first_comment' => l10n.badgeFirstCommentDesc,
      'comments_10' => l10n.badgeComments10Desc,
      'comments_50' => l10n.badgeComments50Desc,
      _ => fallback,
    };
