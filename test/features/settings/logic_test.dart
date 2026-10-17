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
}
