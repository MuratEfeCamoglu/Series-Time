import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/discover/logic.dart';

void main() {
  group('canSearch', () {
    test('en az 2 karakter gerekir (F3b)', () {
      expect(canSearch(''), isFalse);
      expect(canSearch('a'), isFalse);
      expect(canSearch('ab'), isTrue);
    });

    test('baştaki/sondaki boşluk sayılmaz', () {
      expect(canSearch(' a '), isFalse);
    });
  });

  group('usernamePrefixPattern', () {
    test('küçük harfe çevirir ve önek deseni üretir', () {
      expect(usernamePrefixPattern(' Ayse '), 'ayse%');
    });

    test('alt çizgi LIKE jokeri olmasın diye kaçırılır', () {
      expect(usernamePrefixPattern('ayse_1'), r'ayse\_1%');
    });

    test('kullanıcı adında olamayacak karakter varsa null', () {
      expect(usernamePrefixPattern('ay şe'), isNull);
      expect(usernamePrefixPattern('a%'), isNull);
      expect(usernamePrefixPattern(''), isNull);
    });
  });
}
