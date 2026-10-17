import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/auth/logic.dart';

void main() {
  group('isValidUsername (F1a)', () {
    test('kurala uyan adları kabul eder', () {
      expect(isValidUsername('abc'), isTrue);
      expect(isValidUsername('ayse_1990'), isTrue);
      expect(isValidUsername('a' * 20), isTrue);
    });

    test('kısa, uzun, büyük harfli veya özel karakterli adları reddeder', () {
      expect(isValidUsername('ab'), isFalse);
      expect(isValidUsername('a' * 21), isFalse);
      expect(isValidUsername('Ayse'), isFalse);
      expect(isValidUsername('ayşe'), isFalse);
      expect(isValidUsername('ay se'), isFalse);
      expect(isValidUsername('ay-se'), isFalse);
    });

    test('normalizeUsername boşlukları kırpar ve küçük harfe çevirir', () {
      expect(normalizeUsername('  Ayse_1 '), 'ayse_1');
      expect(isValidUsername(normalizeUsername(' Burak ')), isTrue);
    });
  });

  test('isValidPassword en az 8 karakter ister (F1b)', () {
    expect(isValidPassword('1234567'), isFalse);
    expect(isValidPassword('12345678'), isTrue);
  });

  test('isValidEmail bariz hatalı adresleri reddeder', () {
    expect(isValidEmail('a@b.co'), isTrue);
    expect(isValidEmail(' a@b.co '), isTrue);
    expect(isValidEmail('a@b'), isFalse);
    expect(isValidEmail('ab.co'), isFalse);
    expect(isValidEmail(''), isFalse);
  });

  group('nextAuthStatus', () {
    test('sıfırlama oturumu belirteç yenilemesiyle girişe dönmez', () {
      expect(
        nextAuthStatus(AuthStatus.passwordRecovery, AuthStatus.signedIn),
        AuthStatus.passwordRecovery,
      );
    });

    test('sıfırlama sırasında çıkış yapılırsa çıkış durumuna geçer', () {
      expect(
        nextAuthStatus(AuthStatus.passwordRecovery, AuthStatus.signedOut),
        AuthStatus.signedOut,
      );
    });

    test('diğer durumlarda gelen değer geçerlidir', () {
      expect(
        nextAuthStatus(AuthStatus.signedOut, AuthStatus.signedIn),
        AuthStatus.signedIn,
      );
      expect(
        nextAuthStatus(AuthStatus.signedIn, AuthStatus.passwordRecovery),
        AuthStatus.passwordRecovery,
      );
    });
  });

  group('authRedirect', () {
    AuthRedirect redirect(
      AuthStatus status, {
      bool auth = false,
      bool reset = false,
    }) => authRedirect(status: status, isAuthRoute: auth, isResetRoute: reset);

    test('oturum yoksa korumalı ekranlar girişe yönlenir', () {
      expect(redirect(AuthStatus.signedOut), AuthRedirect.signIn);
      expect(redirect(AuthStatus.signedOut, reset: true), AuthRedirect.signIn);
      expect(redirect(AuthStatus.signedOut, auth: true), AuthRedirect.none);
    });

    test('oturum açıksa giriş ekranlarından ana ekrana yönlenir', () {
      expect(redirect(AuthStatus.signedIn, auth: true), AuthRedirect.home);
      expect(redirect(AuthStatus.signedIn, reset: true), AuthRedirect.home);
      expect(redirect(AuthStatus.signedIn), AuthRedirect.none);
    });

    test(
      'şifre sıfırlama bağlantısı yeni şifre ekranını zorunlu kılar (F1e)',
      () {
        expect(
          redirect(AuthStatus.passwordRecovery),
          AuthRedirect.resetPassword,
        );
        expect(
          redirect(AuthStatus.passwordRecovery, auth: true),
          AuthRedirect.resetPassword,
        );
        expect(
          redirect(AuthStatus.passwordRecovery, reset: true),
          AuthRedirect.none,
        );
      },
    );

    test(
      'misafir uygulamada kalır, giriş/kayıt ekranlarına gidebilir (F19)',
      () {
        expect(redirect(AuthStatus.guest), AuthRedirect.none);
        expect(redirect(AuthStatus.guest, auth: true), AuthRedirect.none);
        expect(redirect(AuthStatus.guest, reset: true), AuthRedirect.home);
      },
    );
  });

  test('yalnızca hesabı olan oturum kullanıcı verisi çeker (F19)', () {
    expect(isRegistered(AuthStatus.signedIn), isTrue);
    expect(isRegistered(AuthStatus.passwordRecovery), isTrue);
    expect(isRegistered(AuthStatus.guest), isFalse);
    expect(isRegistered(AuthStatus.signedOut), isFalse);
  });
}
