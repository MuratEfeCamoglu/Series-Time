/// F13 saf kuralları: okunmamış sayısı ve zil rozeti metni.
library;

import 'data/models.dart';

int countUnread(List<AppNotification> items) =>
    items.where((n) => n.isUnread).length;

/// Zil rozetinde 99'dan büyük sayı "99+" olarak yazılır.
String unreadBadgeLabel(int count) => count > 99 ? '99+' : '$count';
