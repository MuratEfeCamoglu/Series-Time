import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/settings/logic.dart';

void main() {
  test('kullanıcı adı yazılınca silme onaylanır (F16)', () {
    expect(deleteConfirmationMatches('ayse_1', 'ayse_1'), isTrue);
    expect(deleteConfirmationMatches('  AYSE_1 ', 'ayse_1'), isTrue);
  });

  test('farklı veya boş ad onaylamaz', () {
    expect(deleteConfirmationMatches('', 'ayse_1'), isFalse);
    expect(deleteConfirmationMatches('ayse', 'ayse_1'), isFalse);
  });

  test('dil seçimi: Sistem telefon diline göre, elle seçim önce (F21b)', () {
    expect(
      resolveLanguageCode(choice: 'system', deviceLanguageCode: 'tr'),
      'tr',
    );
    expect(
      resolveLanguageCode(choice: 'system', deviceLanguageCode: 'de'),
      'en',
    );
    expect(
      resolveLanguageCode(choice: 'system', deviceLanguageCode: null),
      'en',
    );
    expect(resolveLanguageCode(choice: 'en', deviceLanguageCode: 'tr'), 'en');
    expect(resolveLanguageCode(choice: 'tr', deviceLanguageCode: 'en'), 'tr');
  });
}
