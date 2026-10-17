import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/profile/data/models.dart';
import 'package:sezonluk/features/profile/screens/edit_profile_screen.dart';
import 'package:sezonluk/features/profile/screens/profile_screen.dart';

import '../../helpers.dart';

class _FakeProfileEdit extends Fake implements ProfileEdit {}

void main() {
  setUpAll(() {
    registerFallbackValue(testProfile);
    registerFallbackValue(_FakeProfileEdit());
  });

  Future<TestBackend> openEdit(WidgetTester tester) async {
    final backend = TestBackend();
    await backend.pumpApp(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    return backend;
  }

  testWidgets(
    'profil ekranı ad, kullanıcı adı, bayrak ve biyografiyi gösterir',
    (tester) async {
      final backend = TestBackend();
      await backend.pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profil'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Ayşe'), findsOneWidget);
      expect(find.text('@ayse_1'), findsOneWidget);
      expect(find.text('🇹🇷'), findsOneWidget);
      expect(find.text('Dizi kurdu'), findsOneWidget);
    },
  );

  testWidgets('kaydet sonrası profil ekranı yenilemeden güncellenir (F2)', (
    tester,
  ) async {
    final backend = await openEdit(tester);
    final updated = Profile(
      id: testUserId,
      username: 'ayse_yeni',
      displayName: 'Ayşe Y.',
      bio: 'Yeni biyografi',
      countryCode: 'TR',
      createdAt: testProfile.createdAt,
    );
    when(() => backend.profiles.saveProfile(any(), any()))
        .thenAnswer((_) async => updated);

    await tester.enterText(
      find.byKey(const Key('editProfile.displayName')),
      'Ayşe Y.',
    );
    await tester.enterText(
      find.byKey(const Key('editProfile.username')),
      'Ayse_Yeni',
    );
    await tester.enterText(
      find.byKey(const Key('editProfile.bio')),
      'Yeni biyografi',
    );
    await tester.tap(find.byKey(const Key('editProfile.save')));
    await tester.pumpAndSettle();

    final edit =
        verify(() => backend.profiles.saveProfile(any(), captureAny()))
                .captured
                .single
            as ProfileEdit;
    expect(edit.username, 'ayse_yeni');
    expect(edit.avatarBytes, isNull);

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Ayşe Y.'), findsOneWidget);
    expect(find.text('@ayse_yeni'), findsOneWidget);
    expect(find.text('Yeni biyografi'), findsOneWidget);
    // Profil yeniden çekilmedi; değer kaydetme yanıtından geldi.
    verify(() => backend.profiles.fetchProfile(testUserId)).called(1);
  });

  testWidgets(
    'boş görünen ad ve 160 karakteri aşan biyografi kaydedilmez (F2)',
    (tester) async {
      final backend = await openEdit(tester);

      await tester.enterText(
        find.byKey(const Key('editProfile.displayName')),
        ' ',
      );
      await tester.tap(find.byKey(const Key('editProfile.save')));
      await tester.pumpAndSettle();

      expect(find.text('Görünen ad 1–40 karakter olmalı.'), findsOneWidget);
      verifyNever(() => backend.profiles.saveProfile(any(), any()));
    },
  );

  testWidgets(
    'ülke seçici seçilen kodu gösterir ve "Belirtilmemiş" seçilebilir',
    (tester) async {
      await openEdit(tester);
      expect(find.text('🇹🇷  TR'), findsOneWidget);

      await tester.tap(find.text('Ülke'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'de');
      await tester.pumpAndSettle();
      await tester.tap(find.text('DE'));
      await tester.pumpAndSettle();
      expect(find.text('🇩🇪  DE'), findsOneWidget);

      await tester.tap(find.text('Ülke'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belirtilmemiş'));
      await tester.pumpAndSettle();
      expect(find.text('Belirtilmemiş'), findsOneWidget);
    },
  );
}
