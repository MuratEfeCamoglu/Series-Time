import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import '../logic.dart';

/// E-posta bağlantıları uygulamayı bu adreslerle açar; `supabase/config.toml`
/// `additional_redirect_urls` listesinde olmaları gerekir.
const _signInRedirect = 'sezonluk://sign-in';
const _resetPasswordRedirect = 'sezonluk://reset-password';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  AuthStatus get currentStatus => _statusOf(_auth.currentSession);

  static AuthStatus _statusOf(Session? session) => switch (session) {
    null => AuthStatus.signedOut,
    _ when session.user.isAnonymous => AuthStatus.guest,
    _ => AuthStatus.signedIn,
  };

  String? get currentUserId => _auth.currentUser?.id;

  /// Şifre sıfırlama bağlantısı açıldığında `supabase_flutter` oturumu kurar ve
  /// `passwordRecovery` olayı yayar; bu olay ayrı bir durum olarak iletilir.
  Stream<AuthStatus> statusChanges() => _auth.onAuthStateChange.map(
    (state) => state.event == AuthChangeEvent.passwordRecovery
        ? AuthStatus.passwordRecovery
        : _statusOf(state.session),
  );

  /// F19: e-posta/şifre olmadan anonim oturum (panelde anonim giriş açık olmalı).
  Future<void> signInAsGuest() => _guard(_auth.signInAnonymously);

  // Misafir oturumu hesapla değiştirilirken önce kapatılır: misafirin taşınacak verisi yok
  // (F19e) ve yeni kayıt mevcut anonim kullanıcıya bağlanmasın.
  Future<void> _leaveGuestSession() async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      await _auth.signOut(scope: SignOutScope.local);
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _guard(() async {
        await _leaveGuestSession();
        await _auth.signInWithPassword(email: email.trim(), password: password);
      });

  /// Kullanıcı adı önce sorgulanır; çünkü kayıt tetikleyicisindeki benzersizlik
  /// hatası Auth'tan genel bir "veritabanı hatası" olarak döner.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) => _guard(() async {
    final available = await _client.rpc(
      'is_username_available',
      params: {'name': username},
    ) as bool;
    if (!available) throw const AppFailure(AppFailureType.usernameTaken);
    await _leaveGuestSession();
    await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': username},
      emailRedirectTo: _signInRedirect,
    );
  });

  Future<void> sendPasswordReset(String email) => _guard(
    () => _auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _resetPasswordRedirect,
    ),
  );

  Future<void> updatePassword(String newPassword) =>
      _guard(() => _auth.updateUser(UserAttributes(password: newPassword)));

  Future<void> signOut() => _guard(_auth.signOut);

  /// F16: `delete-account` hesabı, tüm satırları (cascade) ve avatarları siler. Sunucuda
  /// oturum kalmadığı için yalnızca cihazdaki oturum kapatılır; yönlendirici girişe döner.
  Future<void> deleteAccount(String confirmUsername) => _guard(() async {
    await _client.functions.invoke(
      'delete-account',
      body: {'confirmUsername': confirmUsername.trim()},
    );
    await _auth.signOut(scope: SignOutScope.local);
  });

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      throw toAppFailure(error);
    }
  }
}
