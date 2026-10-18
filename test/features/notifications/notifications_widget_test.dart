import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/badges/data/models.dart';
import 'package:sezonluk/features/badges/screens/badges_screen.dart';
import 'package:sezonluk/features/episode_feedback/screens/episode_screen.dart';
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

    // Takipçi sayısı başlıkta da görünür (F8c).
    expect(find.text('12'), findsNWidgets(2));
    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
    'sekmede okunmamış sayısı; Ben açılınca hepsi okundu ve sayaç sıfırlanır (F13c, F13f)',
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
      // Zil artık alt menüde (F13f); profilde zil yok.
      expect(find.byKey(const Key('profile.bell')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('nav.notifications')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      when(() => backend.notifications.fetchUnreadCount())
          .thenAnswer((_) async => 0);
      await tester.tap(_navLabel('Bildirimler'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('@burak seni takip etmeye başladı.'), findsOneWidget);
      expect(find.text('@cem yorumunu beğendi.'), findsOneWidget);
      expect(find.text('"İlk Bölüm" rozetini kazandın!'), findsOneWidget);
      verify(() => backend.notifications.markAllRead()).called(1);

      expect(
        find.descendant(
          of: find.byKey(const Key('nav.notifications')),
          matching: find.text('2'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('bildirim yoksa boş durum (F13d)', (tester) async {
    await _openProfile(tester);
    await tester.tap(_navLabel('Bildirimler'));
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

  testWidgets(
    'Arkadaşlar: izleme, puan ve rozet olayları; dokununca bölüm açılır (F13f)',
    (tester) async {
      final backend = await _openProfile(tester);
      when(() => backend.badges.fetchBadges()).thenAnswer(
        (_) async => const [
          BadgeInfo(
            code: 'first_episode',
            name: 'İlk Bölüm',
            description: 'koşul',
            icon: 'badge_first_episode',
          ),
        ],
      );
      when(() => backend.social.fetchFriendsFeed()).thenAnswer(
        (_) async => [
          FriendFeedItem(
            kind: FriendFeedKind.watched,
            userId: 'u2',
            username: 'burak',
            showId: 1399,
            showName: 'Taht Oyunları',
            episodeId: 100,
            seasonNumber: 1,
            episodeNumber: 3,
            episodeCount: 3,
            happenedAt: DateTime.utc(2026, 10, 18, 12),
          ),
          FriendFeedItem(
            kind: FriendFeedKind.rated,
            userId: 'u2',
            username: 'burak',
            showId: 1399,
            showName: 'Taht Oyunları',
            episodeId: 100,
            seasonNumber: 1,
            episodeNumber: 1,
            rating: 4.5,
            happenedAt: DateTime.utc(2026, 10, 18, 11),
          ),
          FriendFeedItem(
            kind: FriendFeedKind.badge,
            userId: 'u2',
            username: 'burak',
            badgeCode: 'first_episode',
            happenedAt: DateTime.utc(2026, 10, 18, 10),
          ),
        ],
      );
      await tester.tap(_navLabel('Bildirimler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arkadaşlar'));
      await tester.pumpAndSettle();

      expect(find.text('@burak 3 bölüm izledi: Taht Oyunları'), findsOneWidget);
      expect(
        find.text('@burak puan verdi: Taht Oyunları · S01 | B01 · 4,5 ★'),
        findsOneWidget,
      );
      expect(find.text('@burak "İlk Bölüm" rozetini kazandı'), findsOneWidget);

      await tester.tap(find.text('@burak 3 bölüm izledi: Taht Oyunları'));
      await tester.pumpAndSettle();
      expect(find.byType(EpisodeScreen), findsOneWidget);
    },
  );

  testWidgets('takip edilen yoksa Arkadaşlar boş durumu (F13f)', (
    tester,
  ) async {
    await _openProfile(tester);
    await tester.tap(_navLabel('Bildirimler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arkadaşlar'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Takip ettiğin kişilerin izlediği bölümler'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Ben: kendi izlemeler bildirimlerle zaman sırasında; sayaca girmez, dokununca bölüm açılır (F13f)',
    (tester) async {
      final backend = await _openProfile(
        tester,
        notifications: [
          AppNotification(
            id: 'n1',
            type: NotificationType.newFollower,
            actorUsername: 'burak',
            createdAt: DateTime.utc(2026, 10, 18, 11),
            readAt: DateTime.utc(2026, 10, 18, 11, 5),
          ),
        ],
      );
      when(() => backend.notifications.fetchMyWatchFeed()).thenAnswer(
        (_) async => [
          MyWatchItem(
            showId: 1399,
            showName: 'Taht Oyunları',
            episodeId: 100,
            seasonNumber: 1,
            episodeNumber: 3,
            episodeCount: 3,
            happenedAt: DateTime.utc(2026, 10, 18, 12),
          ),
          MyWatchItem(
            showId: 1399,
            showName: 'Taht Oyunları',
            episodeId: 99,
            seasonNumber: 1,
            episodeNumber: 1,
            happenedAt: DateTime.utc(2026, 10, 17, 9),
          ),
        ],
      );
      await tester.tap(_navLabel('Bildirimler'));
      await tester.pumpAndSettle();

      final many = find.text('3 bölüm izledin: Taht Oyunları');
      final follower = find.text('@burak seni takip etmeye başladı.');
      final one = find.text('İzledin: Taht Oyunları · S01 | B01');
      expect(many, findsOneWidget);
      expect(follower, findsOneWidget);
      expect(one, findsOneWidget);
      double y(Finder f) => tester.getTopLeft(f).dy;
      expect(y(many), lessThan(y(follower)));
      expect(y(follower), lessThan(y(one)));
      // İzlemeler okunmamış sayılmaz: sekme rozeti yok, okundu işaretlemesi gerekmez.
      verifyNever(() => backend.notifications.markAllRead());

      await tester.tap(many);
      await tester.pumpAndSettle();
      expect(find.byType(EpisodeScreen), findsOneWidget);
    },
  );

  testWidgets('dizi ve sezon rozeti bildirimi dizi adıyla yazılır (F14)', (
    tester,
  ) async {
    await _openProfile(
      tester,
      notifications: [
        AppNotification(
          id: 'n1',
          type: NotificationType.badgeEarned,
          entityId: 'show:1399:0',
          showName: 'Taht Oyunları',
          createdAt: DateTime.utc(2026, 10, 18, 12),
        ),
        AppNotification(
          id: 'n2',
          type: NotificationType.badgeEarned,
          entityId: 'show:1399:2',
          showName: 'Taht Oyunları',
          createdAt: DateTime.utc(2026, 10, 18, 11),
        ),
      ],
    );
    await tester.tap(_navLabel('Bildirimler'));
    await tester.pumpAndSettle();

    expect(
      find.text('"Taht Oyunları" dizisini bitirdin, rozetin hazır!'),
      findsOneWidget,
    );
    expect(
      find.text('"Taht Oyunları" 2. sezonunu bitirdin, rozetin hazır!'),
      findsOneWidget,
    );
  });

  testWidgets('profilde seçilen rozetler vitrinde görünür (F14)', (
    tester,
  ) async {
    final backend = TestBackend();
    when(() => backend.badges.fetchFeatured(testUserId)).thenAnswer(
      (_) async => const [
        FeaturedBadge(
          position: 1,
          showId: 1399,
          seasonNumber: 0,
          showName: 'Taht Oyunları',
        ),
        FeaturedBadge(position: 2, badgeCode: 'first_episode'),
      ],
    );
    tester.view
      ..physicalSize = const Size(800, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await backend.pumpApp(tester);
    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Rozet vitrini'), findsOneWidget);
    expect(find.byKey(const Key('showcase.show.1399.0')), findsOneWidget);
    expect(
      find.byKey(const Key('showcase.badge.first_episode')),
      findsOneWidget,
    );
  });
}
