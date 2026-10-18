import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/discover/screens/discover_search_screen.dart';
import 'package:sezonluk/features/discover/widgets/show_result_tile.dart';
import 'package:sezonluk/features/discover/widgets/suggest_card.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/screens/show_detail_screen.dart';
import 'package:sezonluk/shared/widgets/poster_card.dart';

import '../../helpers.dart';

Future<TestBackend> _openDiscover(
  WidgetTester tester, {
  List<Show> trending = const [],
  int totalPages = 1,
}) async {
  final backend = TestBackend();
  when(() => backend.shows.popularShows()).thenAnswer(
    (_) async => ShowSearchPage(results: trending, totalPages: totalPages),
  );
  await backend.pumpApp(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Keşfet'),
    ),
  );
  await tester.pumpAndSettle();
  return backend;
}

/// Arama Keşfet'in üst çubuğundaki simgeyle ayrı sayfada açılır.
Future<TestBackend> _openSearch(WidgetTester tester) async {
  final backend = await _openDiscover(tester);
  await tester.tap(find.byKey(const Key('discover.searchButton')));
  await tester.pumpAndSettle();
  expect(find.byType(DiscoverSearchScreen), findsOneWidget);
  return backend;
}

final _search = find.byKey(const Key('discover.search'));

void main() {
  testWidgets(
    'arama kutusu boşken trend diziler 3\'lü ızgarada görünür (F3d)',
    (tester) async {
      await _openDiscover(
        tester,
        trending: [for (var i = 1; i <= 3; i++) Show(id: i, name: 'Trend $i')],
      );

      expect(find.text('En ünlü diziler'), findsOneWidget);
      expect(find.byType(PosterCard), findsNWidgets(3));
      final delegate =
          tester.widget<SliverGrid>(find.byType(SliverGrid)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    },
  );

  testWidgets('tek karakterle istek atılmaz (F3b)', (tester) async {
    final backend = await _openSearch(tester);

    await tester.enterText(_search, 't');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Aramak için en az 2 karakter yaz.'), findsOneWidget);
    verifyNever(() => backend.shows.searchShows(any()));
  });

  testWidgets(
    'yazma durduktan 300 ms sonra tek istek atılır, sonuç ad ve yılla listelenir (F3b)',
    (tester) async {
      final backend = await _openSearch(tester);
      when(() => backend.shows.searchShows('taht')).thenAnswer(
        (_) async => ShowSearchPage(results: [testShow], totalPages: 1),
      );

      await tester.enterText(_search, 'ta');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(_search, 'taht');
      await tester.pump(const Duration(milliseconds: 299));
      verifyNever(() => backend.shows.searchShows(any()));

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      verify(() => backend.shows.searchShows('taht')).called(1);
      verifyNever(() => backend.shows.searchShows('ta'));
      expect(find.byType(ShowResultTile), findsOneWidget);
      // Ad hem satır başlığında hem afiş yüklenene kadar yer tutucuda yazar.
      expect(find.text('Taht Oyunları'), findsWidgets);
      expect(find.text('2011'), findsOneWidget);
    },
  );

  testWidgets('sonuç yoksa "Sonuç bulunamadı" görünür (F3e)', (tester) async {
    final backend = await _openSearch(tester);
    when(
      () => backend.shows.searchShows(any()),
    ).thenAnswer((_) async => const ShowSearchPage(results: [], totalPages: 0));

    await tester.enterText(_search, 'yok böyle dizi');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Sonuç bulunamadı'), findsOneWidget);
  });

  testWidgets('Kullanıcılar segmentinde kullanıcı adı aranır (F3a, F3c)', (
    tester,
  ) async {
    final backend = await _openSearch(tester);
    when(() => backend.social.searchUsers('ay'))
        .thenAnswer((_) async => [testProfile]);

    await tester.tap(find.text('Kullanıcılar'));
    await tester.pumpAndSettle();
    await tester.enterText(_search, 'ay');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    verify(() => backend.social.searchUsers('ay')).called(1);
    verifyNever(() => backend.shows.searchShows(any()));
    expect(find.text('@ayse_1'), findsOneWidget);
  });

  testWidgets(
    'Keşfet ana ekranında arama kutusu ve segment yok; öneri bandı kompakt (F3a, F18a)',
    (tester) async {
      await _openDiscover(tester);

      expect(_search, findsNothing);
      expect(find.text('Kullanıcılar'), findsNothing);
      expect(find.byKey(const Key('discover.searchButton')), findsOneWidget);
      expect(
        tester.getSize(find.byType(SuggestCard)).height,
        lessThanOrEqualTo(64),
      );
    },
  );

  testWidgets('arama sayfasında kutu odaklı ve segment var (F3a)', (
    tester,
  ) async {
    await _openSearch(tester);

    expect(find.text('Diziler'), findsWidgets);
    expect(find.text('Kullanıcılar'), findsOneWidget);
    expect(tester.widget<TextField>(_search).autofocus, isTrue);
    // Arama sekmenin içinde açılır; alt menü görünür kalır.
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('en ünlü diziler aşağı kaydırınca sonraki sayfayla artar (F3d)', (
    tester,
  ) async {
    final backend = await _openDiscover(
      tester,
      trending: [for (var i = 1; i <= 20; i++) Show(id: i, name: 'Ünlü $i')],
      totalPages: 3,
    );
    when(() => backend.shows.popularShows(page: 2)).thenAnswer(
      (_) async => ShowSearchPage(
        results: [for (var i = 21; i <= 25; i++) Show(id: i, name: 'Ünlü $i')],
        totalPages: 3,
      ),
    );

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -5000),
      3000,
    );
    await tester.pumpAndSettle();

    verify(() => backend.shows.popularShows(page: 2)).called(1);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -5000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Ünlü 25'), findsWidgets);
  });

  testWidgets('afişe dokununca detay aynı Hero etiketiyle açılır (F22d)', (
    tester,
  ) async {
    await _openDiscover(tester, trending: [testShow]);

    expect(
      tester.widget<Hero>(find.byType(Hero)).tag,
      'popular-${testShow.id}',
    );
    await tester.ensureVisible(find.byType(PosterCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PosterCard));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ShowDetailScreen>(find.byType(ShowDetailScreen)).heroTag,
      'popular-${testShow.id}',
    );
  });
}
