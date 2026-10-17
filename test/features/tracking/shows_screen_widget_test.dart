import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/discover/screens/discover_screen.dart';
import 'package:sezonluk/features/episode_feedback/screens/episode_screen.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/tracking/data/models.dart';
import 'package:sezonluk/features/tracking/logic.dart';
import 'package:sezonluk/features/tracking/providers.dart';
import 'package:sezonluk/theme/app_colors.dart';
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

      // Sekme "Sıradaki", ilk bölüm "İzlemeye devam et" (F6a).
      expect(find.text('Sıradaki'), findsOneWidget);
      expect(find.text('İzlemeye devam et'), findsOneWidget);
      expect(find.text('S01 | B05'), findsWidgets);
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

  testWidgets('liste varsayılandır; ızgara tercihi cihazda saklanır (F6c)', (
    tester,
  ) async {
    final backend = await _open(tester, watchlist: [_item(1)]);
    expect(find.byType(SliverGrid), findsNothing);
    expect(find.text('S01 | B05'), findsOneWidget);

    await tester.tap(find.byKey(const Key('watchlist.layout')));
    await tester.pumpAndSettle();

    expect(find.byType(SliverGrid), findsOneWidget);
    expect(backend.preferences.getString('watchlist.layout'), 'grid');
  });

  testWidgets('saklanan ızgara tercihiyle açılır (F6c)', (tester) async {
    await _open(
      tester,
      watchlist: [_item(1)],
      preferences: {'watchlist.layout': 'grid'},
    );
    expect(find.byType(SliverGrid), findsOneWidget);
  });

  testWidgets(
    'onay düğmesi sıradaki bölümü iyimser işaretler, Bölüm Sonrası açılmaz (F6d, F5e, F5f)',
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
      await tester.pump();
      expect(find.byType(EpisodeScreen), findsNothing);

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

  ShowProgress progress(int id, {DateTime? watchedAt}) => ShowProgress(
    showId: id,
    name: 'Dizi $id',
    addedAt: DateTime.utc(2026, 1, id),
    lastWatchedAt: watchedAt,
    airedCount: 10,
    watchedCount: watchedAt == null ? 0 : 4,
    showStatus: 'Returning Series',
  );

  testWidgets(
    'tek sayfa: Son izlenen diziler, Sıradaki, Yaklaşan sırayla; alt sekme yok (F6, F7)',
    (tester) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final today = DateTime.now().toUtc();
      final backend = TestBackend();
      when(() => backend.shows.fetchMyShows()).thenAnswer(
        (_) async => [UserShow(show: testShow, addedAt: DateTime.utc(2026))],
      );
      when(() => backend.tracking.fetchShowProgress(testUserId)).thenAnswer(
        (_) async => [
          progress(1, watchedAt: DateTime.utc(2026, 10, 1)),
          progress(2),
          progress(3, watchedAt: DateTime.utc(2026, 10, 5)),
        ],
      );
      when(() => backend.tracking.fetchWatchlist())
          .thenAnswer((_) async => [_item(1)]);
      when(() => backend.tracking.fetchUpcoming(90)).thenAnswer(
        (_) async => [
          for (var i = 0; i < 7; i++)
            UpcomingEpisode(
              episodeId: 900 + i,
              showId: 1399,
              showName: 'Yakında $i',
              seasonNumber: 2,
              episodeNumber: i + 1,
              airDate: DateTime.utc(today.year, today.month, today.day + i),
            ),
        ],
      );
      await backend.pumpApp(tester);

      expect(find.byType(TabBar), findsNothing);
      double y(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(y('Son izlenen diziler'), lessThan(y('Sıradaki')));
      expect(y('Sıradaki'), lessThan(y('Yaklaşan')));
      // Son izlenenler: izlenmemiş dizi yok, en son izlenen önce.
      final recent = find.byKey(const Key('shows.recent'));
      final bars = tester
          .widgetList<ProgressBar>(
            find.descendant(of: recent, matching: find.byType(ProgressBar)),
          )
          .length;
      expect(bars, 2);
      expect(
        tester.getTopLeft(find.byKey(const Key('statusBar.3'))).dx,
        lessThan(tester.getTopLeft(find.byKey(const Key('statusBar.1'))).dx),
      );

      // Yaklaşan: ilk 5, "Tümünü göster" ile hepsi.
      expect(find.text('Yakında 4'), findsWidgets);
      expect(find.text('Yakında 5'), findsNothing);
      await tester.tap(find.byKey(const Key('upcoming.toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Yakında 6'), findsWidgets);
    },
  );

  testWidgets('grup kaydı başarısızsa geri alınır (F6j)', (tester) async {
    final backend = await _open(tester);
    when(() => backend.tracking.fetchShowProgress(testUserId)).thenAnswer(
      (_) async => [progress(1, watchedAt: DateTime.utc(2026, 10, 1))],
    );
    when(() => backend.tracking.setManualStatus(1, ManualShowStatus.dropped))
        .thenThrow(const AppFailure(AppFailureType.network));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.invalidate(myShowProgressProvider);
    await tester.pumpAndSettle();

    await expectLater(
      container
          .read(myShowProgressProvider.notifier)
          .setStatus(1, ShowStatus.dropped),
      throwsA(isA<AppFailure>()),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProgressBar>(
            find.descendant(
              of: find.byKey(const Key('statusBar.1')),
              matching: find.byType(ProgressBar),
            ),
          )
          .color,
      AppColors.statusWatching,
    );
  });
}
