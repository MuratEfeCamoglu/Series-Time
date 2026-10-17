import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/preferences.dart';
import 'package:sezonluk/features/auth/data/repository.dart';
import 'package:sezonluk/features/auth/logic.dart';
import 'package:sezonluk/features/auth/providers.dart';
import 'package:sezonluk/features/badges/data/repository.dart';
import 'package:sezonluk/features/badges/providers.dart';
import 'package:sezonluk/features/episode_feedback/data/models.dart';
import 'package:sezonluk/features/episode_feedback/data/repository.dart';
import 'package:sezonluk/features/episode_feedback/providers.dart';
import 'package:sezonluk/features/moderation/data/repository.dart';
import 'package:sezonluk/features/moderation/providers.dart';
import 'package:sezonluk/features/notifications/data/repository.dart';
import 'package:sezonluk/features/notifications/providers.dart';
import 'package:sezonluk/features/profile/data/models.dart';
import 'package:sezonluk/features/profile/data/repository.dart';
import 'package:sezonluk/features/profile/providers.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/data/repository.dart';
import 'package:sezonluk/features/shows/providers.dart';
import 'package:sezonluk/features/social/data/repository.dart';
import 'package:sezonluk/features/social/data/models.dart';
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

class MockEpisodeFeedbackRepository extends Mock
    implements EpisodeFeedbackRepository {}

class MockModerationRepository extends Mock implements ModerationRepository {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockBadgesRepository extends Mock implements BadgesRepository {}

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

/// Varsayılan Bölüm Sonrası ekranı bölümü (dizi 1399, S01B01).
final testEpisodeInfo = EpisodeInfo(
  episode: Episode(
    id: 100,
    showId: 1399,
    seasonNumber: 1,
    episodeNumber: 1,
    name: 'Kış Geliyor',
    airDate: DateTime.utc(2011, 4, 17),
  ),
  showName: 'Taht Oyunları',
);

/// Gerçek Supabase'e bağlanmadan uygulamayı açmak için taklit repository'ler.
class TestBackend {
  TestBackend({AuthStatus initialStatus = AuthStatus.signedIn}) {
    registerFallbackValue(DateTime.utc(2000));
    registerFallbackValue(ReactionType.funny);
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
    when(() => shows.popularShows()).thenAnswer((_) async => const []);
    when(() => shows.fetchShowCast(any())).thenAnswer((_) async => const []);
    when(() => shows.onTheAirShows()).thenAnswer((_) async => const []);
    when(() => shows.fetchCachedEpisodes(any()))
        .thenAnswer((_) async => const []);
    when(() => profiles.fetchRatingDistribution(any()))
        .thenAnswer((_) async => const []);
    when(() => profiles.fetchStats(any())).thenAnswer(
      (_) async => const UserStats(watchedEpisodes: 0, watchMinutes: 0),
    );
    when(() => suggest.fetchGenres()).thenAnswer((_) async => const []);
    when(() => feedback.currentUserId).thenReturn(testUserId);
    when(() => feedback.fetchEpisodeInfo(any()))
        .thenAnswer((invocation) async => testEpisodeInfo);
    when(() => feedback.fetchMyReaction(any())).thenAnswer((_) async => null);
    when(() => feedback.fetchRatingSummary(any())).thenAnswer(
      (_) async =>
          const RatingSummary(ratingCount: 0, likeCount: 0, liked: false),
    );
    when(() => shows.fetchShowImages(any()))
        .thenAnswer((_) async => const ShowImages());
    when(() => feedback.fetchReactionCounts(any()))
        .thenAnswer((_) async => const {});
    when(() => feedback.fetchCredits(any())).thenAnswer((_) async => const []);
    when(() => feedback.fetchMyStarVote(any())).thenAnswer((_) async => null);
    when(() => feedback.fetchStarStats(any()))
        .thenAnswer((_) async => const []);
    when(() => feedback.fetchComments(any(), before: any(named: 'before')))
        .thenAnswer((_) async => const []);
    when(() => moderation.fetchBlockedUsers())
        .thenAnswer((_) async => const []);
    when(() => social.currentUserId).thenReturn(testUserId);
    when(() => social.fetchCounts(any())).thenAnswer(
      (_) async => const ProfileCounts(followers: 0, following: 0, badges: 0),
    );
    when(() => social.isFollowing(any())).thenAnswer((_) async => false);
    when(() => social.fetchFriendsActivity()).thenAnswer((_) async => const []);
    when(() => notifications.fetchUnreadCount()).thenAnswer((_) async => 0);
    when(() => notifications.fetchNotifications())
        .thenAnswer((_) async => const []);
    when(() => notifications.markAllRead()).thenAnswer((_) async {});
    when(() => badges.fetchBadges()).thenAnswer((_) async => const []);
    when(() => badges.fetchEarned(any())).thenAnswer((_) async => const []);
    when(() => suggest.topGenres()).thenAnswer((_) async => const []);
    when(() => tracking.fetchWatchlist()).thenAnswer((_) async => const []);
    when(() => tracking.fetchShowProgress(any()))
        .thenAnswer((_) async => const []);
    when(() => tracking.fetchRecentActivity(any()))
        .thenAnswer((_) async => const []);
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
  final feedback = MockEpisodeFeedbackRepository();
  final moderation = MockModerationRepository();
  final notifications = MockNotificationsRepository();
  final badges = MockBadgesRepository();
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
          episodeFeedbackRepositoryProvider.overrideWithValue(feedback),
          moderationRepositoryProvider.overrideWithValue(moderation),
          notificationsRepositoryProvider.overrideWithValue(notifications),
          badgesRepositoryProvider.overrideWithValue(badges),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const SezonlukApp(),
      ),
    );
    await tester.pumpAndSettle();
  }
}
