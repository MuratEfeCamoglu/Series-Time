import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/badges/data/models.dart';
import 'package:sezonluk/features/badges/screens/badges_screen.dart';
import 'package:sezonluk/features/notifications/data/models.dart';
import 'package:sezonluk/features/notifications/screens/notifications_screen.dart';
import 'package:sezonluk/features/social/data/models.dart';

import '../../helpers.dart';

Finder _navLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

Future<TestBackend> _openProfile(
  WidgetTester tester, {
  int unread = 0,
  List<AppNotification> notifications = const [],
  ProfileCounts counts = const ProfileCounts(
    followers: 0,
    following: 0,
    badges: 0,
  ),
}) async {
  tester.view
    ..physicalSize = const Size(800, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = TestBackend();
  when(() => backend.notifications.fetchUnreadCount())
      .thenAnswer((_) async => unread);
  when(() => backend.notifications.fetchNotifications())
      .thenAnswer((_) async => notifications);
  when(() => backend.social.fetchCounts(testUserId))
      .thenAnswer((_) async => counts);
  await backend.pumpApp(tester);
  await tester.tap(_navLabel('Profil'));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('profildeki sayılar gerçek veriden gelir (F8f)', (tester) async {
    await _openProfile(
      tester,
      counts: const ProfileCounts(followers: 12, following: 7, badges: 3),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
    'zilde okunmamış sayısı; ekran açılınca hepsi okundu ve sayaç sıfırlanır (F8b, F13c)',
    (tester) async {
      final backend = await _openProfile(
        tester,
        unread: 2,
        notifications: [
          AppNotification(
            id: 'n1',
            type: NotificationType.newFollower,
            actorUsername: 'burak',
            createdAt: DateTime.utc(2026, 10, 17, 12),
          ),
          AppNotification(
            id: 'n2',
            type: NotificationType.commentLiked,
            actorUsername: 'cem',
            entityId: 'c1',
            episodeId: 100,
            createdAt: DateTime.utc(2026, 10, 17, 11),
          ),
          AppNotification(
            id: 'n3',
            type: NotificationType.badgeEarned,
            entityId: 'first_episode',
            badgeName: 'İlk Bölüm',
            createdAt: DateTime.utc(2026, 10, 17, 10),
            readAt: DateTime.utc(2026, 10, 17, 10, 5),
          ),
        ],
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('profile.bell')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      when(() => backend.notifications.fetchUnreadCount())
          .thenAnswer((_) async => 0);
      await tester.tap(find.byKey(const Key('profile.bell')));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('@burak seni takip etmeye başladı.'), findsOneWidget);
      expect(find.text('@cem yorumunu beğendi.'), findsOneWidget);
      expect(find.text('"İlk Bölüm" rozetini kazandın!'), findsOneWidget);
      verify(() => backend.notifications.markAllRead()).called(1);

      Navigator.of(tester.element(find.byType(NotificationsScreen))).pop();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('profile.bell')),
          matching: find.text('2'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('bildirim yoksa boş durum (F13d)', (tester) async {
    await _openProfile(tester);
    await tester.tap(find.byKey(const Key('profile.bell')));
    await tester.pumpAndSettle();

    expect(find.text('Son 90 günde bildirim yok.'), findsOneWidget);
  });

  testWidgets(
    'rozet ekranı kazanılanı renkli tarihle, kazanılmayanı koşuluyla gösterir (F14)',
    (tester) async {
      final backend = await _openProfile(
        tester,
        counts: const ProfileCounts(followers: 0, following: 0, badges: 1),
      );
      when(() => backend.badges.fetchBadges()).thenAnswer(
        (_) async => const [
          BadgeInfo(
            code: 'shows_10',
            name: 'Koleksiyoncu',
            description: 'Listene 10 dizi ekle.',
            icon: 'badge_shows_10',
          ),
          BadgeInfo(
            code: 'first_episode',
            name: 'İlk Bölüm',
            description: 'İlk bölümünü izlendi olarak işaretle.',
            icon: 'badge_first_episode',
          ),
        ],
      );
      when(() => backend.badges.fetchEarned(testUserId)).thenAnswer(
        (_) async => [
          EarnedBadge(
            code: 'first_episode',
            earnedAt: DateTime.utc(2026, 10, 17, 10),
          ),
        ],
      );

      await tester.tap(find.byKey(const Key('profile.badges')));
      await tester.pumpAndSettle();

      expect(find.byType(BadgesScreen), findsOneWidget);
      expect(find.text('17 Ekim 2026 tarihinde kazanıldı'), findsOneWidget);
      expect(find.text('Listene 10 dizi ekle.'), findsOneWidget);
      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data);
      expect(titles, ['İlk Bölüm', 'Koleksiyoncu']);
    },
  );
}
