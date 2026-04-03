import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/service_locator.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/reading_goal_screen.dart';
import '../../features/auth/screens/genre_selection_screen.dart';
import '../../features/auth/screens/reading_time_screen.dart';
import '../../features/reader_profile/screens/reader_profile_onboarding_screen.dart';
import '../../features/reader_profile/screens/reader_profile_quiz_screen.dart';
import '../../features/reader_profile/screens/reader_profile_detail_screen.dart';
import '../../features/shell/screens/shell_screen.dart';
import '../../features/home/screens/home_tab.dart';
import '../../features/library/screens/library_tab.dart';
import '../../features/library/screens/book_search_screen.dart';
import '../../features/library/screens/book_detail_screen.dart';
import '../../features/focus/screens/focus_tab.dart';
import '../../features/discover/screens/discover_tab.dart';
import '../../features/profile/screens/profile_tab.dart';
import '../../features/league/screens/league_screen.dart';
import '../../features/profile/screens/notification_settings_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/badge_collection_screen.dart';
import '../../features/discover/screens/challenge_detail_screen.dart';
import '../../features/discover/screens/create_challenge_screen.dart';
import '../../features/profile/screens/how_it_works_screen.dart';
import '../../features/profile/screens/daily_goal_screen.dart';
import '../../features/friends/screens/friends_screen.dart';
import '../../features/home/screens/streak_detail_screen.dart';
import '../../features/inbox/screens/inbox_screen.dart';

class AppRouter {
  AppRouter._();

  static const _onboardingPaths = {
    '/reading-goal',
    '/genre-selection',
    '/reading-time',
    '/reader-profile-onboarding',
  };

  static const _authPaths = {'/', '/sign-up', '/sign-in'};

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthNotifier(getIt<AuthService>()),
    redirect: (context, state) async {
      final authService = getIt<AuthService>();
      final isLoggedIn = authService.currentUser != null;
      final location = state.matchedLocation;

      // Allow onboarding screens for logged-in users
      if (_onboardingPaths.contains(location)) {
        return null;
      }

      final isAuthRoute = _authPaths.contains(location);

      if (isLoggedIn && isAuthRoute) {
        final completed =
            await getIt<UserProfileService>().isOnboardingCompleted();
        return completed ? '/home' : '/reading-goal';
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),

      // Onboarding routes
      GoRoute(
        path: '/reading-goal',
        builder: (context, state) => const ReadingGoalScreen(),
      ),
      GoRoute(
        path: '/genre-selection',
        builder: (context, state) => const GenreSelectionScreen(),
      ),
      GoRoute(
        path: '/reading-time',
        builder: (context, state) => const ReadingTimeScreen(),
      ),
      GoRoute(
        path: '/reader-profile-onboarding',
        builder: (context, state) => const ReaderProfileOnboardingScreen(),
      ),
      GoRoute(
        path: '/reader-profile-quiz',
        builder: (context, state) => const ReaderProfileQuizScreen(),
      ),

      // Shell navigation (bottom tabs)
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeTab(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryTab(),
            ),
          ),
          GoRoute(
            path: '/focus',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FocusTab(),
            ),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoverTab(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileTab(),
            ),
          ),
        ],
      ),

      // Non-shell routes
      GoRoute(
        path: '/book-search',
        builder: (context, state) => const BookSearchScreen(),
      ),
      GoRoute(
        path: '/book/:bookId',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return BookDetailScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/league',
        builder: (context, state) => const LeagueScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          final name = state.extra as String? ?? '';
          return EditProfileScreen(currentDisplayName: name);
        },
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgeCollectionScreen(),
      ),
      GoRoute(
        path: '/how-it-works',
        builder: (context, state) => const HowItWorksScreen(),
      ),
      GoRoute(
        path: '/challenge/:challengeId',
        builder: (context, state) {
          final id = state.pathParameters['challengeId']!;
          return ChallengeDetailScreen(challengeId: id);
        },
      ),
      GoRoute(
        path: '/create-challenge',
        builder: (context, state) => const CreateChallengeScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/reader-profile-detail',
        builder: (context, state) => const ReaderProfileDetailScreen(),
      ),
      GoRoute(
        path: '/streak',
        builder: (context, state) => const StreakDetailScreen(),
      ),
      GoRoute(
        path: '/daily-goal',
        pageBuilder: (context, state) {
          final currentGoal = state.extra as int? ?? 20;
          return MaterialPage(
            fullscreenDialog: true,
            child: DailyGoalScreen(currentGoal: currentGoal),
          );
        },
      ),
    ],
  );
}

class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription _subscription;

  _AuthNotifier(AuthService authService) {
    _subscription = authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
