import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/logic.dart';
import '../features/auth/providers.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/discover/screens/discover_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/tracking/screens/shows_screen.dart';
import 'shell.dart';

abstract final class AppRoutes {
  static const shows = '/shows';
  static const discover = '/discover';
  static const profile = '/profile';
  static const settings = '/settings';
  static const editProfile = '/settings/profile';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
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
            path: 'profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
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
