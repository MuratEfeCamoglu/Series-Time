import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/screens/show_detail_screen.dart';
import 'package:sezonluk/features/tracking/widgets/on_the_air_row.dart';
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

void main() {
  testWidgets(
    'Diziler sekmesinin üstünde "Şu an yayında", listede olmayanlar dahil (F6i)',
    (tester) async {
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

      expect(find.text('Şu an yayında'), findsOneWidget);
      expect(_rowPosters(), findsNWidgets(2));
      // Kullanıcının listesi boş; satır yine de dolu (listedekiler süzülmez).
      verify(() => backend.shows.onTheAirShows()).called(1);

      await tester.tap(_rowPosters().first);
      await tester.pumpAndSettle();
      expect(find.byType(ShowDetailScreen), findsOneWidget);
    },
  );

  testWidgets('misafir de "Şu an yayında" satırını görür (F6i, F19b)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = TestBackend(initialStatus: AuthStatus.guest);
    when(() => backend.shows.onTheAirShows()).thenAnswer((_) async => _airing);
    await backend.pumpApp(tester);

    expect(_rowPosters(), findsNWidgets(2));
    expect(find.byType(GuestGate), findsOneWidget);
  });
}
