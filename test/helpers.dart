import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/features/auth/data/repository.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/auth/providers.dart';
import 'package:sezonluk/features/profile/data/models.dart';
import 'package:sezonluk/features/profile/data/repository.dart';
import 'package:sezonluk/features/profile/providers.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/data/repository.dart';
import 'package:sezonluk/features/shows/providers.dart';
import 'package:sezonluk/features/social/data/repository.dart';
import 'package:sezonluk/features/social/providers.dart';
import 'package:sezonluk/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockShowsRepository extends Mock implements ShowsRepository {}

class MockSocialRepository extends Mock implements SocialRepository {}

const testUserId = '11111111-1111-1111-1111-111111111111';

final testProfile = Profile(
  id: testUserId,
  username: 'ayse_1',
  displayName: 'Ayşe',
  bio: 'Dizi kurdu',
  countryCode: 'TR',
  createdAt: DateTime.utc(2026, 10, 1),
);

final testShow = Show(
  id: 1399,
  name: 'Taht Oyunları',
  posterPath: '/poster.jpg',
  status: 'Ended',
  overview: 'Yedi krallık...',
  firstAirDate: DateTime.utc(2011, 4, 17),
);

/// Gerçek Supabase'e bağlanmadan uygulamayı açmak için taklit repository'ler.
class TestBackend {
  TestBackend({AuthStatus initialStatus = AuthStatus.signedIn}) {
    when(() => auth.currentStatus).thenReturn(initialStatus);
    when(() => auth.currentUserId)
        .thenReturn(initialStatus == AuthStatus.signedOut ? null : testUserId);
    when(() => auth.statusChanges()).thenAnswer((_) => statusController.stream);
    when(() => profiles.fetchProfile(testUserId))
        .thenAnswer((_) async => testProfile);
    when(() => profiles.avatarUrl(any()))
        .thenReturn('https://example.test/a.jpg');
    when(() => shows.fetchMyShows()).thenAnswer((_) async => const []);
    when(() => shows.trendingShows()).thenAnswer((_) async => const []);
  }

  final auth = MockAuthRepository();
  final profiles = MockProfileRepository();
  final shows = MockShowsRepository();
  final social = MockSocialRepository();
  final statusController = StreamController<AuthStatus>.broadcast();

  /// Oturum değişimini taklit eder; yönlendirici bu değere göre çalışır.
  void emit(AuthStatus status) {
    when(() => auth.currentUserId)
        .thenReturn(status == AuthStatus.signedOut ? null : testUserId);
    statusController.add(status);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    addTearDown(statusController.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
          showsRepositoryProvider.overrideWithValue(shows),
          socialRepositoryProvider.overrideWithValue(social),
        ],
        child: const SezonlukApp(),
      ),
    );
    await tester.pumpAndSettle();
  }
}
