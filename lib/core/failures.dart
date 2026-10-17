/// Repository'lerin fırlattığı tek hata türü. Ekranlar [type]'a göre kullanıcıya
/// gösterilecek metni `lib/l10n` içinden seçer; [cause] yalnızca hata ayıklama içindir.
enum AppFailureType {
  network,
  invalidCredentials,
  emailNotConfirmed,
  usernameTaken,
  weakPassword,
  samePassword,
  rateLimited,
  fileTooLarge,
  tmdbUnavailable,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.type, {this.cause});

  final AppFailureType type;
  final Object? cause;

  @override
  String toString() => 'AppFailure($type, cause: $cause)';
}
