import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/moderation/logic.dart';
import 'package:sezonluk/features/profile/data/models.dart';
import 'package:sezonluk/features/profile/screens/user_profile_screen.dart';
import 'package:sezonluk/features/social/data/models.dart';
import 'package:sezonluk/features/social/logic.dart';
import 'package:sezonluk/features/social/screens/follow_list_screen.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

const _otherId = '22222222-2222-2222-2222-222222222222';

final _other = Profile(
  id: _otherId,
  username: 'burak',
  displayName: 'Burak',
  bio: '',
  createdAt: DateTime.utc(2026, 1, 1),
);

FollowListEntry _entry(int i) => FollowListEntry(
  userId: 'u$i',
  username: 'kisi$i',
  displayName: 'Kişi $i',
  followedAt: DateTime.utc(2026, 10, 1),
);

Future<TestBackend> _openOtherProfile(
  WidgetTester tester, {
  ProfileCounts counts = const ProfileCounts(
    followers: 4,
    following: 2,
    badges: 1,
  ),
  bool following = false,
}) async {
  tester.view
    ..physicalSize = const Size(800, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = TestBackend();
  when(() => backend.profiles.fetchProfileByUsername('burak'))
      .thenAnswer((_) async => _other);
  when(() => backend.shows.fetchUserShows(_otherId))
      .thenAnswer((_) async => const []);
  when(() => backend.profiles.fetchStats(_otherId)).thenAnswer(
    (_) async => const UserStats(watchedEpisodes: 0, watchMinutes: 0),
  );
  when(() => backend.social.fetchCounts(_otherId))
      .thenAnswer((_) async => counts);
  when(() => backend.social.isFollowing(_otherId))
      .thenAnswer((_) async => following);
  await backend.pumpApp(tester);
  GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/user/burak');
  await tester.pumpAndSettle();
  expect(find.byType(UserProfileScreen), findsOneWidget);
  return backend;
}

void main() {
  testWidgets('kullanıcı aramasından profil açılır (F12a)', (tester) async {
    final backend = TestBackend();
    when(() => backend.social.searchUsers('bu'))
        .thenAnswer((_) async => [_other]);
    when(() => backend.profiles.fetchProfileByUsername('burak'))
        .thenAnswer((_) async => _other);
    when(() => backend.shows.fetchUserShows(_otherId))
        .thenAnswer((_) async => const []);
    await backend.pumpApp(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Keşfet'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kullanıcılar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('discover.search')), 'bu');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    await tester.tap(find.text('@burak'));
    await tester.pumpAndSettle();
    expect(find.byType(UserProfileScreen), findsOneWidget);
  });

  testWidgets(
    'başka profilde "Düzenle" yerine "Takip et", zil yerine menü (F12a)',
    (tester) async {
      await _openOtherProfile(tester);

      expect(find.text('Takip et'), findsOneWidget);
      expect(find.text('Düzenle'), findsNothing);
      expect(find.byKey(const Key('profile.bell')), findsNothing);
      expect(find.byKey(const Key('profile.menu')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('profile.followers')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('takip etmek sayıya beklemeden yansır (F12b)', (tester) async {
    final backend = await _openOtherProfile(tester);
    final request = Completer<void>();
    when(() => backend.social.setFollowing(_otherId, follow: true))
        .thenAnswer((_) => request.future);

    await tester.tap(find.byKey(const Key('profile.follow')));
    await tester.pump();

    expect(find.text('Takip ediliyor'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile.followers')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
    request.complete();
    await tester.pumpAndSettle();
    verify(() => backend.social.setFollowing(_otherId, follow: true)).called(1);
  });

  testWidgets('takip bırakma hatası geri alınır', (tester) async {
    final backend = await _openOtherProfile(tester, following: true);
    when(() => backend.social.setFollowing(_otherId, follow: false))
        .thenThrow(const AppFailure(AppFailureType.network));

    await tester.tap(find.byKey(const Key('profile.follow')));
    await tester.pumpAndSettle();

    expect(find.text('Takip ediliyor'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile.followers')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
    expect(find.text('Kaydedilemedi, tekrar dene.'), findsOneWidget);
  });

  testWidgets('takipçi listesi 30\'arlı sayfalarla yüklenir (F12c)', (
    tester,
  ) async {
    final backend = await _openOtherProfile(tester);
    when(() => backend.social.fetchFollowList(_otherId, FollowList.followers))
        .thenAnswer((_) async => [for (var i = 0; i < 30; i++) _entry(i)]);
    when(
      () => backend.social.fetchFollowList(
        _otherId,
        FollowList.followers,
        offset: 30,
      ),
    ).thenAnswer((_) async => [_entry(30)]);

    await tester.tap(find.byKey(const Key('profile.followers')));
    await tester.pumpAndSettle();
    expect(find.byType(FollowListScreen), findsOneWidget);
    expect(find.text('Takipçiler'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -5000), 5000);
    await tester.pumpAndSettle();

    verify(
      () => backend.social.fetchFollowList(
        _otherId,
        FollowList.followers,
        offset: 30,
      ),
    ).called(1);
  });

  testWidgets('profil şikayet edilir (F15a)', (tester) async {
    final backend = await _openOtherProfile(tester);
    when(
      () => backend.moderation.report(
        target: ReportTarget.profile,
        targetId: _otherId,
        reason: ReportReason.spam,
      ),
    ).thenAnswer((_) async {});

    await tester.tap(find.byKey(const Key('profile.menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Şikayet et'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report.spam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report.send')));
    await tester.pumpAndSettle();

    verify(
      () => backend.moderation.report(
        target: ReportTarget.profile,
        targetId: _otherId,
        reason: ReportReason.spam,
      ),
    ).called(1);
    expect(find.text('Şikayetin alındı. İnceleyeceğiz.'), findsOneWidget);
  });

  testWidgets('profilden engellenir ve profil kapanır (F15b)', (tester) async {
    final backend = await _openOtherProfile(tester);
    when(() => backend.moderation.block(_otherId)).thenAnswer((_) async {});

    await tester.tap(find.byKey(const Key('profile.menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engelle'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm.ok')));
    await tester.pumpAndSettle();

    verify(() => backend.moderation.block(_otherId)).called(1);
    expect(find.byType(UserProfileScreen), findsNothing);
    expect(find.text('Burak engellendi.'), findsOneWidget);
  });
}
