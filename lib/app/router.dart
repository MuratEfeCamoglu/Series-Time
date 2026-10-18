import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/logic.dart';
import '../features/auth/providers.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/badges/screens/badges_screen.dart';
import '../features/discover/screens/discover_screen.dart';
import '../features/discover/screens/discover_search_screen.dart';
import '../features/moderation/screens/blocked_users_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/episode_feedback/screens/episode_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/user_profile_screen.dart';
import '../features/profile/screens/user_shows_screen.dart';
import '../features/settings/screens/about_screen.dart';
import '../features/settings/screens/app_icon_settings_screen.dart';
import '../features/settings/screens/color_settings_screen.dart';
import '../features/settings/screens/language_settings_screen.dart';
import '../features/settings/screens/delete_account_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/shows/screens/season_screen.dart';
import '../features/social/logic.dart';
import '../features/social/screens/follow_list_screen.dart';
import '../features/shows/screens/show_detail_screen.dart';
import '../features/suggest/screens/suggest_screen.dart';
import '../features/tracking/screens/shows_screen.dart';
import 'shell.dart';

abstract final class AppRoutes {
  static const shows = '/shows';
  static const discover = '/discover';
  static const discoverSearch = '/discover/search';
  static const profile = '/profile';
  static const settings = '/settings';
  static const editProfile = '/settings/profile';
  static const blockedUsers = '/settings/blocked';
  static const about = '/settings/about';
  static const colorSettings = '/settings/colors';
  static const appIconSettings = '/settings/icon';
  static const languageSettings = '/settings/language';
  static const deleteAccount = '/settings/delete-account';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const suggest = '/suggest';

  static String showDetail(int showId) => '/show/$showId';
  static String season(int showId, int seasonNumber) =>
      '/show/$showId/season/$seasonNumber';
  static String episode(int episodeId) => '/episode/$episodeId';
  static String userProfile(String username) => '/user/$username';

  /// [status]: "Tümü" ekranı bu grupla süzülü açılır (F8e).
  static String userShows(String username, {String? status}) => status == null
      ? '/user/$username/shows'
      : '/user/$username/shows?status=$status';
  static String followers(String username) => '/user/$username/followers';
  static String following(String username) => '/user/$username/following';
  static const notifications = '/notifications';

  /// Rozet rafı; [username] verilmezse oturum sahibininki.
  static String badges([String? username]) =>
      username == null ? '/badges' : '/badges?user=$username';
}

const _authRoutes = {
  AppRoutes.signIn,
  AppRoutes.signUp,
  AppRoutes.forgotPassword,
};

final routerProvider = Provider<GoRouter>((ref) {
  // Yönlendirici bir kez kurulur; oturum değişince yalnızca `redirect` yeniden çalışır.
  final authStatus = ValueNotifier(ref.read(authStatusProvider));
  ref.listen(authStatusProvider, (_, next) => authStatus.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.shows,
    refreshListenable: authStatus,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final target = authRedirect(
        status: authStatus.value,
        isAuthRoute: _authRoutes.contains(path),
        isResetRoute: path == AppRoutes.resetPassword,
      );
      return switch (target) {
        AuthRedirect.none => null,
        AuthRedirect.signIn => AppRoutes.signIn,
        AuthRedirect.home => AppRoutes.shows,
        AuthRedirect.resetPassword => AppRoutes.resetPassword,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'colors',
            builder: (context, state) => const ColorSettingsScreen(),
          ),
          GoRoute(
            path: 'icon',
            builder: (context, state) => const AppIconSettingsScreen(),
          ),
          GoRoute(
            path: 'language',
            builder: (context, state) => const LanguageSettingsScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'blocked',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: 'delete-account',
            builder: (context, state) => const DeleteAccountScreen(),
          ),
        ],
      ),
      // Detay ekranları alt menünün üstünde açılır.
      GoRoute(
        path: '/show/:id',
        redirect: (context, state) =>
            _intParam(state, 'id') == null ? AppRoutes.shows : null,
        builder: (context, state) => ShowDetailScreen(
          showId: _intParam(state, 'id')!,
          heroTag: switch (state.extra) {
            final String tag => tag,
            _ => null,
          },
        ),
        routes: [
          GoRoute(
            path: 'season/:season',
            redirect: (context, state) =>
                _intParam(state, 'season') == null ? AppRoutes.shows : null,
            builder: (context, state) => SeasonScreen(
              showId: _intParam(state, 'id')!,
              seasonNumber: _intParam(state, 'season')!,
              title: state.extra as String?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.suggest,
        builder: (context, state) => const SuggestScreen(),
      ),
      GoRoute(
        path: '/user/:username',
        builder: (context, state) =>
            UserProfileScreen(username: state.pathParameters['username']!),
        routes: [
          GoRoute(
            path: 'shows',
            builder: (context, state) => UserShowsScreen(
              username: state.pathParameters['username']!,
              initialStatus: state.uri.queryParameters['status'],
            ),
          ),
          GoRoute(
            path: 'followers',
            builder: (context, state) => FollowListScreen(
              username: state.pathParameters['username']!,
              list: FollowList.followers,
            ),
          ),
          GoRoute(
            path: 'following',
            builder: (context, state) => FollowListScreen(
              username: state.pathParameters['username']!,
              list: FollowList.following,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) =>
            BadgesScreen(username: state.uri.queryParameters['user']),
      ),
      GoRoute(
        path: '/episode/:id',
        redirect: (context, state) =>
            _intParam(state, 'id') == null ? AppRoutes.shows : null,
        builder: (context, state) =>
            EpisodeScreen(episodeId: _intParam(state, 'id')!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shows,
                builder: (context, state) => const ShowsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const DiscoverScreen(),
                // Arama Keşfet sekmesinin içinde açılır; alt menü görünür kalır.
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const DiscoverSearchScreen(),
                  ),
                ],
              ),
            ],
          ),
          // F13(f): Bildirimler, Keşfet ile Profil arasında.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    authStatus.dispose();
  });
  return router;
});

int? _intParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '');
