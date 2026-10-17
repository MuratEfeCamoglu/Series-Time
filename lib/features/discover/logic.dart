/// F3 saf kuralları: arama eşiği, bekleme süresi ve kullanıcı adı önek deseni.
library;

const minSearchLength = 2;
const searchDebounce = Duration(milliseconds: 300);
const maxUserResults = 20;

final _usernameChars = RegExp(r'^[a-z0-9_]+$');

bool canSearch(String query) => query.trim().runes.length >= minSearchLength;

/// Kullanıcı adında önek eşleşmesi için SQL `LIKE` deseni. `_` LIKE'ta tek karakter
/// joker olduğu için kaçırılır. Kullanıcı adında olamayacak karakter varsa null:
/// sorgu atmaya gerek yoktur, sonuç zaten boştur.
String? usernamePrefixPattern(String query) {
  final normalized = query.trim().toLowerCase();
  if (!_usernameChars.hasMatch(normalized)) return null;
  return '${normalized.replaceAll('_', r'\_')}%';
}
