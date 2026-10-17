import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import '../../../core/tmdb_image.dart';
import '../logic.dart';
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

  Future<Profile> fetchProfileByUsername(String username) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('username', username)
        .single();
    return Profile.fromJson(row);
  });

  Future<UserStats> fetchStats(String userId) => _guard(() async {
    final rows = await _client.rpc(
      'get_user_stats',
      params: {'user_id': userId},
    ) as List;
    return UserStats.fromJson(rows.single as Map<String, dynamic>);
  });

  /// F8(l): kullanıcının puan dağılımı.
  Future<List<RatingCount>> fetchRatingDistribution(String userId) =>
      _guard(() async {
        final rows = await _client.rpc(
          'get_rating_distribution',
          params: {'user_id': userId},
        ) as List;
        return [
          for (final row in rows)
            RatingCount.fromJson(row as Map<String, dynamic>),
        ];
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
          '${current.id}/${DateTime.now().millisecondsSinceEpoch}.png';
      await _avatars.uploadBinary(
        newAvatarPath,
        Uint8List.fromList(bytes),
        fileOptions: const FileOptions(contentType: 'image/png'),
      );
    }

    final row = await _client
        .from('profiles')
        .update({
          'username': edit.username,
          'display_name': edit.displayName.trim(),
          'bio': edit.bio.trim(),
          'country_code': edit.countryCode,
          'cover_show_id': edit.coverShowId,
          'cover_path': edit.coverPath,
          'letterboxd_username': edit.letterboxdUsername,
          'instagram_username': edit.instagramUsername,
          'avatar_path': ?newAvatarPath,
        })
        .eq('id', current.id)
        .select()
        .single();

    final oldPath = current.avatarPath;
    // Eski sürümün TMDB avatarı Storage'da dosya değildir; yalnızca yüklenmiş dosya silinir.
    if (newAvatarPath != null && oldPath != null && !isTmdbAvatar(oldPath)) {
      await _removeOldAvatar(oldPath);
    }
    return Profile.fromJson(row);
  });

  /// Avatar adresi: TMDB karakter fotoğrafı veya Storage'daki yüklenmiş görsel.
  String avatarUrl(String path) => isTmdbAvatar(path)
      ? tmdbImageUrl(fromTmdbAvatarPath(path), TmdbImageSize.w185)!
      : _avatars.getPublicUrl(path);

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
