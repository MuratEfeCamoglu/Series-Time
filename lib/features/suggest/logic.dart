/// F18 saf kuralları: kategori seçimi, varsayılan seçim ve listedeki dizileri ayıklama.
library;

import '../shows/data/models.dart';

/// F18(b): aynı anda en fazla 3 kategori.
const maxSelectedGenres = 3;

/// Seçili türe dokunmak onu kaldırır; seçili değilse ekler. 3 tür seçiliyken yeni tür
/// eklenmez ve [rejected] true döner (ekran "En fazla 3 kategori" iletisini gösterir).
({Set<int> selection, bool rejected}) toggleGenre(
  Set<int> selected,
  int genreId,
) {
  if (selected.contains(genreId)) {
    return (selection: {...selected}..remove(genreId), rejected: false);
  }
  if (selected.length >= maxSelectedGenres) {
    return (selection: selected, rejected: true);
  }
  return (selection: {...selected, genreId}, rejected: false);
}

/// F18(c): cihazda saklanan son seçim varsa o (boş seçim de bir seçimdir); yoksa
/// listedeki en sık 3 tür; liste boşsa hiçbiri.
Set<int> defaultGenreSelection({
  required List<int>? stored,
  required List<int> topGenres,
}) => (stored ?? topGenres).take(maxSelectedGenres).toSet();

/// F18(e): listeye eklenen dizi sunucu yanıtını beklemeden ızgaradan kalkar.
List<Show> withoutShows(List<Show> results, Set<int> excludedIds) => [
  for (final show in results)
    if (!excludedIds.contains(show.id)) show,
];

/// F18(f): "İzlediklerine benzer" bölümünün kaynağı en son izlenen dizi; hiç bölüm
/// izlenmemişse null (bölüm gösterilmez).
Show? lastWatchedShow(List<UserShow> shows) {
  UserShow? latest;
  for (final entry in shows) {
    final watched = entry.lastWatchedAt;
    if (watched == null) continue;
    if (latest == null || watched.isAfter(latest.lastWatchedAt!)) {
      latest = entry;
    }
  }
  return latest?.show;
}

/// F21(b): TMDB dizi türlerinin İngilizce adları. `genres` önbelleği Türkçedir; İngilizce
/// arayüzde bu adlar gösterilir, bilinmeyen tür önbellekteki adla kalır.
const tmdbGenreNamesEn = {
  10759: 'Action & Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  10762: 'Kids',
  9648: 'Mystery',
  10763: 'News',
  10764: 'Reality',
  10765: 'Sci-Fi & Fantasy',
  10766: 'Soap',
  10767: 'Talk',
  10768: 'War & Politics',
  37: 'Western',
};

String genreLabel({
  required int id,
  required String cachedName,
  required bool english,
}) => english ? tmdbGenreNamesEn[id] ?? cachedName : cachedName;
