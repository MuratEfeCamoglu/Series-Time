import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/episode_feedback/screens/episode_screen.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/screens/season_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

final _past = DateTime.utc(2020, 1, 1);
final _future = DateTime.now().toUtc().add(const Duration(days: 30));

final _episodes = [
  Episode(
    id: 1,
    showId: 1399,
    seasonNumber: 1,
    episodeNumber: 1,
    name: 'Bir',
    airDate: _past,
  ),
  Episode(
    id: 2,
    showId: 1399,
    seasonNumber: 1,
    episodeNumber: 2,
    name: 'İki',
    airDate: _past,
  ),
  Episode(
    id: 3,
    showId: 1399,
    seasonNumber: 1,
    episodeNumber: 3,
    name: 'Üç',
    airDate: _future,
  ),
];

Future<TestBackend> _openSeason(
  WidgetTester tester, {
  Set<int> watched = const {},
}) async {
  final backend = TestBackend();
  when(() => backend.shows.fetchSeasonEpisodes(1399, 1))
      .thenAnswer((_) async => _episodes);
  when(() => backend.tracking.fetchWatchedEpisodeIds(1399))
      .thenAnswer((_) async => watched);
  await backend.pumpApp(tester);
  GoRouter.of(tester.element(find.byType(ShowsScreen)))
      .push('/show/1399/season/1');
  await tester.pumpAndSettle();
  expect(find.byType(SeasonScreen), findsOneWidget);
  return backend;
}

Checkbox _checkbox(WidgetTester tester, int id) =>
    tester.widget<Checkbox>(find.byKey(Key('episode.check.$id')));

void main() {
  testWidgets(
    'izlenen bölüm işaretli, gelecekteki bölümün kutusu pasif (F4a, F5d)',
    (tester) async {
      await _openSeason(tester, watched: {1});

      expect(_checkbox(tester, 1).value, isTrue);
      expect(_checkbox(tester, 2).value, isFalse);
      expect(_checkbox(tester, 3).onChanged, isNull);
    },
  );

  testWidgets(
    'işaret kutusu yalnızca işaretler, Bölüm Sonrası açılmaz (F5a, F5f, F4e)',
    (tester) async {
      final backend = await _openSeason(tester);
      when(() => backend.tracking.markEpisode(episodeId: 2, showId: 1399))
          .thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('episode.check.2')));
      await tester.pumpAndSettle();

      verify(() => backend.tracking.markEpisode(episodeId: 2, showId: 1399))
          .called(1);
      expect(find.byType(EpisodeScreen), findsNothing);
      expect(_checkbox(tester, 2).value, isTrue);

      // Banda dokunmak Bölüm Sonrası ekranını açar.
      await tester.tap(find.byKey(const Key('episode.banner.2')));
      await tester.pumpAndSettle();
      expect(find.byType(EpisodeScreen), findsOneWidget);
    },
  );

  testWidgets('işaret geri alınınca Bölüm Sonrası açılmaz (F5a)', (
    tester,
  ) async {
    final backend = await _openSeason(tester, watched: {1});
    when(() => backend.tracking.unmarkEpisode(1)).thenAnswer((_) async {});

    await tester.tap(find.byKey(const Key('episode.check.1')));
    await tester.pumpAndSettle();

    verify(() => backend.tracking.unmarkEpisode(1)).called(1);
    expect(find.byType(EpisodeScreen), findsNothing);
    expect(_checkbox(tester, 1).value, isFalse);
  });

  testWidgets('işaretleme hatası geri alınır ve ileti gösterilir (F5e)', (
    tester,
  ) async {
    final backend = await _openSeason(tester);
    when(() => backend.tracking.markEpisode(episodeId: 2, showId: 1399))
        .thenThrow(const AppFailure(AppFailureType.network));

    await tester.tap(find.byKey(const Key('episode.check.2')));
    await tester.pumpAndSettle();

    expect(find.text('Kaydedilemedi, tekrar dene.'), findsOneWidget);
    expect(_checkbox(tester, 2).value, isFalse);
  });

  testWidgets(
    'sezonun tamamı yayınlanmış bölümleri işaretler, ekran açmaz (F5b, F5f)',
    (tester) async {
      final backend = await _openSeason(tester);
      when(() => backend.tracking.markSeason(1399, 1)).thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('season.markAll')));
      await tester.pumpAndSettle();

      verify(() => backend.tracking.markSeason(1399, 1)).called(1);
      expect(find.byType(EpisodeScreen), findsNothing);
      expect(_checkbox(tester, 1).value, isTrue);
      expect(_checkbox(tester, 2).value, isTrue);
      expect(_checkbox(tester, 3).value, isFalse);
    },
  );

  testWidgets('uzun basınca "Buraya kadar izledim" (F5c)', (tester) async {
    final backend = await _openSeason(tester);
    when(() => backend.tracking.markEpisodesUntil(2)).thenAnswer((_) async {});

    await tester.longPress(find.byKey(const Key('episode.banner.2')));
    await tester.pumpAndSettle();
    when(() => backend.tracking.fetchWatchedEpisodeIds(1399))
        .thenAnswer((_) async => {1, 2});
    await tester.tap(find.byKey(const Key('episode.markUntil')));
    await tester.pumpAndSettle();

    verify(() => backend.tracking.markEpisodesUntil(2)).called(1);
    expect(find.byType(EpisodeScreen), findsNothing);
    expect(_checkbox(tester, 1).value, isTrue);
    expect(_checkbox(tester, 2).value, isTrue);
  });
}
