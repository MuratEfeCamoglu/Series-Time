import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import 'data/repository.dart';
import 'logic.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.statusChanges().listen(
      (incoming) => state = nextAuthStatus(state, incoming),
    );
    ref.onDispose(subscription.cancel);
    return repository.currentStatus;
  }

  /// Yeni şifre kaydedilince sıfırlama oturumu normal oturuma dönüşür.
  void passwordResetCompleted() => state = AuthStatus.signedIn;
}

final authStatusProvider = NotifierProvider<AuthStatusNotifier, AuthStatus>(
  AuthStatusNotifier.new,
);

/// F19: misafir yalnızca okur; yazma gerektiren yerler hesap çağrısı gösterir.
final isGuestProvider = Provider<bool>(
  (ref) => ref.watch(authStatusProvider) == AuthStatus.guest,
);
