import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/discover/widgets/show_result_tile.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/shared/widgets/poster_card.dart';

import '../../helpers.dart';

Future<TestBackend> _openDiscover(
  WidgetTester tester, {
  List<Show> trending = const [],
}) async {
  final backend = TestBackend();
  when(() => backend.shows.trendingShows()).thenAnswer((_) async => trending);
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

final _search = find.byKey(const Key('discover.search'));

void main() {
  testWidgets(
    'arama kutusu boşken trend diziler 3\'lü ızgarada görünür (F3d)',
    (tester) async {
      await _openDiscover(
        tester,
        trending: [for (var i = 1; i <= 3; i++) Show(id: i, name: 'Trend $i')],
      );

      expect(find.text('Haftanın trend dizileri'), findsOneWidget);
      expect(find.byType(PosterCard), findsNWidgets(3));
      final delegate =
          tester.widget<SliverGrid>(find.byType(SliverGrid)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    },
  );

  testWidgets('tek karakterle istek atılmaz (F3b)', (tester) async {
    final backend = await _openDiscover(tester);

    await tester.enterText(_search, 't');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Aramak için en az 2 karakter yaz.'), findsOneWidget);
    verifyNever(() => backend.shows.searchShows(any()));
  });

  testWidgets(
    'yazma durduktan 300 ms sonra tek istek atılır, sonuç ad ve yılla listelenir (F3b)',
    (tester) async {
      final backend = await _openDiscover(tester);
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
    final backend = await _openDiscover(tester);
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
    final backend = await _openDiscover(tester);
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
}
