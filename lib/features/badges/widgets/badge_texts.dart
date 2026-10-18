import '../../../core/app_locale.dart';
import '../../../l10n/app_localizations.dart';
import '../../suggest/logic.dart';
import '../logic.dart';

/// F14 tür rozetlerinde türün Türkçe adı (`genres` önbelleği rozet ekranında yüklenmez).
const _genreNamesTr = {
  10759: 'Aksiyon & Macera',
  16: 'Animasyon',
  35: 'Komedi',
  80: 'Suç',
  99: 'Belgesel',
  18: 'Dram',
  10751: 'Aile',
  10762: 'Çocuk',
  9648: 'Gizem',
  10763: 'Haber',
  10764: 'Gerçeklik',
  10765: 'Bilim Kurgu & Fantastik',
  10766: 'Pembe Dizi',
  10767: 'Talk Show',
  10768: 'Savaş & Politika',
  37: 'Western',
};

String genreName(int genreId) =>
    (AppLocale.isEnglish ? tmdbGenreNamesEn : _genreNamesTr)[genreId] ??
    '$genreId';

String _tierTitle(AppLocalizations l10n, int tier) => switch (tier) {
  >= 10 => l10n.genreTierMaster,
  >= 5 => l10n.genreTierEnthusiast,
  _ => l10n.genreTierFan,
};

/// F21(b): rozet adı ve koşulu arayüz dilinde; bilinmeyen rozet veritabanındaki metinle kalır.
String badgeTitle(AppLocalizations l10n, String code, String fallback) {
  final genre = parseGenreBadge(code);
  if (genre != null) {
    return l10n.genreBadgeTitle(
      genreName(genre.genreId),
      _tierTitle(l10n, genre.tier),
    );
  }
  return switch (code) {
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
}

String badgeCondition(AppLocalizations l10n, String code, String fallback) {
  final genre = parseGenreBadge(code);
  if (genre != null) {
    return l10n.genreBadgeCondition(genre.tier, genreName(genre.genreId));
  }
  return switch (code) {
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
}

/// Dizi rozetinin adı: "Dizi · Final" ya da "Dizi · 2. Sezon".
String showBadgeTitle(AppLocalizations l10n, String showName, int season) =>
    season == 0
    ? l10n.showBadgeTitle(showName)
    : l10n.seasonBadgeTitle(showName, season);
