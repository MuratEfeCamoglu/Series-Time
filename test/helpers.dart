import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/preferences.dart';
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
import 'package:sezonluk/features/suggest/data/repository.dart';
import 'package:sezonluk/features/suggest/providers.dart';
import 'package:sezonluk/features/tracking/data/repository.dart';
import 'package:sezonluk/features/tracking/providers.dart';
import 'package:sezonluk/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockShowsRepository extends Mock implements ShowsRepository {}

class MockSocialRepository extends Mock implements SocialRepository {}

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockSuggestRepository extends Mock implements SuggestRepository {}

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
    when(() => profiles.fetchStats(any())).thenAnswer(
      (_) async => const UserStats(watchedEpisodes: 0, watchMinutes: 0),
    );
    when(() => suggest.fetchGenres()).thenAnswer((_) async => const []);
    when(() => suggest.topGenres()).thenAnswer((_) async => const []);
    when(() => tracking.fetchWatchlist()).thenAnswer((_) async => const []);
    when(() => tracking.fetchUpcoming(any())).thenAnswer((_) async => const []);
    when(() => tracking.fetchWatchedEpisodeIds(any()))
        .thenAnswer((_) async => <int>{});
  }

  final auth = MockAuthRepository();
  final profiles = MockProfileRepository();
  final shows = MockShowsRepository();
  final social = MockSocialRepository();
  final tracking = MockTrackingRepository();
  final suggest = MockSuggestRepository();
  late SharedPreferences preferences;
  final statusController = StreamController<AuthStatus>.broadcast();

  /// Oturum değişimini taklit eder; yönlendirici bu değere göre çalışır.
  void emit(AuthStatus status) {
    when(() => auth.currentUserId)
        .thenReturn(status == AuthStatus.signedOut ? null : testUserId);
    statusController.add(status);
  }

  /// [preferenceValues]: cihazda önceden saklanmış tercihler.
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> preferenceValues = const {},
  }) async {
    addTearDown(statusController.close);
    SharedPreferences.setMockInitialValues(preferenceValues);
    preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
          showsRepositoryProvider.overrideWithValue(shows),
          socialRepositoryProvider.overrideWithValue(social),
          trackingRepositoryProvider.overrideWithValue(tracking),
          suggestRepositoryProvider.overrideWithValue(suggest),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const SezonlukApp(),
      ),
    );
    await tester.pumpAndSettle();
  }
}
