import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'failures.dart';

/// Testlerde repository'ler taklit edildiği için bu sağlayıcı yalnızca gerçek
/// repository'ler tarafından okunur.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Supabase/ağ hatalarını [AppFailure]'a çevirir. Zaten [AppFailure] ise aynen döner.
AppFailure toAppFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is SocketException ||
      error is TimeoutException ||
      error is AuthRetryableFetchException) {
    return AppFailure(AppFailureType.network, cause: error);
  }
  if (error is AuthException) {
    final type = switch (error.code) {
      'invalid_credentials' => AppFailureType.invalidCredentials,
      'email_not_confirmed' => AppFailureType.emailNotConfirmed,
      'weak_password' => AppFailureType.weakPassword,
      'same_password' => AppFailureType.samePassword,
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' => AppFailureType.rateLimited,
      _ => AppFailureType.unknown,
    };
    return AppFailure(type, cause: error);
  }
  if (error is StorageException && error.statusCode == '413') {
    return AppFailure(AppFailureType.fileTooLarge, cause: error);
  }
  if (error is PostgrestException && error.code == '23505') {
    return AppFailure(AppFailureType.usernameTaken, cause: error);
  }
  return AppFailure(AppFailureType.unknown, cause: error);
}
