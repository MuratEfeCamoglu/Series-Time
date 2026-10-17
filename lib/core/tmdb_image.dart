/// TMDB görsel boyutları: listede [w342], detayda [w780] (ISKELET.md §5.2). Bölüm sahne
/// görselleri (still) w185/w300/original boyutlarında gelir; w342 yoktur.
enum TmdbImageSize { w185, w300, w342, w780, original }

/// `poster_path` gibi TMDB yolundan tam adres; yol yoksa null.
String? tmdbImageUrl(String? path, TmdbImageSize size) {
  if (path == null || path.isEmpty) return null;
  return 'https://image.tmdb.org/t/p/${size.name}$path';
}
