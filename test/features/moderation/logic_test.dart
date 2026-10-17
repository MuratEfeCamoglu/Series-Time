import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/moderation/data/models.dart';
import 'package:sezonluk/features/moderation/logic.dart';

void main() {
  test('şikayet notu en fazla 300 karakter', () {
    expect(isValidReportNote(''), isTrue);
    expect(isValidReportNote('a' * 300), isTrue);
    expect(isValidReportNote('a' * 301), isFalse);
  });

  test('boş not null olur, dolu not kırpılır', () {
    expect(normalizeReportNote('   '), isNull);
    expect(normalizeReportNote(' spam '), 'spam');
  });

  test('neden ve hedef adları veritabanı enum değerleriyle aynı', () {
    expect(ReportReason.values.map((r) => r.name), [
      'spam',
      'harassment',
      'spoiler',
      'inappropriate',
      'other',
    ]);
    expect(ReportTarget.values.map((t) => t.name), ['comment', 'profile']);
  });

  test('BlockedUser.fromJson profil özetini ayrıştırır', () {
    final user = BlockedUser.fromJson({
      'id': 'u2',
      'username': 'burak',
      'display_name': 'Burak',
      'avatar_path': null,
    });
    expect(user.userId, 'u2');
    expect(user.username, 'burak');
    expect(user.displayName, 'Burak');
    expect(user.avatarPath, isNull);
  });
}
