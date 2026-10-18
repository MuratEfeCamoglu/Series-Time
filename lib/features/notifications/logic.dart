/// F13 saf kuralları: okunmamış sayısı, zil rozeti metni ve Ben listesinin birleştirilmesi.
library;

import 'data/models.dart';

int countUnread(List<AppNotification> items) =>
    items.where((n) => n.isUnread).length;

/// Zil rozetinde 99'dan büyük sayı "99+" olarak yazılır.
String unreadBadgeLabel(int count) => count > 99 ? '99+' : '$count';

/// Bildirimler › Ben listesinin bir satırı: bildirim ya da kendi izlemen (F13f).
sealed class MeFeedEntry {
  const MeFeedEntry();

  DateTime get time;
}

final class NotificationEntry extends MeFeedEntry {
  const NotificationEntry(this.notification);

  final AppNotification notification;

  @override
  DateTime get time => notification.createdAt;
}

final class WatchEntry extends MeFeedEntry {
  const WatchEntry(this.watch);

  final MyWatchItem watch;

  @override
  DateTime get time => watch.happenedAt;
}

/// Bildirimler ve kendi izlemeler zamana göre en yeniden eskiye tek listede.
/// Aynı anda olanlarda bildirim önce gelir; sıralama kararlıdır.
List<MeFeedEntry> mergeMeFeed(
  List<AppNotification> notifications,
  List<MyWatchItem> watches,
) {
  final entries = <MeFeedEntry>[
    for (final n in notifications) NotificationEntry(n),
    for (final w in watches) WatchEntry(w),
  ];
  final indexed = entries.indexed.toList()
    ..sort((a, b) {
      final byTime = b.$2.time.compareTo(a.$2.time);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return [for (final (_, entry) in indexed) entry];
}
