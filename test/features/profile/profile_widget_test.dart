import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/profile/data/models.dart';
import 'package:sezonluk/features/profile/logic.dart';
import 'package:sezonluk/features/profile/screens/user_shows_screen.dart';
import 'package:sezonluk/features/profile/widgets/avatar_crop_view.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/tracking/data/models.dart';
import 'package:sezonluk/shared/widgets/poster_card.dart';
import 'package:sezonluk/shared/widgets/progress_bar.dart';

import '../../helpers.dart';

class _FakeProfileEdit extends Fake implements ProfileEdit {}

Finder _navLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

UserShow _entry(int id, {DateTime? watched, String? backdrop}) => UserShow(
  show: Show(id: id, name: 'Dizi $id', backdropPath: backdrop),
  addedAt: DateTime.utc(2026, 1, id),
  lastWatchedAt: watched,
);

ShowProgress _progressOf(UserShow entry, {int watched = 0}) => ShowProgress(
  showId: entry.show.id,
  name: entry.show.name,
  addedAt: entry.addedAt,
  lastWatchedAt: entry.lastWatchedAt,
  airedCount: 10,
  watchedCount: watched,
  showStatus: 'Ended',
);

Future<TestBackend> _openProfile(
  WidgetTester tester, {
  Profile? profile,
  List<UserShow> myShows = const [],
  List<ShowProgress>? progress,
  List<RecentEpisode> recent = const [],
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
  if (profile != null) {
    when(() => backend.profiles.fetchProfile(testUserId))
        .thenAnswer((_) async => profile);
  }
  // get_user_show_progress son izlenene göre sıralı döner.
  when(() => backend.tracking.fetchShowProgress(testUserId)).thenAnswer(
    (_) async =>
        progress ??
        [for (final e in sortByLastWatched(myShows)) _progressOf(e)],
  );
  when(() => backend.tracking.fetchRecentActivity(testUserId))
      .thenAnswer((_) async => recent);
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
    'soluk kapaklı başlık: solda avatar, sağında ad, tarih ve takipçi (F8a, F8c, F8f)',
    (tester) async {
      await _openProfile(tester);

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.pinned, isTrue);
      expect(appBar.flexibleSpace, isA<FlexibleSpaceBar>());
      expect(
        (appBar.flexibleSpace! as FlexibleSpaceBar).collapseMode,
        CollapseMode.parallax,
      );
      final avatar = tester.getRect(find.byKey(const Key('profile.avatar')));
      expect(avatar.left, lessThan(800 / 4));
      expect(
        tester.getTopLeft(find.text('Ayşe')).dx,
        greaterThan(avatar.right),
      );
      expect(find.text('@ayse_1'), findsOneWidget);
      expect(find.text('1 Ekim 2026 tarihinden beri'), findsOneWidget);
      expect(find.byKey(const Key('profile.headerFollowers')), findsOneWidget);
      // Paylaş ve Ayarlar üst çubukta; "Düzenle" yalnızca Ayarlar'da.
      expect(find.byKey(const Key('profile.edit')), findsNothing);
      expect(find.text('Düzenle'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SliverAppBar),
          matching: find.byKey(const Key('profile.settings')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SliverAppBar),
          matching: find.byKey(const Key('profile.share')),
        ),
        findsOneWidget,
      );
      // Zil Bildirimler sekmesine taşındı (F13f).
      expect(find.byKey(const Key('profile.bell')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Rozet'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Takipçi'), findsOneWidget);
      expect(find.text('Takip'), findsOneWidget);
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
    'bölüm sırası: Favoriler, Şu an izlediklerim, Son etkinlik, Dizilerim (F8e, F8j, F8k)',
    (tester) async {
      final shows = [
        _entry(1, watched: DateTime.utc(2026, 10, 1)),
        _entry(2, watched: DateTime.utc(2026, 10, 5)),
        _entry(3),
      ];
      final backend = await _openProfile(
        tester,
        myShows: shows,
        progress: [
          ShowProgress(
            showId: 2,
            name: 'Dizi 2',
            addedAt: DateTime.utc(2026),
            lastWatchedAt: DateTime.utc(2026, 10, 5),
            airedCount: 10,
            watchedCount: 3,
            showStatus: 'Ended',
          ),
          ShowProgress(
            showId: 1,
            name: 'Dizi 1',
            addedAt: DateTime.utc(2026),
            lastWatchedAt: DateTime.utc(2026, 10, 1),
            airedCount: 10,
            watchedCount: 10,
            showStatus: 'Ended',
            isFavorite: true,
          ),
          _progressOf(shows[2]),
        ],
        recent: [
          RecentEpisode(
            episodeId: 200,
            showId: 2,
            showName: 'Dizi 2',
            seasonNumber: 1,
            episodeNumber: 3,
            watchedAt: DateTime.utc(2026, 10, 5),
          ),
        ],
      );
      when(() => backend.profiles.fetchProfileByUsername('ayse_1'))
          .thenAnswer((_) async => testProfile);

      double y(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(y('Favori diziler'), lessThan(y('Şu an izlediklerim')));
      expect(y('Şu an izlediklerim'), lessThan(y('Son etkinlik')));
      expect(y('Son etkinlik'), lessThan(y('Dizilerim')));
      expect(find.byKey(const Key('profile.favorite.1')), findsOneWidget);
      expect(find.byKey(const Key('profile.favorite.2')), findsNothing);
      expect(find.byKey(const Key('profile.recent.200')), findsOneWidget);
      expect(find.text('S01 | B03'), findsOneWidget);

      // "Tümü" ekranı Devam ediyor grubuyla süzülü açılır.
      await tester.tap(find.byKey(const Key('profile.seeAll')));
      await tester.pumpAndSettle();
      expect(find.byType(UserShowsScreen), findsOneWidget);
      expect(
        tester
            .widgetList<PosterCard>(find.byType(PosterCard))
            .map((c) => c.title),
        ['Dizi 2'],
      );
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
      await tester.tap(find.byKey(const Key('layout.grid')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchlist.check.1')));
      await tester.pumpAndSettle();
      await tester.tap(_navLabel('Profil'));
      await tester.pumpAndSettle();

      verify(() => backend.profiles.fetchStats(testUserId)).called(1);
    },
  );

  testWidgets(
    'kapak bir dizinin arka plan görsellerinden seçilir ve kaydedilir (F2, V9)',
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
          coverPath:
              (invocation.positionalArguments[1] as ProfileEdit).coverPath,
          createdAt: testProfile.createdAt,
        ),
      );
      // Kapak seçilmemiş ve hiç izleme yok: kapak düz renk (V9).
      expect(find.byKey(const Key('profile.cover')), findsNothing);

      // Profili düzenleme yalnızca Ayarlar'dan açılır.
      await tester.tap(find.byKey(const Key('profile.settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profili düzenle'));
      await tester.pumpAndSettle();
      expect(find.text('Otomatik'), findsOneWidget);
      await tester.tap(find.byKey(const Key('editProfile.cover')));
      await tester.pumpAndSettle();
      when(() => backend.shows.fetchShowImages(2)).thenAnswer(
        (_) async => const ShowImages(
          backdrops: ['/arka1.jpg', '/arka2.jpg'],
          posters: ['/afis.jpg'],
        ),
      );
      await tester.tap(find.byKey(const Key('showChooser.2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cover.image.1')));
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
      expect(edit.coverPath, '/arka2.jpg');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile.cover')), findsOneWidget);
    },
  );

  testWidgets(
    'avatar bir dizinin arka plan ve afişlerinden seçilip kırpmaya gider (F2)',
    (tester) async {
      final backend = await _openProfile(tester, myShows: [_entry(1)]);
      when(() => backend.shows.fetchShowImages(1)).thenAnswer(
        (_) async =>
            const ShowImages(backdrops: ['/arka.jpg'], posters: ['/afis.jpg']),
      );

      // Profili düzenleme yalnızca Ayarlar'dan açılır.
      await tester.tap(find.byKey(const Key('profile.settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profili düzenle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editProfile.avatar')));
      await tester.pumpAndSettle();
      // Oyuncu fotoğrafı seçeneği kalktı.
      expect(find.text('Dizi görsellerinden seç'), findsOneWidget);
      await tester.tap(find.byKey(const Key('avatar.show')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('showChooser.1')));
      await tester.pumpAndSettle();
      // Arka plan ve afiş birlikte listelenir.
      expect(find.byKey(const Key('avatarImage.0')), findsOneWidget);
      expect(find.byKey(const Key('avatarImage.1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('avatarImage.1')));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AvatarCropView), findsOneWidget);
      expect(find.text('Kırp'), findsOneWidget);
    },
  );

  testWidgets(
    'Letterboxd ve Instagram doğrulanır, yalnızca kullanıcı adı kaydedilir (F2)',
    (tester) async {
      final backend = await _openProfile(tester);
      when(() => backend.profiles.saveProfile(any(), any()))
          .thenAnswer((_) async => testProfile);

      // Profili düzenleme yalnızca Ayarlar'dan açılır.
      await tester.tap(find.byKey(const Key('profile.settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profili düzenle'));
      await tester.pumpAndSettle();
      final letterboxd = find.byKey(const Key('editProfile.letterboxd'));
      final instagram = find.byKey(const Key('editProfile.instagram'));
      await tester.ensureVisible(instagram);
      await tester.enterText(letterboxd, 'a');
      await tester.enterText(instagram, 'ay..se');
      await tester.tap(find.byKey(const Key('editProfile.save')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Geçerli bir Letterboxd profil bağlantısı'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Geçerli bir Instagram profil bağlantısı'),
        findsOneWidget,
      );
      verifyNever(() => backend.profiles.saveProfile(any(), any()));

      await tester.enterText(letterboxd, 'https://letterboxd.com/Ayse_LB/');
      await tester.enterText(instagram, '@ayse.dizi');
      await tester.tap(find.byKey(const Key('editProfile.save')));
      await tester.pumpAndSettle();

      final edit =
          verify(() => backend.profiles.saveProfile(any(), captureAny()))
                  .captured
                  .single
              as ProfileEdit;
      expect(edit.letterboxdUsername, 'ayse_lb');
      expect(edit.instagramUsername, 'ayse.dizi');
    },
  );

  testWidgets(
    'dolu bağlantılar profilde yalnızca logolu simge olarak görünür (F8i)',
    (tester) async {
      await _openProfile(
        tester,
        profile: Profile(
          id: testUserId,
          username: 'ayse_1',
          displayName: 'Ayşe',
          bio: '',
          letterboxdUsername: 'ayse_lb',
          createdAt: testProfile.createdAt,
        ),
      );

      final button = find.byKey(const Key('profile.letterboxd'));
      expect(button, findsOneWidget);
      // Bağlantı metni yok; ekran okuyucu etiketi platform ve kullanıcı adını söyler.
      expect(find.text('letterboxd.com/ayse_lb'), findsNothing);
      expect(find.bySemanticsLabel('Letterboxd: ayse_lb'), findsOneWidget);
      expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
      expect(find.byKey(const Key('profile.instagram')), findsNothing);
    },
  );

  testWidgets(
    'profildeki Dizilerim ızgarası grup renginde çubuklu ve çiplerle süzülür (F6j, F8e)',
    (tester) async {
      final shows = [_entry(1), _entry(2)];
      await _openProfile(
        tester,
        myShows: shows,
        progress: [
          _progressOf(shows[0], watched: 10),
          _progressOf(shows[1], watched: 0),
        ],
      );
      final chip = find.byKey(const Key('statusFilter.finished'));
      await tester.scrollUntilVisible(
        chip,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('statusBar.1')), findsOneWidget);
      expect(find.byKey(const Key('statusBar.2')), findsOneWidget);

      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statusBar.1')), findsOneWidget);
      expect(find.byKey(const Key('statusBar.2')), findsNothing);
      expect(find.byType(ProgressBar), findsOneWidget);
    },
  );

  testWidgets('Son etkinlik bölümün sahne görselini gösterir (F8k)', (
    tester,
  ) async {
    await _openProfile(
      tester,
      myShows: [_entry(1)],
      recent: [
        RecentEpisode(
          episodeId: 300,
          showId: 1,
          showName: 'Dizi 1',
          posterPath: '/afis.jpg',
          backdropPath: '/arka.jpg',
          stillPath: '/sahne300.jpg',
          seasonNumber: 1,
          episodeNumber: 4,
          watchedAt: DateTime.utc(2026, 10, 17),
        ),
        RecentEpisode(
          episodeId: 301,
          showId: 1,
          showName: 'Dizi 1',
          posterPath: '/afis.jpg',
          backdropPath: '/arka.jpg',
          seasonNumber: 1,
          episodeNumber: 3,
          watchedAt: DateTime.utc(2026, 10, 16),
        ),
      ],
    );
    String imageOf(int id) => tester
        .widget<CachedNetworkImage>(
          find.descendant(
            of: find.byKey(Key('profile.recent.$id')),
            matching: find.byType(CachedNetworkImage),
          ),
        )
        .imageUrl;
    expect(imageOf(300), contains('/sahne300.jpg'));
    // Sahne görseli yoksa dizinin arka planı.
    expect(imageOf(301), contains('/arka.jpg'));
    expect(find.text('S01 | B04'), findsOneWidget);
  });

  testWidgets(
    "istatistikler Favorilerin üstünde, Puanlar Dizilerim'in üstünde (F8e, F8l)",
    (tester) async {
      final backend = TestBackend();
      when(() => backend.profiles.fetchRatingDistribution(testUserId))
          .thenAnswer(
            (_) async => const [
              RatingCount(rating: 2, count: 1),
              RatingCount(rating: 4.5, count: 4),
            ],
          );
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await backend.pumpApp(tester);
      await tester.tap(_navLabel('Profil'));
      await tester.pumpAndSettle();

      double y(Finder f) => tester.getTopLeft(f).dy;
      final stats = find.byKey(const Key('profile.watchTime'));
      expect(y(stats), greaterThan(y(find.byKey(const Key('profile.avatar')))));
      expect(y(stats), lessThan(y(find.text('Favori diziler'))));
      expect(y(find.text('Puanlar')), lessThan(y(find.text('Dizilerim'))));
      expect(
        y(find.text('Şu an izlediklerim')),
        lessThan(y(find.text('Puanlar'))),
      );

      expect(find.text('5 puan · ortalama 4,0'), findsOneWidget);
      double height(double rating) =>
          tester.getSize(find.byKey(Key('profile.ratingBar.$rating'))).height;
      // En çok verilen puan tam boy, 1 kez verilen dörtte biri.
      expect(height(4.5), closeTo(4 * height(2.0), 0.01));
      expect(height(4.5), greaterThan(height(3.0)));
    },
  );

  testWidgets('düzenleme ekranında bağlantılar tam adresle görünür (F2)', (
    tester,
  ) async {
    await _openProfile(
      tester,
      profile: Profile(
        id: testUserId,
        username: 'ayse_1',
        displayName: 'Ayşe',
        bio: '',
        instagramUsername: 'ayse.dizi',
        createdAt: testProfile.createdAt,
      ),
    );
    // Profili düzenleme yalnızca Ayarlar'dan açılır.
    await tester.tap(find.byKey(const Key('profile.settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profili düzenle'));
    await tester.pumpAndSettle();
    final instagram = find.byKey(const Key('editProfile.instagram'));
    await tester.ensureVisible(instagram);
    expect(
      tester.widget<TextFormField>(instagram).controller!.text,
      'https://www.instagram.com/ayse.dizi/',
    );
  });
}
