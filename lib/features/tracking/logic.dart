/// F5–F7 saf kuralları: ilerleme, İzleme Listesi bölümleri, Yaklaşan gruplaması ve
/// iyimser işaretleme kümeleri.
library;

import '../shows/data/models.dart';
import '../shows/logic.dart';
import 'data/models.dart';

/// "Bir süredir izlemediklerin" eşiği (V14).
const staleWatchAfter = Duration(days: 30);

/// Yaklaşan sekmesinin ufku (V14).
const upcomingDays = 90;

/// F6(c): Diziler ana ekranının üç görünümü.
enum WatchlistLayout { list, grid, poster }

/// İzlenen yayınlanmış bölüm / yayınlanmış bölüm (sezon 0 hariç, sayılar RPC'den gelir).
double watchProgress(int watchedCount, int airedCount) {
  if (airedCount <= 0) return 0;
  return (watchedCount / airedCount).clamp(0.0, 1.0);
}

/// F6(g): hiç izlenmemişler en üstte (eklenme tarihine göre azalan), sonra son izleme azalan.
List<WatchlistItem> sortWatchlist(List<WatchlistItem> items) {
  int compare(WatchlistItem a, WatchlistItem b) {
    final aWatched = a.lastWatchedAt;
    final bWatched = b.lastWatchedAt;
    if (aWatched == null && bWatched == null) {
      return b.addedAt.compareTo(a.addedAt);
    }
    if (aWatched == null) return -1;
    if (bWatched == null) return 1;
    return bWatched.compareTo(aWatched);
  }

  return [...items]..sort(compare);
}

/// F6(a, e): hiç izlenmemişler "Henüz başlamadıkların"; son izleme ≤ 30 gün önce olanlar
/// "Sıradaki"; > 30 gün önce olanlar "Bir süredir izlemediklerin".
({
  List<WatchlistItem> upNext,
  List<WatchlistItem> notStarted,
  List<WatchlistItem> notRecently,
})
splitWatchlist(List<WatchlistItem> items, DateTime now) {
  final sorted = sortWatchlist(items);
  bool isStale(WatchlistItem item) {
    final watched = item.lastWatchedAt;
    return watched != null && now.difference(watched) > staleWatchAfter;
  }

  return (
    upNext: [
      for (final item in sorted)
        if (item.lastWatchedAt != null && !isStale(item)) item,
    ],
    notStarted: [
      for (final item in sorted)
        if (item.lastWatchedAt == null) item,
    ],
    notRecently: [
      for (final item in sorted)
        if (isStale(item)) item,
    ],
  );
}

/// "S05 | B01 +38": sıradaki bölümden sonra kalan yayınlanmış bölüm sayısı.
int remainingAfterNext(WatchlistItem item) =>
    (item.airedCount - item.watchedCount - 1).clamp(0, item.airedCount);

/// Sezonun ilk bölümü "Sezon başı" etiketiyle gösterilir.
bool isSeasonPremiere(int episodeNumber) => episodeNumber == 1;

/// Dizi detayındaki "Sıradaki" bandı: izlenmemiş ilk yayınlanmış normal bölüm.
Episode? nextUnwatchedEpisode(
  List<Episode> episodes,
  Set<int> watchedIds,
  DateTime now,
) {
  final candidates =
      [
        for (final e in episodes)
          if (isAired(e, now) && !watchedIds.contains(e.id)) e,
      ]..sort((a, b) {
        final bySeason = a.seasonNumber.compareTo(b.seasonNumber);
        return bySeason != 0
            ? bySeason
            : a.episodeNumber.compareTo(b.episodeNumber);
      });
  return candidates.isEmpty ? null : candidates.first;
}

/// Sezon kartı: izlenen / yayınlanmış bölüm sayısı (özel bölümler için yayın tarihi yeterli).
({int watched, int released}) seasonProgress(
  List<Episode> seasonEpisodes,
  Set<int> watchedIds,
  DateTime now,
) {
  final released = [
    for (final e in seasonEpisodes)
      if (isReleased(e, now)) e,
  ];
  return (
    watched: released.where((e) => watchedIds.contains(e.id)).length,
    released: released.length,
  );
}

enum UpcomingDay { today, tomorrow, later }

UpcomingDay upcomingDayKind(DateTime airDate, DateTime now) {
  final days = utcDate(airDate).difference(utcDate(now)).inDays;
  return switch (days) {
    <= 0 => UpcomingDay.today,
    1 => UpcomingDay.tomorrow,
    _ => UpcomingDay.later,
  };
}

/// F7: tarih başlıklarına göre gruplar, artan tarih sırasıyla.
List<({DateTime date, List<UpcomingEpisode> episodes})> groupUpcoming(
  List<UpcomingEpisode> items,
) {
  final sorted = [...items]..sort((a, b) => a.airDate.compareTo(b.airDate));
  final groups = <({DateTime date, List<UpcomingEpisode> episodes})>[];
  for (final item in sorted) {
    final day = utcDate(item.airDate);
    if (groups.isEmpty || groups.last.date != day) {
      groups.add((date: day, episodes: [item]));
    } else {
      groups.last.episodes.add(item);
    }
  }
  return groups;
}

/// F5(b) için iyimser küme: sezonun işaretlenebilir bölümleri.
Set<int> markableEpisodeIds(List<Episode> episodes, DateTime now) => {
  for (final e in episodes)
    if (isReleased(e, now)) e.id,
};

/// F5(c) için iyimser küme (yalnızca açık sezon): hedef ve ondan önceki işaretlenebilir
/// bölümler. Önceki sezonlar sunucu yanıtından sonra yenilenir.
Set<int> episodeIdsUntil(
  List<Episode> seasonEpisodes,
  Episode target,
  DateTime now,
) {
  if (target.seasonNumber == specialsSeasonNumber) {
    return isReleased(target, now) ? {target.id} : {};
  }
  return {
    for (final e in seasonEpisodes)
      if (e.episodeNumber <= target.episodeNumber && isReleased(e, now)) e.id,
  };
}

/// F6(j) durum grupları. [paused] ve [dropped] yalnızca elle seçilir (V27).
enum ShowStatus { finished, upToDate, watching, paused, dropped, watchlist }

/// Filtre çiplerindeki ve menüdeki sıra.
const showStatusOrder = [
  ShowStatus.watching,
  ShowStatus.upToDate,
  ShowStatus.finished,
  ShowStatus.paused,
  ShowStatus.dropped,
  ShowStatus.watchlist,
];

/// Otomatik grup: hiç izlenmemiş veya yayınlanmış bölümü yoksa İzleme Listesi; yayınlanmış her şey
/// izlendiyse dizi bittiyse Bitti, değilse (veya TMDB durumu bilinmiyorsa) Güncel; aksi halde
/// Devam ediyor. Sayılar sezon 0 ve gelecek bölümleri içermez (RPC'den gelir).
ShowStatus autoShowStatus({
  required String? tmdbStatus,
  required int airedCount,
  required int watchedCount,
}) {
  if (airedCount <= 0 || watchedCount <= 0) return ShowStatus.watchlist;
  if (watchedCount < airedCount) return ShowStatus.watching;
  return showRunStatus(tmdbStatus) == ShowRunStatus.ended
      ? ShowStatus.finished
      : ShowStatus.upToDate;
}

/// Elle seçilen grup otomatiğin önüne geçer.
ShowStatus effectiveShowStatus({
  required ManualShowStatus? manual,
  required ShowStatus auto,
}) => switch (manual) {
  ManualShowStatus.paused => ShowStatus.paused,
  ManualShowStatus.dropped => ShowStatus.dropped,
  ManualShowStatus.planned => ShowStatus.watchlist,
  null => auto,
};

ShowStatus showStatusOf({
  required String? tmdbStatus,
  required int airedCount,
  required int watchedCount,
  required ManualShowStatus? manual,
}) => effectiveShowStatus(
  manual: manual,
  auto: autoShowStatus(
    tmdbStatus: tmdbStatus,
    airedCount: airedCount,
    watchedCount: watchedCount,
  ),
);

/// Çubuğun doluluğu: İzleme Listesi boş, Bitti ve Güncel dolu; diğerleri kalınan yere kadar.
double statusProgress(ShowStatus status, int watchedCount, int airedCount) =>
    switch (status) {
      ShowStatus.watchlist => 0,
      ShowStatus.finished || ShowStatus.upToDate => 1,
      _ => watchProgress(watchedCount, airedCount),
    };

/// Grup çipi seçili değilse (null) hepsi.
List<ShowProgress> filterByStatus(
  List<ShowProgress> shows,
  ShowStatus? status,
) => status == null
    ? shows
    : [
        for (final s in shows)
          if (showStatusOf(
                tmdbStatus: s.showStatus,
                airedCount: s.airedCount,
                watchedCount: s.watchedCount,
                manual: s.manualStatus,
              ) ==
              status)
            s,
      ];

/// Menüde seçilen grup → kaydedilecek elle seçim; null "Otomatik".
ManualShowStatus? manualFor(ShowStatus? choice) => switch (choice) {
  ShowStatus.paused => ManualShowStatus.paused,
  ShowStatus.dropped => ManualShowStatus.dropped,
  ShowStatus.watchlist => ManualShowStatus.planned,
  _ => null,
};

/// F8(j): profilde en fazla bu kadar favori dizi.
const maxFavorites = 4;

/// F7: Diziler sayfasında "Tümünü göster"den önce görünen yaklaşan bölüm sayısı.
const upcomingPreviewCount = 5;

/// F6: "Son izlenen diziler" satırının uzunluğu.
const recentShowsLimit = 20;

List<ShowProgress> favoriteShows(List<ShowProgress> shows) => [
  for (final s in shows)
    if (s.isFavorite) s,
];

bool canAddFavorite(List<ShowProgress> shows) =>
    favoriteShows(shows).length < maxFavorites;

/// En az bir bölümü izlenmiş diziler, son izlenen önce (F6).
List<ShowProgress> recentlyWatchedShows(List<ShowProgress> shows) {
  final watched = [
    for (final s in shows)
      if (s.lastWatchedAt != null) s,
  ]..sort((a, b) => b.lastWatchedAt!.compareTo(a.lastWatchedAt!));
  return watched.take(recentShowsLimit).toList();
}

/// Profildeki "Şu an izlediklerim": Devam ediyor grubundakiler, sıra korunur (F8e).
List<ShowProgress> currentlyWatching(List<ShowProgress> shows) =>
    filterByStatus(shows, ShowStatus.watching);

/// F6(k) Afiş görünümü Yaklaşan satırı: her diziden yalnızca en yakın bölüm, tarih sırası korunur.
List<UpcomingEpisode> nextUpcomingPerShow(List<UpcomingEpisode> episodes) {
  final seen = <int>{};
  return [
    for (final e in episodes)
      if (seen.add(e.showId)) e,
  ];
}
