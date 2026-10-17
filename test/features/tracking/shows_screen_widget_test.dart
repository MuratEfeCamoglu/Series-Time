import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/discover/screens/discover_screen.dart';
import 'package:sezonluk/features/episode_feedback/screens/episode_screen.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/tracking/data/models.dart';
import 'package:sezonluk/shared/widgets/progress_bar.dart';

import '../../helpers.dart';

WatchlistItem _item(
  int showId, {
  DateTime? lastWatchedAt,
  int watched = 4,
  int aired = 10,
}) => WatchlistItem(
  showId: showId,
  name: 'Dizi $showId',
  addedAt: DateTime.utc(2026, 1, 1),
  lastWatchedAt: lastWatchedAt,
  nextEpisodeId: showId * 100,
  nextSeasonNumber: 1,
  nextEpisodeNumber: 5,
  airedCount: aired,
  watchedCount: watched,
);

Future<TestBackend> _open(
  WidgetTester tester, {
  List<WatchlistItem> watchlist = const [],
  List<UpcomingEpisode> upcoming = const [],
  Map<String, Object> preferences = const {},
}) async {
  final backend = TestBackend();
  when(() => backend.shows.fetchMyShows()).thenAnswer(
    (_) async => [UserShow(show: testShow, addedAt: DateTime.utc(2026, 1, 1))],
  );
  when(() => backend.tracking.fetchWatchlist())
      .thenAnswer((_) async => watchlist);
  when(() => backend.tracking.fetchUpcoming(90))
      .thenAnswer((_) async => upcoming);
  await backend.pumpApp(tester, preferenceValues: preferences);
  return backend;
}

void main() {
  testWidgets('listede dizi yoksa boş durum ve Keşfet düğmesi görünür (F6f)', (
    tester,
  ) async {
    final backend = TestBackend();
    await backend.pumpApp(tester);

    expect(find.text('Henüz dizi eklemedin'), findsOneWidget);
    await tester.tap(find.text("Keşfet'e git"));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverScreen), findsOneWidget);
  });

  testWidgets(
    'Sıradaki ve Bir süredir izlemediklerin bölümleri, kod ve ilerleme (F6a, F6b, F6e)',
    (tester) async {
      final now = DateTime.now().toUtc();
      await _open(
        tester,
        watchlist: [
          _item(1, lastWatchedAt: now.subtract(const Duration(days: 2))),
          _item(2, lastWatchedAt: now.subtract(const Duration(days: 40))),
        ],
      );

      expect(find.text('Sıradaki'), findsOneWidget);
      expect(find.text('S01B05'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Bir süredir izlemediklerin'),
        200,
        // Sekme görünümünün kendi kaydırıcısı da var; liste kaydırılır.
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Bir süredir izlemediklerin'), findsOneWidget);
      final bar = tester.widget<ProgressBar>(find.byType(ProgressBar).first);
      expect(bar.value, 0.4);
    },
  );

  testWidgets('tüm yayınlanmış bölümler izlendiyse liste boş iletisi', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('İzleyecek yeni bölüm yok'), findsOneWidget);
  });

  testWidgets('ızgara varsayılandır; liste tercihi cihazda saklanır (F6c)', (
    tester,
  ) async {
    final backend = await _open(tester, watchlist: [_item(1)]);
    expect(find.byType(SliverGrid), findsOneWidget);

    await tester.tap(find.byKey(const Key('watchlist.layout')));
    await tester.pumpAndSettle();

    expect(find.byType(SliverGrid), findsNothing);
    expect(backend.preferences.getString('watchlist.layout'), 'list');
  });

  testWidgets('saklanan liste tercihiyle açılır (F6c)', (tester) async {
    await _open(
      tester,
      watchlist: [_item(1)],
      preferences: {'watchlist.layout': 'list'},
    );
    expect(find.byType(SliverGrid), findsNothing);
    expect(find.text('Dizi 1'), findsWidgets);
  });

  testWidgets(
    'onay düğmesi sıradaki bölümü iyimser işaretler ve Bölüm Sonrası ekranını açar (F6d, F5e, F5f)',
    (tester) async {
      final backend = await _open(
        tester,
        watchlist: [_item(1)],
        preferences: {'watchlist.layout': 'list'},
      );
      final request = Completer<void>();
      when(() => backend.tracking.markEpisode(episodeId: 100, showId: 1))
          .thenAnswer((_) => request.future);

      await tester.tap(find.byKey(const Key('watchlist.check.1')));
      await tester.pump();

      verify(() => backend.tracking.markEpisode(episodeId: 100, showId: 1))
          .called(1);
      await tester.pumpAndSettle();
      expect(find.byType(EpisodeScreen), findsOneWidget);

      request.complete();
      await tester.pumpAndSettle();
      // Sunucu onayından sonra yeni sıradaki bölüm için liste yeniden çekilir.
      verify(() => backend.tracking.fetchWatchlist()).called(2);
    },
  );

  testWidgets(
    'işaretleme başarısızsa geri alınır ve hata iletisi çıkar (F5e)',
    (tester) async {
      final backend = await _open(
        tester,
        watchlist: [_item(1)],
        preferences: {'watchlist.layout': 'list'},
      );
      when(() => backend.tracking.markEpisode(episodeId: 100, showId: 1))
          .thenThrow(const AppFailure(AppFailureType.network));

      await tester.tap(find.byKey(const Key('watchlist.check.1')));
      await tester.pumpAndSettle();

      // İleti, Bölüm Sonrası ekranının altındaki Diziler ekranında gösterilir.
      Navigator.of(tester.element(find.byType(EpisodeScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Kaydedilemedi, tekrar dene.'), findsOneWidget);
      final bar = tester.widget<ProgressBar>(find.byType(ProgressBar));
      expect(bar.value, 0.4);
    },
  );

  testWidgets('Yaklaşan: Bugün, Yarın ve tarih başlıkları (F7)', (
    tester,
  ) async {
    // "Şu an yayında" satırı da ekranda; tüm gruplar görünsün.
    tester.view
      ..physicalSize = const Size(800, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final today = DateTime.now().toUtc();
    DateTime day(int offset) =>
        DateTime.utc(today.year, today.month, today.day + offset);
    UpcomingEpisode upcoming(int id, int offset) => UpcomingEpisode(
      episodeId: id,
      showId: 1,
      showName: 'Dizi $id',
      seasonNumber: 2,
      episodeNumber: id,
      episodeName: 'Bölüm $id',
      airDate: day(offset),
    );

    await _open(
      tester,
      upcoming: [upcoming(1, 0), upcoming(2, 1), upcoming(3, 5)],
    );
    await tester.tap(find.text('Yaklaşan'));
    await tester.pumpAndSettle();

    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Yarın'), findsOneWidget);
    expect(find.text('S02B03 · Bölüm 3'), findsOneWidget);
  });

  testWidgets('yaklaşan bölüm yoksa boş durum (F7)', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Yaklaşan'));
    await tester.pumpAndSettle();

    expect(find.text('Yaklaşan bölüm yok'), findsOneWidget);
  });
}
