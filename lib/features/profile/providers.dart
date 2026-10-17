import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/failures.dart';
import '../../core/supabase_client.dart';
import '../auth/logic.dart';
import '../auth/providers.dart';
import '../shows/data/models.dart';
import '../shows/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

/// Oturum sahibinin profili. Kaydetme sonrası state doğrudan güncellenir, böylece
/// profil ekranı yenileme gerekmeden yeni değeri gösterir (F2).
class MyProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() {
    // Oturum değişince (çıkış/başka hesapla giriş) profil yeniden yüklenir.
    final status = ref.watch(authStatusProvider);
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (status == AuthStatus.signedOut || userId == null) {
      throw const AppFailure(AppFailureType.unknown);
    }
    return ref.read(profileRepositoryProvider).fetchProfile(userId);
  }

  Future<void> save(ProfileEdit edit) async {
    final current = await future;
    final updated = await ref
        .read(profileRepositoryProvider)
        .saveProfile(current, edit);
    state = AsyncData(updated);
  }
}

final myProfileProvider = AsyncNotifierProvider<MyProfileNotifier, Profile>(
  MyProfileNotifier.new,
);

/// F8(d) istatistikleri. Profil her açıldığında ve her işaretlemeden sonra yeniden
/// hesaplanır (F8h); işaretleme sağlayıcıları bu aileyi geçersiz kılar.
final userStatsProvider = FutureProvider.autoDispose.family<UserStats, String>(
  (ref, userId) => ref.watch(profileRepositoryProvider).fetchStats(userId),
);

final profileByUsernameProvider = FutureProvider.autoDispose
    .family<Profile, String>(
      (ref, username) =>
          ref.watch(profileRepositoryProvider).fetchProfileByUsername(username),
    );

/// "Tümü" ekranı: kullanıcının tüm dizileri, son izlenene göre (F8e).
final userShowsProvider = FutureProvider.autoDispose
    .family<List<UserShow>, String>(
      (ref, userId) =>
          ref.watch(showsRepositoryProvider).fetchUserShows(userId),
    );
