import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/episode_feedback/screens/episode_screen.dart';
import 'package:sezonluk/features/profile/data/models.dart';
import 'package:sezonluk/features/profile/screens/user_shows_screen.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/tracking/data/models.dart';
import 'package:sezonluk/shared/widgets/poster_card.dart';

import '../../helpers.dart';

class _FakeProfileEdit extends Fake implements ProfileEdit {}

Finder _navLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

UserShow _entry(int id, {DateTime? watched, String? backdrop}) => UserShow(
  show: Show(id: id, name: 'Dizi $id', backdropPath: backdrop),
  addedAt: DateTime.utc(2026, 1, id),
  lastWatchedAt: watched,
);

Future<TestBackend> _openProfile(
  WidgetTester tester, {
  List<UserShow> myShows = const [],
  UserStats stats = const UserStats(watchedEpisodes: 0, watchMinutes: 0),
  List<WatchlistItem> watchlist = const [],
}) async {
  // Profil uzun bir sayfa; kartlar ve dizi satırı ilk ekranda çizilsin.
  tester.view
    ..physicalSize = const Size(800, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = TestBackend();
  when(() => backend.shows.fetchMyShows()).thenAnswer((_) async => myShows);
  when(() => backend.profiles.fetchStats(testUserId))
      .thenAnswer((_) async => stats);
  when(() => backend.tracking.fetchWatchlist())
      .thenAnswer((_) async => watchlist);
  await backend.pumpApp(tester);
  await tester.tap(_navLabel('Profil'));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  setUpAll(() {
    registerFallbackValue(testProfile);
    registerFallbackValue(_FakeProfileEdit());
  });

  testWidgets(
    'kapak 220 yüksekliğinde, zil ve sayılar görünür (F8a, F8b, F8f)',
    (tester) async {
      await _openProfile(tester);

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.expandedHeight, 220);
      expect(appBar.flexibleSpace, isA<FlexibleSpaceBar>());
      expect(
        (appBar.flexibleSpace! as FlexibleSpaceBar).collapseMode,
        CollapseMode.parallax,
      );
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('Takipçi'), findsOneWidget);
      expect(find.text('Takip'), findsOneWidget);
      expect(find.text('Rozet'), findsOneWidget);
    },
  );

  testWidgets('istatistik kartları süre ve bölüm sayısını gösterir (F8d)', (
    tester,
  ) async {
    await _openProfile(
      tester,
      stats: const UserStats(
        watchedEpisodes: 73,
        watchMinutes: 31 * 24 * 60 + 5 * 60,
      ),
    );

    expect(find.text('1 ay 1 gün 5 saat'), findsOneWidget);
    expect(find.text('73'), findsOneWidget);
  });

  testWidgets(
    '"Dizilerim" son izlenene göre sıralı; "Tümü" ızgarayı açar (F8e)',
    (tester) async {
      final shows = [
        _entry(1, watched: DateTime.utc(2026, 10, 1)),
        _entry(2),
        _entry(3, watched: DateTime.utc(2026, 10, 5)),
      ];
      final backend = await _openProfile(tester, myShows: shows);
      when(() => backend.profiles.fetchProfileByUsername('ayse_1'))
          .thenAnswer((_) async => testProfile);
      when(() => backend.shows.fetchUserShows(testUserId))
          .thenAnswer((_) async => shows);

      await tester.scrollUntilVisible(
        find.byKey(const Key('profile.seeAll')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final titles = tester
          .widgetList<PosterCard>(find.byType(PosterCard))
          .map((card) => card.title);
      expect(titles, ['Dizi 3', 'Dizi 1', 'Dizi 2']);

      await tester.tap(find.byKey(const Key('profile.seeAll')));
      await tester.pumpAndSettle();
      expect(find.byType(UserShowsScreen), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(PosterCard), findsNWidgets(3));
    },
  );

  testWidgets(
    'paylaş, sistem paylaşım menüsünü profil bağlantısıyla açar (F8g)',
    (tester) async {
      final calls = <MethodCall>[];
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await _openProfile(tester);

      await tester.tap(find.byKey(const Key('profile.share')));
      await tester.pumpAndSettle();

      expect(calls, isNotEmpty);
      expect(
        (calls.single.arguments as Map)['text'],
        contains('sezonluk://user/ayse_1'),
      );
    },
  );

  testWidgets(
    'bölüm işaretlendikten sonra profil güncel istatistiği çeker (F8h)',
    (tester) async {
      final backend = await _openProfile(
        tester,
        myShows: [_entry(1)],
        watchlist: [
          WatchlistItem(
            showId: 1,
            name: 'Dizi 1',
            addedAt: DateTime.utc(2026, 1, 1),
            nextEpisodeId: 100,
            nextSeasonNumber: 1,
            nextEpisodeNumber: 1,
            airedCount: 2,
            watchedCount: 0,
          ),
        ],
      );
      verify(() => backend.profiles.fetchStats(testUserId)).called(1);
      when(() => backend.tracking.markEpisode(episodeId: 100, showId: 1))
          .thenAnswer((_) async {});

      await tester.tap(_navLabel('Diziler'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchlist.layout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchlist.check.1')));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(EpisodeScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(_navLabel('Profil'));
      await tester.pumpAndSettle();

      verify(() => backend.profiles.fetchStats(testUserId)).called(1);
    },
  );

  testWidgets(
    'kapak listedeki bir dizinin arka planından seçilir ve kaydedilir (F2, V9)',
    (tester) async {
      final backend = await _openProfile(
        tester,
        myShows: [
          _entry(1, backdrop: '/b1.jpg'),
          _entry(2, backdrop: '/b2.jpg'),
        ],
      );
      when(() => backend.profiles.saveProfile(any(), any())).thenAnswer(
        (invocation) async => Profile(
          id: testUserId,
          username: 'ayse_1',
          displayName: 'Ayşe',
          bio: 'Dizi kurdu',
          countryCode: 'TR',
          coverShowId:
              (invocation.positionalArguments[1] as ProfileEdit).coverShowId,
          createdAt: testProfile.createdAt,
        ),
      );
      // Kapak seçilmemiş ve hiç izleme yok: kapak düz renk (V9).
      expect(find.byKey(const Key('profile.cover')), findsNothing);

      await tester.tap(find.text('Düzenle'));
      await tester.pumpAndSettle();
      expect(find.text('Otomatik'), findsOneWidget);
      await tester.tap(find.byKey(const Key('editProfile.cover')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cover.2')));
      await tester.pumpAndSettle();
      expect(find.text('Dizi 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editProfile.save')));
      await tester.pumpAndSettle();

      final edit =
          verify(() => backend.profiles.saveProfile(any(), captureAny()))
                  .captured
                  .single
              as ProfileEdit;
      expect(edit.coverShowId, 2);
      expect(find.byKey(const Key('profile.cover')), findsOneWidget);
    },
  );
}
