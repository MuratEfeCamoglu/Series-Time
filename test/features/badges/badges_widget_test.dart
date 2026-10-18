import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/badges/data/models.dart';
import 'package:sezonluk/features/badges/logic.dart';
import 'package:sezonluk/features/badges/screens/badges_screen.dart';
import 'package:sezonluk/features/badges/widgets/badge_medal.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

const _genreBadges = [
  BadgeInfo(
    code: 'genre_18_1',
    name: 'Dram Meraklısı',
    description: 'k',
    icon: 'genre',
  ),
  BadgeInfo(
    code: 'genre_18_5',
    name: 'Dram Tutkunu',
    description: 'k',
    icon: 'genre',
  ),
  BadgeInfo(
    code: 'genre_18_10',
    name: 'Dram Ustası',
    description: 'k',
    icon: 'genre',
  ),
];

class _FakeRefs extends Fake implements List<BadgeRef> {}

Future<TestBackend> _openBadges(
  WidgetTester tester, {
  List<FeaturedBadge> featured = const [],
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = TestBackend();
  when(() => backend.badges.fetchBadges())
      .thenAnswer((_) async => _genreBadges);
  when(() => backend.badges.fetchEarned(testUserId)).thenAnswer(
    (_) async => [
      EarnedBadge(code: 'genre_18_1', earnedAt: DateTime.utc(2026, 10, 18)),
    ],
  );
  when(() => backend.badges.fetchShowBadges(testUserId)).thenAnswer(
    (_) async => [
      ShowBadge(
        showId: 1399,
        seasonNumber: 0,
        showName: 'Taht Oyunları',
        posterPath: '/p.jpg',
        earnedAt: DateTime.utc(2026, 10, 18),
      ),
      ShowBadge(
        showId: 1399,
        seasonNumber: 2,
        showName: 'Taht Oyunları',
        earnedAt: DateTime.utc(2026, 10, 17),
      ),
    ],
  );
  when(() => backend.badges.fetchFeatured(testUserId))
      .thenAnswer((_) async => featured);
  when(() => backend.badges.setFeatured(any())).thenAnswer((_) async {});
  await backend.pumpApp(tester);
  GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/badges');
  await tester.pumpAndSettle();
  expect(find.byType(BadgesScreen), findsOneWidget);
  return backend;
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeRefs()));

  testWidgets(
    'dizi ve sezon rozetleri afişli madalyon, tür rozetleri kademeli (F14)',
    (tester) async {
      await _openBadges(tester);

      expect(find.text('Dizi rozetleri (2)'), findsOneWidget);
      expect(find.text('Taht Oyunları · Final'), findsOneWidget);
      expect(find.text('Taht Oyunları · 2. Sezon'), findsOneWidget);
      expect(find.byType(ShowBadgeMedal), findsNWidgets(2));
      expect(find.text('FİNAL'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);

      expect(find.byKey(const Key('genreBadges.18')), findsOneWidget);
      expect(find.text('Dram Meraklısı'), findsOneWidget);
      expect(find.text('Dram Ustası'), findsOneWidget);
      // Kazanılmamış kademe koşuluyla görünür.
      expect(
        find.text('Dram türünde bitmiş 10 dizinin tüm bölümlerini izle.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('kazanılan rozete dokununca vitrine eklenir (F14)', (
    tester,
  ) async {
    final backend = await _openBadges(tester);

    await tester.tap(find.byKey(const Key('showBadge.1399.0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('badge.genre_18_1')));
    await tester.pumpAndSettle();

    final calls = verify(() => backend.badges.setFeatured(captureAny()))
        .captured;
    expect(calls.last, [
      const BadgeRef.show(1399, 0),
      const BadgeRef.general('genre_18_1'),
    ]);
    expect(
      find.text('Profil vitrinine eklemek için kazandığın rozete dokun (2/6).'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.push_pin), findsNWidgets(2));

    // Kazanılmamış rozet seçilemez.
    await tester.tap(find.byKey(const Key('badge.genre_18_5')));
    await tester.pumpAndSettle();
    verifyNever(
      () => backend.badges.setFeatured([
        const BadgeRef.show(1399, 0),
        const BadgeRef.general('genre_18_1'),
        const BadgeRef.general('genre_18_5'),
      ]),
    );
  });

  testWidgets('vitrin doluyken yedinci rozet eklenmez (F14)', (tester) async {
    final backend = await _openBadges(
      tester,
      featured: [
        for (var i = 1; i <= 6; i++)
          FeaturedBadge(position: i, showId: 100 + i, seasonNumber: 1),
      ],
    );

    await tester.tap(find.byKey(const Key('showBadge.1399.0')));
    await tester.pumpAndSettle();

    expect(find.text('En fazla 6 rozet seçebilirsin'), findsOneWidget);
    verifyNever(() => backend.badges.setFeatured(any()));
  });
}
