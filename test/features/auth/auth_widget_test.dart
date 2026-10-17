import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/auth/screens/reset_password_screen.dart';
import 'package:sezonluk/features/auth/screens/sign_in_screen.dart';
import 'package:sezonluk/features/auth/screens/sign_up_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';
import 'package:sezonluk/shared/widgets/primary_button.dart';

import '../../helpers.dart';

void main() {
  testWidgets('oturum yoksa uygulama giriş ekranıyla açılır', (tester) async {
    await TestBackend(initialStatus: AuthStatus.signedOut).pumpApp(tester);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('oturum varsa Diziler sekmesiyle açılır (F1d)', (tester) async {
    await TestBackend().pumpApp(tester);

    expect(find.byType(ShowsScreen), findsOneWidget);
  });

  testWidgets('doğrulanmamış e-posta ile girişte uyarı görünür (F1c)', (
    tester,
  ) async {
    final backend = TestBackend(initialStatus: AuthStatus.signedOut);
    when(
      () => backend.auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AppFailure(AppFailureType.emailNotConfirmed));
    await backend.pumpApp(tester);

    await tester.enterText(find.byKey(const Key('signIn.email')), 'a@b.co');
    await tester.enterText(
      find.byKey(const Key('signIn.password')),
      '12345678',
    );
    await tester.tap(find.widgetWithText(PrimaryButton, 'Giriş yap'));
    await tester.pumpAndSettle();

    expect(find.textContaining('E-postanı doğrula'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('başarılı girişte Diziler sekmesine geçilir', (tester) async {
    final backend = TestBackend(initialStatus: AuthStatus.signedOut);
    when(
      () => backend.auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => backend.emit(AuthStatus.signedIn));
    await backend.pumpApp(tester);

    await tester.enterText(find.byKey(const Key('signIn.email')), 'a@b.co');
    await tester.enterText(
      find.byKey(const Key('signIn.password')),
      '12345678',
    );
    await tester.tap(find.widgetWithText(PrimaryButton, 'Giriş yap'));
    await tester.pumpAndSettle();

    expect(find.byType(ShowsScreen), findsOneWidget);
  });

  group('kayıt', () {
    Future<TestBackend> openSignUp(WidgetTester tester) async {
      final backend = TestBackend(initialStatus: AuthStatus.signedOut);
      await backend.pumpApp(tester);
      await tester.ensureVisible(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);
      return backend;
    }

    PrimaryButton submitButton(WidgetTester tester) =>
        tester.widget<PrimaryButton>(find.byKey(const Key('signUp.submit')));

    Future<void> fillForm(
      WidgetTester tester, {
      String username = 'Ayse_1',
    }) async {
      await tester.enterText(
        find.byKey(const Key('signUp.username')),
        username,
      );
      await tester.enterText(find.byKey(const Key('signUp.email')), 'a@b.co');
      await tester.enterText(
        find.byKey(const Key('signUp.password')),
        '12345678',
      );
    }

    testWidgets('onay kutusu işaretlenmeden "Kayıt ol" pasiftir (F1f)', (
      tester,
    ) async {
      await openSignUp(tester);
      await fillForm(tester);

      expect(submitButton(tester).onPressed, isNull);

      await tester.ensureVisible(find.byKey(const Key('signUp.consent')));
      await tester.tap(find.byKey(const Key('signUp.consent')));
      await tester.pump();
      expect(submitButton(tester).onPressed, isNotNull);
    });

    testWidgets(
      'kurala uymayan kullanıcı adı ve kısa şifre gönderilmez (F1a, F1b)',
      (tester) async {
        final backend = await openSignUp(tester);
        await fillForm(tester, username: 'ab');
        await tester.enterText(find.byKey(const Key('signUp.password')), '123');
        await tester.ensureVisible(find.byKey(const Key('signUp.consent')));
        await tester.tap(find.byKey(const Key('signUp.consent')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('signUp.submit')));
        await tester.tap(find.byKey(const Key('signUp.submit')));
        await tester.pumpAndSettle();

        expect(find.textContaining('3–20 karakter'), findsOneWidget);
        expect(find.text('Şifre en az 8 karakter olmalı.'), findsOneWidget);
        verifyNever(
          () => backend.auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          ),
        );
      },
    );

    testWidgets('alınmış kullanıcı adında hata görünür (F1a)', (tester) async {
      final backend = await openSignUp(tester);
      when(
        () => backend.auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          username: any(named: 'username'),
        ),
      ).thenThrow(const AppFailure(AppFailureType.usernameTaken));
      await fillForm(tester);
      await tester.ensureVisible(find.byKey(const Key('signUp.consent')));
      await tester.tap(find.byKey(const Key('signUp.consent')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('signUp.submit')));
      await tester.tap(find.byKey(const Key('signUp.submit')));
      await tester.pumpAndSettle();

      expect(find.text('Bu kullanıcı adı alınmış.'), findsOneWidget);
    });

    testWidgets(
      'başarılı kayıtta küçük harfli ad gönderilir ve doğrulama mesajı görünür',
      (tester) async {
        final backend = await openSignUp(tester);
        when(
          () => backend.auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          ),
        ).thenAnswer((_) async {});
        await fillForm(tester);
        await tester.ensureVisible(find.byKey(const Key('signUp.consent')));
        await tester.tap(find.byKey(const Key('signUp.consent')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('signUp.submit')));
        await tester.tap(find.byKey(const Key('signUp.submit')));
        await tester.pumpAndSettle();

        verify(
          () => backend.auth.signUp(
            email: 'a@b.co',
            password: '12345678',
            username: 'ayse_1',
          ),
        ).called(1);
        expect(find.textContaining('a@b.co adresine'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'şifre sıfırlama bağlantısı yeni şifre ekranını açar ve kayıttan sonra ana ekrana döner (F1e)',
    (tester) async {
      final backend = TestBackend(initialStatus: AuthStatus.signedOut);
      when(() => backend.auth.updatePassword(any())).thenAnswer((_) async {});
      await backend.pumpApp(tester);

      backend.emit(AuthStatus.passwordRecovery);
      await tester.pumpAndSettle();
      expect(find.byType(ResetPasswordScreen), findsOneWidget);

      // Belirteç yenilemesi ekranı kapatmamalı.
      backend.emit(AuthStatus.signedIn);
      await tester.pumpAndSettle();
      expect(find.byType(ResetPasswordScreen), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'yeni-sifre-1');
      await tester.enterText(fields.at(1), 'yeni-sifre-1');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Şifreyi kaydet'));
      await tester.pumpAndSettle();

      verify(() => backend.auth.updatePassword('yeni-sifre-1')).called(1);
      expect(find.byType(ShowsScreen), findsOneWidget);
    },
  );
}
