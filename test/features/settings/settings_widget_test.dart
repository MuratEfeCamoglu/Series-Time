import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/app_locale.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/auth/screens/sign_in_screen.dart';
import 'package:sezonluk/features/settings/screens/about_screen.dart';
import 'package:sezonluk/features/shows/logic.dart';
import 'package:sezonluk/features/settings/screens/color_settings_screen.dart';
import 'package:sezonluk/features/settings/screens/delete_account_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import 'package:sezonluk/theme/app_colors.dart';
import 'package:sezonluk/theme/app_palettes.dart';

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

  group('F21 görünüm', () {
    tearDown(() => AppColors.apply(AppPalette.yellow));

    testWidgets(
      'Renk: palet seçimi hemen uygulanır, saklanır ve ekran yerinde kalır (F21a)',
      (tester) async {
        final backend = await _openSettings(tester);
        await tester.tap(find.byKey(const Key('settings.colors')));
        await tester.pumpAndSettle();
        expect(find.byType(ColorSettingsScreen), findsOneWidget);
        expect(find.byKey(const Key('palette.orange')), findsOneWidget);

        await tester.tap(find.byKey(const Key('palette.purple')));
        await tester.pumpAndSettle();

        expect(AppColors.accent, AppPalette.purple.accent);
        expect(backend.preferences.getString('appearance.palette'), 'purple');
        expect(find.byType(ColorSettingsScreen), findsOneWidget);
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.theme!.colorScheme.primary, AppPalette.purple.accent);
        expect(
          tester
              .widget<ListTile>(find.byKey(const Key('palette.purple')))
              .selected,
          isTrue,
        );
      },
    );

    testWidgets('saklanan paletle açılır (F21a)', (tester) async {
      await TestBackend().pumpApp(
        tester,
        preferenceValues: {'appearance.palette': 'green'},
      );
      expect(AppColors.accent, AppPalette.green.accent);
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .scaffoldBackgroundColor,
        AppPalette.green.background,
      );
    });
  });

  group('F21 dil', () {
    tearDown(() => AppLocale.apply('tr'));

    testWidgets(
      'Dil: English seçilince arayüz hemen İngilizce olur ve saklanır (F21b)',
      (tester) async {
        final backend = await _openSettings(tester);
        await tester.tap(find.byKey(const Key('settings.language')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('language.en')));
        await tester.pumpAndSettle();

        expect(backend.preferences.getString('app.locale'), 'en');
        expect(find.text('Language'), findsOneWidget);
        expect(AppLocale.code, 'en');
        expect(episodeLabel(1, 5), 'S01 | E05');
      },
    );

    testWidgets('Sistem: telefon dili Türkçe değilse İngilizce açılır (F21b)', (
      tester,
    ) async {
      // Test cihazının dili İngilizcedir.
      await TestBackend().pumpApp(
        tester,
        preferenceValues: {'app.locale': 'system'},
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Discover'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Türkçe seçiliyken bölüm kodu "B" ile (F21b)', (tester) async {
      await TestBackend().pumpApp(tester);
      expect(AppLocale.code, 'tr');
      expect(episodeLabel(1, 5), 'S01 | B05');
    });
  });
}
