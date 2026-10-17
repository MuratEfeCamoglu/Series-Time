import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/screens/season_screen.dart';
import 'package:sezonluk/features/tracking/data/models.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

final _detail = ShowDetail(
  show: testShow,
  seasons: const [
    Season(
      id: 2,
      showId: 1399,
      seasonNumber: 1,
      name: '1. Sezon',
      episodeCount: 10,
    ),
    Season(id: 1, showId: 1399, seasonNumber: 0, name: 'Özel', episodeCount: 3),
  ],
);

Future<TestBackend> _openDetail(
  WidgetTester tester, {
  List<UserShow> myShows = const [],
}) async {
  final backend = TestBackend();
  when(() => backend.shows.fetchMyShows()).thenAnswer((_) async => myShows);
  when(() => backend.shows.fetchShow(1399)).thenAnswer((_) async => _detail);
  await backend.pumpApp(tester);
  GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/show/1399');
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('detay ad, yıl, durum, özet ve sezonları gösterir (F4a, F4d)', (
    tester,
  ) async {
    await _openDetail(tester);

    expect(find.text('Taht Oyunları'), findsWidgets);
    expect(find.text('2011 · Bitti'), findsOneWidget);
    // Açılışta Bölümler sekmesi: sezon kartları, özel bölümler en sonda (F4d).
    expect(find.text('Tüm bölümler'), findsOneWidget);
    expect(find.text('1. Sezon'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);
    expect(find.text('Özel'), findsOneWidget);

    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();
    expect(find.text('Yedi krallık...'), findsOneWidget);
    expect(find.text('Oyuncular'), findsOneWidget);
  });

  testWidgets('Hakkında sekmesinde oyuncular ve rolleri (F4a)', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = TestBackend();
    when(() => backend.shows.fetchShow(1399)).thenAnswer((_) async => _detail);
    when(() => backend.shows.fetchShowCast(1399)).thenAnswer(
      (_) async => const [
        ShowCastMember(
          personId: 22970,
          name: 'Peter Dinklage',
          character: 'Tyrion Lannister',
        ),
      ],
    );
    await backend.pumpApp(tester);
    GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/show/1399');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();
    expect(find.text('Peter Dinklage'), findsOneWidget);
    expect(find.text('Tyrion Lannister'), findsOneWidget);
  });

  testWidgets(
    'Bölümler: sıradaki bölüm bandı, sezon ilerlemesi ve sezonu işaretleme (F4a, F5b)',
    (tester) async {
      // Başlık, sekmeler, bant ve kartlar birlikte görünsün.
      tester.view
        ..physicalSize = const Size(800, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final backend = TestBackend();
      final past = DateTime.utc(2020, 1, 1);
      when(() => backend.shows.fetchShow(1399))
          .thenAnswer((_) async => _detail);
      when(() => backend.shows.fetchCachedEpisodes(1399)).thenAnswer(
        (_) async => [
          Episode(
            id: 1,
            showId: 1399,
            seasonNumber: 1,
            episodeNumber: 1,
            name: 'Bir',
            airDate: past,
          ),
          Episode(
            id: 2,
            showId: 1399,
            seasonNumber: 1,
            episodeNumber: 2,
            name: 'İki',
            airDate: past,
          ),
        ],
      );
      when(() => backend.tracking.fetchWatchedEpisodeIds(1399))
          .thenAnswer((_) async => {1});
      when(() => backend.tracking.markSeason(1399, 1)).thenAnswer((_) async {});
      await backend.pumpApp(tester);
      GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/show/1399');
      await tester.pumpAndSettle();

      expect(find.text('Sıradaki'), findsOneWidget);
      expect(find.text('S01 | B02 · İki'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('season.markAll.1')));
      await tester.pumpAndSettle();
      verify(() => backend.tracking.markSeason(1399, 1)).called(1);
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('Hepsini izledin!'), findsOneWidget);
    },
  );

  testWidgets(
    '"Ekle" düğmeyi beklemeden değiştirir, bölümleri çeker ve dizi Diziler sekmesinde görünür (F4b)',
    (tester) async {
      final backend = await _openDetail(tester);
      final request = Completer<void>();
      when(() => backend.shows.addToMyShows(1399))
          .thenAnswer((_) => request.future);
      when(() => backend.shows.fetchSeasonEpisodes(1399, 1))
          .thenAnswer((_) async => const []);
      when(() => backend.tracking.fetchWatchlist()).thenAnswer(
        (_) async => [
          WatchlistItem(
            showId: 1399,
            name: 'Taht Oyunları',
            addedAt: DateTime.utc(2026, 10, 17),
            nextEpisodeId: 63056,
            nextSeasonNumber: 1,
            nextEpisodeNumber: 1,
            airedCount: 73,
            watchedCount: 0,
          ),
        ],
      );

      await tester.tap(find.byKey(const Key('showDetail.add')));
      await tester.pump();

      // Sunucu henüz yanıt vermedi; düğme iyimser olarak değişti.
      expect(find.byKey(const Key('showDetail.remove')), findsOneWidget);
      request.complete();
      await tester.pumpAndSettle();
      verify(() => backend.shows.addToMyShows(1399)).called(1);
      // Özel bölümler (sezon 0) sıradaki bölüm hesabına girmediği için çekilmez.
      verify(() => backend.shows.fetchSeasonEpisodes(1399, 1)).called(1);
      verifyNever(() => backend.shows.fetchSeasonEpisodes(1399, 0));

      GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ShowsScreen), findsOneWidget);
      expect(find.text('S01 | B01'), findsOneWidget);
    },
  );

  testWidgets('ekleme başarısız olursa geri alınır ve hata gösterilir', (
    tester,
  ) async {
    final backend = await _openDetail(tester);
    when(() => backend.shows.addToMyShows(1399))
        .thenThrow(const AppFailure(AppFailureType.network));

    await tester.tap(find.byKey(const Key('showDetail.add')));
    await tester.pumpAndSettle();

    expect(find.text('Kaydedilemedi, tekrar dene.'), findsOneWidget);
    expect(find.byKey(const Key('showDetail.add')), findsOneWidget);
  });

  testWidgets('"Listeden çıkar" onay ister (F4c)', (tester) async {
    final backend = await _openDetail(
      tester,
      myShows: [UserShow(show: testShow, addedAt: DateTime.utc(2026, 10, 1))],
    );
    when(() => backend.shows.removeFromMyShows(1399)).thenAnswer((_) async {});

    await tester.tap(find.byKey(const Key('showDetail.remove')));
    await tester.pumpAndSettle();
    expect(find.text('Listeden çıkarılsın mı?'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    verifyNever(() => backend.shows.removeFromMyShows(any()));
    expect(find.byKey(const Key('showDetail.remove')), findsOneWidget);

    await tester.tap(find.byKey(const Key('showDetail.remove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('showDetail.confirmRemove')));
    await tester.pumpAndSettle();

    verify(() => backend.shows.removeFromMyShows(1399)).called(1);
    expect(find.byKey(const Key('showDetail.add')), findsOneWidget);
  });

  testWidgets('sezona dokununca bölümler no, ad ve tarihle listelenir', (
    tester,
  ) async {
    final backend = await _openDetail(tester);
    when(() => backend.shows.fetchSeasonEpisodes(1399, 1)).thenAnswer(
      (_) async => [
        Episode(
          id: 63056,
          showId: 1399,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Kış Geliyor',
          airDate: DateTime.utc(2011, 4, 17),
        ),
        const Episode(
          id: 63057,
          showId: 1399,
          seasonNumber: 1,
          episodeNumber: 2,
          name: 'Kral Yolu',
        ),
      ],
    );

    // Yeni sayfa açılmaz; bölümler sezon kartının altında bant olarak açılır.
    await tester.tap(find.text('1. Sezon'));
    await tester.pumpAndSettle();
    expect(find.byType(SeasonScreen), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('episode.banner.63057')));
    await tester.pumpAndSettle();
    expect(find.text('S01 | B01 · Kış Geliyor'), findsOneWidget);
    expect(find.text('17 Nisan 2011'), findsOneWidget);
    expect(find.text('Yayın tarihi belli değil'), findsOneWidget);

    await tester.tap(find.text('1. Sezon'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('episode.banner.63056')), findsNothing);
  });
}
