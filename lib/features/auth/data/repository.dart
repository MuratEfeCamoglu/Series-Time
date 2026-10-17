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

  AuthStatus get currentStatus =>
      _auth.currentSession == null ? AuthStatus.signedOut : AuthStatus.signedIn;

  String? get currentUserId => _auth.currentUser?.id;

  /// Şifre sıfırlama bağlantısı açıldığında `supabase_flutter` oturumu kurar ve
  /// `passwordRecovery` olayı yayar; bu olay ayrı bir durum olarak iletilir.
  Stream<AuthStatus> statusChanges() => _auth.onAuthStateChange.map(
    (state) => state.event == AuthChangeEvent.passwordRecovery
        ? AuthStatus.passwordRecovery
        : state.session == null
        ? AuthStatus.signedOut
        : AuthStatus.signedIn,
  );

  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithPassword(email: email.trim(), password: password),
      );

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

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      throw toAppFailure(error);
    }
  }
}
