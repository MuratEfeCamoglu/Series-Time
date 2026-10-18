import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'models.dart';

/// F13: uygulama içi bildirimler (veritabanı tetikleyicileri üretir).
class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchNotifications() => _guard(() async {
    final rows = await _client.rpc('get_notifications') as List;
    return [
      for (final row in rows)
        AppNotification.fromJson(row as Map<String, dynamic>),
    ];
  });

  /// F13(f): Bildirimler › Ben'deki kendi izlemeler (son 90 gün).
  Future<List<MyWatchItem>> fetchMyWatchFeed() => _guard(() async {
    final rows = await _client.rpc('get_my_watch_feed') as List;
    return [
      for (final row in rows) MyWatchItem.fromJson(row as Map<String, dynamic>),
    ];
  });

  /// F8(b) zil sayacı.
  Future<int> fetchUnreadCount() => _guard(() async {
    final response = await _client
        .from('notifications')
        .select('id')
        .isFilter('read_at', null)
        .count(CountOption.exact);
    return response.count;
  });

  /// F13(c): zil ekranı açılınca hepsi okundu.
  Future<void> markAllRead() => _guard(() async {
    await _client.rpc('mark_notifications_read');
  });

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
