import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'models.dart';

const _avatarBucket = 'avatars';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  StorageFileApi get _avatars => _client.storage.from(_avatarBucket);

  Future<Profile> fetchProfile(String userId) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(row);
  });

  /// Yeni avatar varsa önce yüklenir, sonra profil satırı güncellenir.
  Future<Profile> saveProfile(
    Profile current,
    ProfileEdit edit,
  ) => _guard(() async {
    String? newAvatarPath;
    final bytes = edit.avatarBytes;
    if (bytes != null) {
      // Her yüklemede yeni ad: aynı adres önbellekteki eski görseli gösterirdi.
      newAvatarPath =
          '${current.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _avatars.uploadBinary(
        newAvatarPath,
        Uint8List.fromList(bytes),
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
    }

    final row = await _client
        .from('profiles')
        .update({
          'username': edit.username,
          'display_name': edit.displayName.trim(),
          'bio': edit.bio.trim(),
          'country_code': edit.countryCode,
          'avatar_path': ?newAvatarPath,
        })
        .eq('id', current.id)
        .select()
        .single();

    final oldPath = current.avatarPath;
    if (newAvatarPath != null && oldPath != null) {
      await _removeOldAvatar(oldPath);
    }
    return Profile.fromJson(row);
  });

  String avatarUrl(String path) => _avatars.getPublicUrl(path);

  // Profil bu noktada kaydedilmiştir; eski dosya silinemese de kullanıcıya hata
  // gösterilmez. Artık dosya F16'da kullanıcının klasörüyle birlikte silinir.
  Future<void> _removeOldAvatar(String path) async {
    try {
      await _avatars.remove([path]);
    } on StorageException catch (error) {
      debugPrint('Eski avatar silinemedi ($path): $error');
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw toAppFailure(error);
    }
  }
}
