import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../auth/logic.dart';
import '../auth/providers.dart';
import 'data/models.dart';
import 'data/repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(supabaseClientProvider)),
);

/// Alt menüdeki Bildirimler sekmesinin sayacı (F13f).
final unreadCountProvider = FutureProvider<int>((ref) async {
  if (!isRegistered(ref.watch(authStatusProvider))) return 0;
  return ref.read(notificationsRepositoryProvider).fetchUnreadCount();
});

/// Zil ekranı: liste okunmadan önceki haliyle gösterilir (yeni olanlar vurgulu),
/// ardından hepsi okundu işaretlenir ve sayaç sıfırlanır (F13c).
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final repository = ref.read(notificationsRepositoryProvider);
    final items = await repository.fetchNotifications();
    if (items.any((n) => n.isUnread)) {
      await repository.markAllRead();
      ref.invalidate(unreadCountProvider);
    }
    return items;
  },
);

/// Bildirimler › Ben'deki kendi izlemeler (F13f); okunmamış sayacına girmez.
final myWatchFeedProvider = FutureProvider.autoDispose<List<MyWatchItem>>(
  (ref) => ref.read(notificationsRepositoryProvider).fetchMyWatchFeed(),
);
