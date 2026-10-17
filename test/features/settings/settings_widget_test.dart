import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/auth/screens/sign_in_screen.dart';
import 'package:sezonluk/features/settings/screens/about_screen.dart';
import 'package:sezonluk/features/settings/screens/delete_account_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

Future<TestBackend> _openSettings(WidgetTester tester) async {
  final backend = TestBackend();
  await backend.pumpApp(tester);
  GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/settings');
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  group('F16 hesap silme', () {
    testWidgets(
      'kullanıcı adı yazılmadan düğme pasif; silince giriş ekranına dönülür',
      (tester) async {
        final backend = await _openSettings(tester);
        when(() => backend.auth.deleteAccount('ayse_1')).thenAnswer((_) async {
          // Gerçek repository yerel oturumu kapatır; yönlendirici buna tepki verir.
          backend.emit(AuthStatus.signedOut);
        });
        when(() => backend.auth.currentStatus).thenReturn(AuthStatus.signedOut);

        await tester.tap(find.byKey(const Key('settings.deleteAccount')));
        await tester.pumpAndSettle();
        expect(find.byType(DeleteAccountScreen), findsOneWidget);

        FilledButton submit() => tester.widget<FilledButton>(
          find.byKey(const Key('deleteAccount.submit')),
        );
        expect(submit().onPressed, isNull);

        await tester.enterText(
          find.byKey(const Key('deleteAccount.confirm')),
          'ayse',
        );
        await tester.pump();
        expect(submit().onPressed, isNull);

        await tester.enterText(
          find.byKey(const Key('deleteAccount.confirm')),
          'ayse_1',
        );
        await tester.pump();
        expect(submit().onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('deleteAccount.submit')));
        await tester.pumpAndSettle();

        verify(() => backend.auth.deleteAccount('ayse_1')).called(1);
        expect(find.byType(SignInScreen), findsOneWidget);
      },
    );

    testWidgets('silme başarısızsa hata gösterilir, ekranda kalınır', (
      tester,
    ) async {
      final backend = await _openSettings(tester);
      when(() => backend.auth.deleteAccount(any()))
          .thenThrow(const AppFailure(AppFailureType.network));

      await tester.tap(find.byKey(const Key('settings.deleteAccount')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('deleteAccount.confirm')),
        'ayse_1',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('deleteAccount.submit')));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteAccountScreen), findsOneWidget);
      expect(
        find.text(
          'İnternet bağlantısı yok. Bağlantını kontrol edip tekrar dene.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'Hakkında: TMDB logosu, atıf metni, yasal bağlantılar ve sürüm (F17)',
    (tester) async {
      await _openSettings(tester);
      await tester.tap(find.byKey(const Key('settings.about')));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(
        find.text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
        ),
        findsOneWidget,
      );
      final logo = tester.widget<Image>(find.byType(Image));
      expect(
        (logo.image as AssetImage).assetName,
        'assets/images/tmdb_logo.png',
      );
      expect(find.text('Gizlilik Politikası'), findsOneWidget);
      expect(find.text('Kullanım Şartları'), findsOneWidget);
      expect(find.text('Sürüm dev'), findsOneWidget);
    },
  );
}
