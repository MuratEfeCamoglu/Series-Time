import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/suggest/data/models.dart';
import 'package:sezonluk/features/suggest/screens/suggest_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

const _genres = [
  Genre(id: 18, name: 'Dram'),
  Genre(id: 35, name: 'Komedi'),
  Genre(id: 80, name: 'Suç'),
  Genre(id: 99, name: 'Belgesel'),
];

List<Show> _shows(int from, int count) => [
  for (var i = from; i < from + count; i++) Show(id: i, name: 'Öneri $i'),
];

FilterChip _chip(WidgetTester tester, int id) =>
    tester.widget<FilterChip>(find.byKey(Key('genre.$id')));

Future<TestBackend> _openSuggest(
  WidgetTester tester, {
  List<int> topGenres = const [],
  Map<String, Object> preferences = const {},
  List<UserShow> myShows = const [],
  ShowSearchPage? page,
}) async {
  final backend = TestBackend();
  when(() => backend.suggest.fetchGenres()).thenAnswer((_) async => _genres);
  when(() => backend.suggest.topGenres()).thenAnswer((_) async => topGenres);
  when(() => backend.shows.fetchMyShows()).thenAnswer((_) async => myShows);
  when(() => backend.suggest.discover(any(), page: any(named: 'page')))
      .thenAnswer(
        (_) async =>
            page ?? ShowSearchPage(results: _shows(1, 3), totalPages: 1),
      );
  await backend.pumpApp(tester, preferenceValues: preferences);
  GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/suggest');
  await tester.pumpAndSettle();
  expect(find.byType(SuggestScreen), findsOneWidget);
  return backend;
}

void main() {
  testWidgets('Keşfet\'in üstündeki kart öneriler sayfasını açar (F18a)', (
    tester,
  ) async {
    final backend = TestBackend();
    await backend.pumpApp(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Keşfet'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('discover.suggestCard')));
    await tester.pumpAndSettle();
    expect(find.byType(SuggestScreen), findsOneWidget);
  });

  testWidgets(
    'saklı seçim yoksa listedeki en sık türler seçili gelir (F18c, F18d)',
    (tester) async {
      final backend = await _openSuggest(tester, topGenres: [35, 18]);

      expect(_chip(tester, 18).selected, isTrue);
      expect(_chip(tester, 35).selected, isTrue);
      expect(_chip(tester, 80).selected, isFalse);
      verify(() => backend.suggest.discover([18, 35])).called(1);
      expect(find.text('Öneri 1'), findsWidgets);
    },
  );

  testWidgets('cihazda saklanan seçim önce gelir (F18c)', (tester) async {
    final backend = await _openSuggest(
      tester,
      topGenres: [35],
      preferences: {
        'suggest.genres': ['80'],
      },
    );

    expect(_chip(tester, 80).selected, isTrue);
    expect(_chip(tester, 35).selected, isFalse);
    verifyNever(() => backend.suggest.topGenres());
  });

  testWidgets('liste boşsa tür seçilmez ve ileti görünür (F18c)', (
    tester,
  ) async {
    final backend = await _openSuggest(tester);

    expect(
      find.text('Öneri almak için en az bir kategori seç'),
      findsOneWidget,
    );
    verifyNever(() => backend.suggest.discover(any()));
  });

  testWidgets('4. kategori eklenmez ve ileti çıkar; seçim saklanır (F18b)', (
    tester,
  ) async {
    final backend = await _openSuggest(tester, topGenres: [18, 35, 80]);

    await tester.tap(find.byKey(const Key('genre.99')));
    await tester.pumpAndSettle();

    expect(find.text('En fazla 3 kategori seçebilirsin'), findsOneWidget);
    expect(_chip(tester, 99).selected, isFalse);

    await tester.tap(find.byKey(const Key('genre.80')));
    await tester.pumpAndSettle();
    expect(_chip(tester, 80).selected, isFalse);
    expect(backend.preferences.getStringList('suggest.genres'), ['18', '35']);
    verify(() => backend.suggest.discover([18, 35])).called(1);
  });

  testWidgets('"+" diziyi listeye ekler ve ızgaradan hemen kaldırır (F18e)', (
    tester,
  ) async {
    final backend = await _openSuggest(tester, topGenres: [18]);
    when(() => backend.shows.addToMyShows(1)).thenAnswer((_) async {});
    when(() => backend.shows.fetchShow(1)).thenAnswer(
      (_) async => const ShowDetail(
        show: Show(id: 1, name: 'Öneri 1'),
        seasons: [Season(id: 10, showId: 1, seasonNumber: 1)],
      ),
    );
    when(() => backend.shows.fetchSeasonEpisodes(1, 1))
        .thenAnswer((_) async => const []);

    await tester.tap(find.byKey(const Key('suggest.add.1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('suggest.add.1')), findsNothing);
    expect(find.byKey(const Key('suggest.add.2')), findsOneWidget);
    verify(() => backend.shows.addToMyShows(1)).called(1);
    // Sıradaki bölüm hesabı için dizinin bölümleri çekilir.
    verify(() => backend.shows.fetchSeasonEpisodes(1, 1)).called(1);
  });

  testWidgets('sonuç kalmadıysa boş durum (F18g)', (tester) async {
    await _openSuggest(
      tester,
      topGenres: [18],
      page: const ShowSearchPage(results: [], totalPages: 0),
    );

    expect(find.text('Bu kategorilerde yeni öneri kalmadı'), findsOneWidget);
  });

  testWidgets('aşağı kaydırınca sonraki sayfa yüklenir (F18d)', (tester) async {
    final backend = await _openSuggest(
      tester,
      topGenres: [18],
      page: ShowSearchPage(results: _shows(1, 20), totalPages: 2),
    );
    when(() => backend.suggest.discover([18], page: 2)).thenAnswer(
      (_) async => ShowSearchPage(results: _shows(21, 5), totalPages: 2),
    );

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -3000),
      3000,
    );
    await tester.pumpAndSettle();

    verify(() => backend.suggest.discover([18], page: 2)).called(1);
  });

  testWidgets('"İzlediklerine benzer": son izlenen diziye göre (F18f)', (
    tester,
  ) async {
    final backend = TestBackend();
    when(() => backend.suggest.recommendations(1399))
        .thenAnswer((_) async => _shows(50, 2));
    await _openSuggestWithBackend(
      tester,
      backend,
      myShows: [
        UserShow(
          show: testShow,
          addedAt: DateTime.utc(2026, 1, 1),
          lastWatchedAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );

    expect(find.text('Taht Oyunları izlediğin için'), findsOneWidget);
    expect(find.byKey(const Key('suggest.add.50')), findsOneWidget);
  });

  testWidgets('hiç bölüm izlenmemişse benzer bölümü gösterilmez (F18f)', (
    tester,
  ) async {
    final backend = await _openSuggest(
      tester,
      topGenres: [18],
      myShows: [UserShow(show: testShow, addedAt: DateTime.utc(2026, 1, 1))],
    );

    expect(find.textContaining('izlediğin için'), findsNothing);
    verifyNever(() => backend.suggest.recommendations(any()));
  });
}

Future<void> _openSuggestWithBackend(
  WidgetTester tester,
  TestBackend backend, {
  required List<UserShow> myShows,
}) async {
  when(() => backend.suggest.fetchGenres()).thenAnswer((_) async => _genres);
  when(() => backend.shows.fetchMyShows()).thenAnswer((_) async => myShows);
  await backend.pumpApp(tester);
  GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/suggest');
  await tester.pumpAndSettle();
}
