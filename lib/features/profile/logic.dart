/// F2, F8 saf kuralları: profil alanı doğrulama, ülke bayrağı, izleme süresi ve kapak.
library;

import '../shows/data/models.dart';
import 'data/models.dart';

const maxDisplayNameLength = 40;
const maxBioLength = 160;
const maxAvatarBytes = 2 * 1024 * 1024;

// Postgres `char_length` kod noktası sayar; Dart `length` UTF-16 birimi sayar.
// Emoji gibi karakterlerde ikisi ayrışmasın diye `runes` kullanılır.
bool isValidDisplayName(String value) {
  final length = value.trim().runes.length;
  return length >= 1 && length <= maxDisplayNameLength;
}

bool isValidBio(String value) => value.trim().runes.length <= maxBioLength;

bool isValidAvatarSize(int bytes) => bytes <= maxAvatarBytes;

/// "TR" → 🇹🇷. Bayrak, iki bölgesel gösterge harfinin yan yana yazılmasıdır.
String countryFlag(String code) {
  const regionalIndicatorA = 0x1F1E6;
  final upper = code.toUpperCase();
  return String.fromCharCodes(
    upper.codeUnits.map((unit) => regionalIndicatorA + unit - 0x41),
  );
}

/// [query] boşsa tüm liste; değilse koda göre önek eşleşmesi.
List<String> filterCountryCodes(String query) {
  final upper = query.trim().toUpperCase();
  if (upper.isEmpty) return isoCountryCodes;
  return isoCountryCodes.where((code) => code.startsWith(upper)).toList();
}

const _minutesPerHour = 60;
const _minutesPerDay = 24 * _minutesPerHour;
// V15: istatistikte 1 ay = 30 gün.
const _minutesPerMonth = 30 * _minutesPerDay;

/// F8(d): toplam dakika → ay, gün, saat. Bir saatten kısa kalan dakikalar atılır.
({int months, int days, int hours}) splitWatchTime(int totalMinutes) {
  final minutes = totalMinutes < 0 ? 0 : totalMinutes;
  return (
    months: minutes ~/ _minutesPerMonth,
    days: minutes % _minutesPerMonth ~/ _minutesPerDay,
    hours: minutes % _minutesPerDay ~/ _minutesPerHour,
  );
}

/// F8(e): "Dizilerim" sırası — son izlenen önce, hiç izlenmeyenler en sonda (eklenmeye göre).
List<UserShow> sortByLastWatched(List<UserShow> shows) {
  int compare(UserShow a, UserShow b) {
    final aWatched = a.lastWatchedAt;
    final bWatched = b.lastWatchedAt;
    if (aWatched != null && bWatched != null) {
      return bWatched.compareTo(aWatched);
    }
    if (aWatched != null) return -1;
    if (bWatched != null) return 1;
    return b.addedAt.compareTo(a.addedAt);
  }

  return [...shows]..sort(compare);
}

/// V9: seçilen kapak listedeyse o; değilse en son izlenen dizi; o da yoksa null (düz renk).
/// Arka plan görseli olmayan diziler kapak olamaz.
Show? coverShow(int? coverShowId, List<UserShow> shows) {
  final withBackdrop = [
    for (final entry in shows)
      if (entry.show.backdropPath != null) entry,
  ];
  for (final entry in withBackdrop) {
    if (entry.show.id == coverShowId) return entry.show;
  }
  for (final entry in sortByLastWatched(withBackdrop)) {
    if (entry.lastWatchedAt != null) return entry.show;
  }
  return null;
}

const _tmdbAvatarPrefix = 'tmdb:';

/// Kırpılan avatarın kenar uzunluğu (F2).
const avatarOutputSize = 512;

/// Eski sürümde seçilen TMDB oyuncu fotoğrafı avatarları "tmdb:" öneklidir; hâlâ gösterilir.
bool isTmdbAvatar(String path) => path.startsWith(_tmdbAvatarPrefix);

String toTmdbAvatarPath(String tmdbPath) => '$_tmdbAvatarPrefix$tmdbPath';

String fromTmdbAvatarPath(String path) =>
    path.substring(_tmdbAvatarPrefix.length);

/// Profil kapağının TMDB yolu: seçilen görsel; yoksa V9 kuralıyla dizinin arka planı.
String? profileCoverPath(Profile profile, List<UserShow> shows) =>
    profile.coverPath ?? coverShow(profile.coverShowId, shows)?.backdropPath;

/// ISO 3166-1 alpha-2, resmî olarak atanmış 249 kod.
const isoCountryCodes = [
  'AD', 'AE', 'AF', 'AG', 'AI', 'AL', 'AM', 'AO', 'AQ', 'AR', 'AS', 'AT', //
  'AU', 'AW', 'AX', 'AZ', 'BA', 'BB', 'BD', 'BE', 'BF', 'BG', 'BH', 'BI', //
  'BJ', 'BL', 'BM', 'BN', 'BO', 'BQ', 'BR', 'BS', 'BT', 'BV', 'BW', 'BY', //
  'BZ', 'CA', 'CC', 'CD', 'CF', 'CG', 'CH', 'CI', 'CK', 'CL', 'CM', 'CN', //
  'CO', 'CR', 'CU', 'CV', 'CW', 'CX', 'CY', 'CZ', 'DE', 'DJ', 'DK', 'DM', //
  'DO', 'DZ', 'EC', 'EE', 'EG', 'EH', 'ER', 'ES', 'ET', 'FI', 'FJ', 'FK', //
  'FM', 'FO', 'FR', 'GA', 'GB', 'GD', 'GE', 'GF', 'GG', 'GH', 'GI', 'GL', //
  'GM', 'GN', 'GP', 'GQ', 'GR', 'GS', 'GT', 'GU', 'GW', 'GY', 'HK', 'HM', //
  'HN', 'HR', 'HT', 'HU', 'ID', 'IE', 'IL', 'IM', 'IN', 'IO', 'IQ', 'IR', //
  'IS', 'IT', 'JE', 'JM', 'JO', 'JP', 'KE', 'KG', 'KH', 'KI', 'KM', 'KN', //
  'KP', 'KR', 'KW', 'KY', 'KZ', 'LA', 'LB', 'LC', 'LI', 'LK', 'LR', 'LS', //
  'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'ME', 'MF', 'MG', 'MH', 'MK', //
  'ML', 'MM', 'MN', 'MO', 'MP', 'MQ', 'MR', 'MS', 'MT', 'MU', 'MV', 'MW', //
  'MX', 'MY', 'MZ', 'NA', 'NC', 'NE', 'NF', 'NG', 'NI', 'NL', 'NO', 'NP', //
  'NR', 'NU', 'NZ', 'OM', 'PA', 'PE', 'PF', 'PG', 'PH', 'PK', 'PL', 'PM', //
  'PN', 'PR', 'PS', 'PT', 'PW', 'PY', 'QA', 'RE', 'RO', 'RS', 'RU', 'RW', //
  'SA', 'SB', 'SC', 'SD', 'SE', 'SG', 'SH', 'SI', 'SJ', 'SK', 'SL', 'SM', //
  'SN', 'SO', 'SR', 'SS', 'ST', 'SV', 'SX', 'SY', 'SZ', 'TC', 'TD', 'TF', //
  'TG', 'TH', 'TJ', 'TK', 'TL', 'TM', 'TN', 'TO', 'TR', 'TT', 'TV', 'TW', //
  'TZ', 'UA', 'UG', 'UM', 'US', 'UY', 'UZ', 'VA', 'VC', 'VE', 'VG', 'VI', //
  'VN', 'VU', 'WF', 'WS', 'YE', 'YT', 'ZA', 'ZM', 'ZW',
];

final _letterboxdPattern = RegExp(r'^[a-z0-9_]{2,15}$');
final _instagramPattern = RegExp(r'^[a-z0-9._]{1,30}$');

/// F2: "@ad", "letterboxd.com/ad/" veya "instagram.com/ad" yapıştırılsa da yalnızca kullanıcı adı
/// alınır; boşsa null (alan isteğe bağlı).
String? normalizeSocialUsername(String input) {
  var value = input.trim();
  final fromUrl = RegExp(
    r'(?:letterboxd\.com|instagram\.com)/([^/?#\s]+)',
    caseSensitive: false,
  ).firstMatch(value);
  if (fromUrl != null) value = fromUrl.group(1)!;
  if (value.startsWith('@')) value = value.substring(1);
  value = value.toLowerCase();
  return value.isEmpty ? null : value;
}

bool isValidLetterboxdUsername(String username) =>
    _letterboxdPattern.hasMatch(username);

/// Instagram: harf, rakam, nokta, alt çizgi; nokta ile başlayıp bitmez, art arda nokta yok.
bool isValidInstagramUsername(String username) =>
    _instagramPattern.hasMatch(username) &&
    !username.startsWith('.') &&
    !username.endsWith('.') &&
    !username.contains('..');

String letterboxdUrl(String username) => 'https://letterboxd.com/$username/';

String instagramUrl(String username) => 'https://www.instagram.com/$username/';

/// F8(l): grafiğin sütunları, 0,5 adımla 0,5–5.
const ratingSteps = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];

/// Her puan adımı için verilen puan sayısı; hiç verilmeyen adım 0.
List<({double rating, int count})> ratingHistogram(List<RatingCount> counts) {
  final byRating = {for (final c in counts) c.rating: c.count};
  return [
    for (final rating in ratingSteps)
      (rating: rating, count: byRating[rating] ?? 0),
  ];
}

int totalRatings(List<RatingCount> counts) =>
    counts.fold(0, (sum, c) => sum + c.count);

/// Hiç puan yoksa null.
double? averageRating(List<RatingCount> counts) {
  final total = totalRatings(counts);
  if (total == 0) return null;
  return counts.fold(0.0, (sum, c) => sum + c.rating * c.count) / total;
}
