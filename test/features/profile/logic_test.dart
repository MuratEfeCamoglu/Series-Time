import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/profile/logic.dart';

void main() {
  test('isValidDisplayName 1–40 karakter ister (F2)', () {
    expect(isValidDisplayName(''), isFalse);
    expect(isValidDisplayName('   '), isFalse);
    expect(isValidDisplayName('A'), isTrue);
    expect(isValidDisplayName('a' * 40), isTrue);
    expect(isValidDisplayName('a' * 41), isFalse);
  });

  test('emoji kod noktası olarak sayılır (Postgres char_length ile aynı)', () {
    // Her 😀 UTF-16'da 2 birimdir; 40 emoji yine de 40 karakterdir.
    expect(isValidDisplayName('😀' * 40), isTrue);
    expect(isValidBio('😀' * 160), isTrue);
    expect(isValidBio('😀' * 161), isFalse);
  });

  test('isValidBio en fazla 160 karakter (F2)', () {
    expect(isValidBio(''), isTrue);
    expect(isValidBio('a' * 160), isTrue);
    expect(isValidBio('a' * 161), isFalse);
  });

  test('isValidAvatarSize 2 MB sınırı (F2)', () {
    expect(isValidAvatarSize(2 * 1024 * 1024), isTrue);
    expect(isValidAvatarSize(2 * 1024 * 1024 + 1), isFalse);
  });

  test('countryFlag ISO kodunu bayrak emojisine çevirir', () {
    expect(countryFlag('TR'), '🇹🇷');
    expect(countryFlag('de'), '🇩🇪');
  });

  group('isoCountryCodes', () {
    test('249 benzersiz, sıralı, iki büyük harfli kod içerir', () {
      expect(isoCountryCodes, hasLength(249));
      expect(isoCountryCodes.toSet(), hasLength(249));
      expect(isoCountryCodes, everyElement(matches(RegExp(r'^[A-Z]{2}$'))));
      expect([...isoCountryCodes]..sort(), isoCountryCodes);
    });

    test('filterCountryCodes önek eşleşmesi yapar', () {
      expect(filterCountryCodes(''), isoCountryCodes);
      expect(filterCountryCodes(' tr '), ['TR']);
      expect(filterCountryCodes('t'), everyElement(startsWith('T')));
      expect(filterCountryCodes('qq'), isEmpty);
    });
  });
}
