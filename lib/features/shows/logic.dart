/// F4 saf kuralları: dizi durumu, sezon ayrımı ve yayınlanmış bölüm.
library;

import 'data/models.dart';
import '../../core/app_locale.dart';

/// Sezon 0 TMDB'de özel bölümlerdir; ilerleme ve istatistiğe girmez (F4d).
const specialsSeasonNumber = 0;

enum ShowRunStatus { ongoing, ended, unknown }

/// TMDB `status` değerinden F4(a)'daki "devam ediyor / bitti" ayrımı.
ShowRunStatus showRunStatus(String? tmdbStatus) => switch (tmdbStatus) {
  'Ended' || 'Canceled' => ShowRunStatus.ended,
  'Returning Series' ||
  'In Production' ||
  'Planned' ||
  'Pilot' => ShowRunStatus.ongoing,
  _ => ShowRunStatus.unknown,
};

/// Normal sezonlar artan sırada; sezon 0 ayrı "Özel Bölümler" başlığı için.
({List<Season> regular, List<Season> specials}) splitSeasons(
  List<Season> seasons,
) {
  final sorted = [...seasons]
    ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
  return (
    regular: [
      for (final s in sorted)
        if (s.seasonNumber != specialsSeasonNumber) s,
    ],
    specials: [
      for (final s in sorted)
        if (s.seasonNumber == specialsSeasonNumber) s,
    ],
  );
}

DateTime utcDate(DateTime moment) {
  final utc = moment.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

/// Yayınlanmış bölüm: tarihi dolu, tarihi bugün (UTC) veya önce, sezon 0 değil.
/// Tarihsiz bölüm yayınlanmamış sayılır (R6).
bool isAired(Episode episode, DateTime now) {
  final airDate = episode.airDate;
  return airDate != null &&
      episode.seasonNumber != specialsSeasonNumber &&
      !airDate.isAfter(utcDate(now));
}

/// İşaretlenebilir bölüm (F5d): yayın tarihi dolu ve bugün (UTC) veya önce. Özel bölümler
/// de işaretlenebilir; yalnızca ilerlemeye girmezler ([isAired]).
bool isReleased(Episode episode, DateTime now) {
  final airDate = episode.airDate;
  return airDate != null && !airDate.isAfter(utcDate(now));
}

/// İzleme Listesi satırındaki "S01 | B05" biçimi (F6b).
String episodeLabel(int seasonNumber, int episodeNumber) =>
    'S${seasonNumber.toString().padLeft(2, '0')} | '
    '${AppLocale.episodeLetter}${episodeNumber.toString().padLeft(2, '0')}';

/// "S01B05" biçimi.
String episodeCode(int seasonNumber, int episodeNumber) =>
    'S${seasonNumber.toString().padLeft(2, '0')}'
    '${AppLocale.episodeLetter}${episodeNumber.toString().padLeft(2, '0')}';

/// Bölümleri önbellekte eksik olan yayınlanmış sezonlar. Sıradaki bölüm ve ilerleme
/// yalnızca önbellekteki bölümlerden hesaplandığı için, çekilmemiş bir sezon diziyi
/// "bitti" gösterir (ör. 1. sezon bitince 2. sezon hiç görünmez); bunlar tamamlanır.
List<int> missingSeasonNumbers({
  required List<Season> seasons,
  required List<Episode> cached,
  required DateTime now,
}) {
  final counts = <int, int>{};
  for (final episode in cached) {
    counts.update(episode.seasonNumber, (n) => n + 1, ifAbsent: () => 1);
  }
  final today = utcDate(now);
  return [
    for (final season in seasons)
      if (season.seasonNumber != specialsSeasonNumber &&
          season.airDate != null &&
          !season.airDate!.isAfter(today) &&
          (season.episodeCount ?? 0) > (counts[season.seasonNumber] ?? 0))
        season.seasonNumber,
  ];
}
