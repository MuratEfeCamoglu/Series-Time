import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/screens/show_detail_screen.dart';
import 'package:sezonluk/features/discover/widgets/on_the_air_row.dart';
import 'package:sezonluk/shared/widgets/guest_gate.dart';
import 'package:sezonluk/shared/widgets/poster_card.dart';

import '../../helpers.dart';

const _airing = [
  Show(id: 1, name: 'Yayında Bir'),
  Show(id: 2, name: 'Yayında İki'),
];

Finder _rowPosters() => find.descendant(
  of: find.byType(OnTheAirRow),
  matching: find.byType(PosterCard),
);

Future<void> _goToDiscover(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Keşfet'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Keşfet\'te öneri kartının altında, en ünlülerin üstünde "Şu an yayında" (F3g)',
    (tester) async {
      tester.view
        ..physicalSize = const Size(800, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final backend = TestBackend();
      when(() => backend.shows.onTheAirShows())
          .thenAnswer((_) async => _airing);
      when(() => backend.shows.fetchShow(1)).thenAnswer(
        (_) async => const ShowDetail(
          show: Show(id: 1, name: 'Yayında Bir'),
          seasons: [],
        ),
      );
      await backend.pumpApp(tester);
      // Diziler sekmesinden taşındı.
      expect(find.text('Şu an yayında'), findsNothing);
      await _goToDiscover(tester);

      expect(find.text('Şu an yayında'), findsOneWidget);
      final row = tester.getTopLeft(find.byType(OnTheAirRow)).dy;
      expect(
        row,
        greaterThan(tester.getTopLeft(find.text('Sana Özel Öneriler')).dy),
      );
      expect(row, lessThan(tester.getTopLeft(find.text('En ünlü diziler')).dy));
      expect(_rowPosters(), findsNWidgets(2));
      // Kullanıcının listesi boş; satır yine de dolu (listedekiler süzülmez).
      verify(() => backend.shows.onTheAirShows()).called(1);

      await tester.tap(_rowPosters().first);
      await tester.pumpAndSettle();
      expect(find.byType(ShowDetailScreen), findsOneWidget);
    },
  );

  testWidgets('misafir de "Şu an yayında" satırını görür (F3g, F19b)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = TestBackend(initialStatus: AuthStatus.guest);
    when(() => backend.shows.onTheAirShows()).thenAnswer((_) async => _airing);
    await backend.pumpApp(tester);
    expect(find.byType(GuestGate), findsOneWidget);
    await _goToDiscover(tester);

    expect(_rowPosters(), findsNWidgets(2));
  });
}
