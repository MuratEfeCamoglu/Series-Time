import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sezonluk/core/format.dart';
import 'package:sezonluk/core/tmdb_image.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  test('parseDbDate tarihi UTC gece yarısı olarak okur', () {
    expect(parseDbDate('2011-04-17'), DateTime.utc(2011, 4, 17));
    expect(parseDbDate(null), isNull);
    expect(parseDbDate(''), isNull);
  });

  test('formatLongDate Türkçe ay adıyla yazar', () {
    expect(formatLongDate(DateTime.utc(2026, 10, 17)), '17 Ekim 2026');
  });

  test('tmdbImageUrl boyut ve yolu birleştirir', () {
    expect(
      tmdbImageUrl('/a.jpg', TmdbImageSize.w342),
      'https://image.tmdb.org/t/p/w342/a.jpg',
    );
    expect(tmdbImageUrl(null, TmdbImageSize.w780), isNull);
    expect(tmdbImageUrl('', TmdbImageSize.w780), isNull);
  });
}
