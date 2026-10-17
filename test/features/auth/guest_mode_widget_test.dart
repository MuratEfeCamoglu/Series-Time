import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/auth/screens/sign_in_screen.dart';
import 'package:sezonluk/features/auth/screens/sign_up_screen.dart';
import 'package:sezonluk/features/discover/screens/discover_screen.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/shared/widgets/guest_gate.dart';

import '../../helpers.dart';

Finder _navLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

void main() {
  testWidgets('giriş ekranından misafir olarak Keşfet açılır (F19a)', (
    tester,
  ) async {
    final backend = TestBackend(initialStatus: AuthStatus.signedOut);
    when(() => backend.auth.signInAsGuest()).thenAnswer((_) async {
      backend.emit(AuthStatus.guest);
    });
    await backend.pumpApp(tester);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('signIn.guest')));
    await tester.pumpAndSettle();

    verify(() => backend.auth.signInAsGuest()).called(1);
    expect(find.byType(DiscoverScreen), findsOneWidget);
  });

  testWidgets(
    'misafir Diziler ve Profil sekmelerinde hesap çağrısı görür, veri çekilmez (F19c)',
    (tester) async {
      final backend = TestBackend(initialStatus: AuthStatus.guest);
      await backend.pumpApp(tester);

      expect(find.byType(GuestGate), findsOneWidget);
      await tester.tap(_navLabel('Profil'));
      await tester.pumpAndSettle();
      expect(find.byType(GuestGate), findsOneWidget);
      expect(find.text('Bu özellik için hesap oluştur'), findsOneWidget);

      verifyNever(() => backend.shows.fetchMyShows());
      verifyNever(() => backend.tracking.fetchWatchlist());
      verifyNever(() => backend.profiles.fetchProfile(any()));
      verifyNever(() => backend.notifications.fetchUnreadCount());
    },
  );

  testWidgets('hesap çağrısındaki "Kayıt ol" kayıt ekranını açar (F19e)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await TestBackend(initialStatus: AuthStatus.guest).pumpApp(tester);

    await tester.tap(find.byKey(const Key('guestGate.signUp')));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets(
    'misafir dizi detayını görür; "Ekle" ve bölüm işaretleme hesap ister (F19b, F19c)',
    (tester) async {
      final backend = TestBackend(initialStatus: AuthStatus.guest);
      when(() => backend.shows.fetchShow(1399)).thenAnswer(
        (_) async => ShowDetail(
          show: testShow,
          seasons: const [
            Season(id: 2, showId: 1399, seasonNumber: 1, name: '1. Sezon'),
          ],
        ),
      );
      when(() => backend.shows.fetchSeasonEpisodes(1399, 1)).thenAnswer(
        (_) async => [
          Episode(
            id: 1,
            showId: 1399,
            seasonNumber: 1,
            episodeNumber: 1,
            name: 'Kış Geliyor',
            airDate: DateTime.utc(2011, 4, 17),
          ),
        ],
      );
      await backend.pumpApp(tester);
      GoRouter.of(tester.element(find.byType(GuestGate))).push('/show/1399');
      await tester.pumpAndSettle();

      expect(find.text('Taht Oyunları'), findsWidgets);
      await tester.tap(find.byKey(const Key('showDetail.add')));
      await tester.pumpAndSettle();
      expect(find.byType(GuestGate), findsWidgets);
      verifyNever(() => backend.shows.addToMyShows(any()));
      Navigator.of(tester.element(find.byType(GuestGate).last)).pop();
      await tester.pumpAndSettle();

      // Sezon kartı yerinde açılır; bölüm bandı aşağıda kalabilir.
      await tester.tap(find.text('1. Sezon'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('episode.check.1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('episode.check.1')));
      await tester.pumpAndSettle();
      expect(find.text('Bu özellik için hesap oluştur'), findsWidgets);
      verifyNever(
        () => backend.tracking.markEpisode(
          episodeId: any(named: 'episodeId'),
          showId: any(named: 'showId'),
        ),
      );
    },
  );
}
