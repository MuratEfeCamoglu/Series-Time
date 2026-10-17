/// F1 saf kuralları: alan doğrulama ve oturuma göre yönlendirme.
library;

/// [guest]: hesapsız (anonim) oturum, yalnızca okuma (F19).
enum AuthStatus { signedOut, signedIn, passwordRecovery, guest }

/// Hesabı olan oturum: kullanıcı verisi (liste, profil, bildirim) yalnızca bunlarda çekilir.
bool isRegistered(AuthStatus status) =>
    status == AuthStatus.signedIn || status == AuthStatus.passwordRecovery;

/// Yönlendirmenin hedefi; yollar `lib/app/router.dart` içinde eşlenir.
enum AuthRedirect { none, signIn, home, resetPassword }

final _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');
// Sunucu (Supabase Auth) asıl doğrulamayı yapar; burada yalnızca bariz yazım hataları yakalanır.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

const minPasswordLength = 8;

String normalizeUsername(String input) => input.trim().toLowerCase();

bool isValidUsername(String username) => _usernamePattern.hasMatch(username);

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

bool isValidPassword(String password) => password.length >= minPasswordLength;

/// Sıfırlama bağlantısıyla gelen oturum, yeni şifre kaydedilene kadar "giriş
/// yapılmış" sayılmaz; aksi halde belirteç yenilemesi kullanıcıyı ekrandan atar.
AuthStatus nextAuthStatus(AuthStatus current, AuthStatus incoming) =>
    current == AuthStatus.passwordRecovery && incoming == AuthStatus.signedIn
    ? AuthStatus.passwordRecovery
    : incoming;

/// [isAuthRoute]: giriş, kayıt, şifremi unuttum ekranları.
/// [isResetRoute]: yeni şifre ekranı; yalnızca şifre sıfırlama bağlantısıyla açılır.
AuthRedirect authRedirect({
  required AuthStatus status,
  required bool isAuthRoute,
  required bool isResetRoute,
}) {
  switch (status) {
    case AuthStatus.passwordRecovery:
      return isResetRoute ? AuthRedirect.none : AuthRedirect.resetPassword;
    case AuthStatus.signedOut:
      return isAuthRoute ? AuthRedirect.none : AuthRedirect.signIn;
    case AuthStatus.signedIn:
      return isAuthRoute || isResetRoute
          ? AuthRedirect.home
          : AuthRedirect.none;
    case AuthStatus.guest:
      // Misafir hesap açmak veya giriş yapmak için giriş/kayıt ekranlarına gidebilir.
      return isResetRoute ? AuthRedirect.home : AuthRedirect.none;
  }
}
