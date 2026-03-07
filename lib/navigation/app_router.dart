import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'main_scaffold.dart';

// Auth screens
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';

// Main tab screens
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/themes/screens/themes_screen.dart';
import '../features/quizzes/screens/quizzes_screen.dart';
import '../features/profile/screens/profile_screen.dart';

// Stack screens
import '../features/quizzes/screens/quiz_player_screen.dart';
import '../features/quizzes/screens/quiz_correction_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/legal/screens/terms_screen.dart';
import '../features/legal/screens/help_screen.dart';
import '../features/duels/screens/duels_screen.dart';
import '../features/duels/screens/duel_create_screen.dart';
import '../features/duels/screens/duel_join_screen.dart';
import '../features/duels/screens/duel_lobby_screen.dart';
import '../features/duels/screens/duel_play_screen.dart';
import '../features/duels/screens/duel_results_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main tabs
  static const String dashboard = '/';
  static const String themes = '/themes';
  static const String quizzes = '/quizzes';
  static const String profile = '/profile';

  // Stack routes
  static const String quizPlayer = '/quizzes/:quizId/play';
  static const String quizCorrection = '/quizzes/:quizId/correction';
  static const String leaderboard = '/leaderboard';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String terms = '/terms';
  static const String help = '/help';

  // Notifications
  static const String notifications = '/notifications';

  // Duels
  static const String duels = '/duels';
  static const String duelCreate = '/duels/create';
  static const String duelJoin = '/duels/join';
  static const String duelLobby = '/duels/lobby';
  static const String duelPlay = '/duels/play';
  static const String duelResults = '/duels/results';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildTransitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Listenable that notifies GoRouter when auth state changes,
/// without recreating the router instance.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
    _ref.listen(isAuthLoadingProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Read (not watch) current auth state inside redirect callback
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isLoading = ref.read(isAuthLoadingProvider);
      final currentPath = state.uri.path;

      // Don't redirect while loading
      if (isLoading) return null;

      final isAuthRoute = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath.startsWith('/verify-email') ||
          currentPath.startsWith('/reset-password');

      // Not authenticated → redirect to login (unless already on auth route)
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Don't redirect away from verify-email even if authenticated
      // (user just verified and will be redirected to dashboard by the screen itself)
      if (isAuthenticated && currentPath.startsWith('/verify-email')) {
        return null;
      }

      // Authenticated → redirect away from auth routes
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // ── Auth routes (no shell) ──
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // ── Main shell with BottomNavigationBar ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.themes,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ThemesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.quizzes,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuizzesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeaderboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.duels,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DuelsScreen(),
            ),
          ),
        ],
      ),

      // ── Stack routes (full screen, outside shell) ──
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.quizPlayer,
        pageBuilder: (context, state) {
          final quizId = state.pathParameters['quizId']!;
          return _buildTransitionPage(state, QuizPlayerScreen(quizId: quizId));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.quizCorrection,
        pageBuilder: (context, state) {
          final quizId = state.pathParameters['quizId']!;
          return _buildTransitionPage(state, QuizCorrectionScreen(quizId: quizId));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.terms,
        pageBuilder: (context, state) => _buildTransitionPage(state, const TermsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.help,
        pageBuilder: (context, state) => _buildTransitionPage(state, const HelpScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildTransitionPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.duelCreate,
        pageBuilder: (context, state) => _buildTransitionPage(state, const DuelCreateScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.duelJoin,
        pageBuilder: (context, state) => _buildTransitionPage(state, const DuelJoinScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.duelLobby,
        pageBuilder: (context, state) => _buildTransitionPage(state, const DuelLobbyScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.duelPlay,
        pageBuilder: (context, state) => _buildTransitionPage(state, const DuelPlayScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.duelResults,
        pageBuilder: (context, state) => _buildTransitionPage(state, const DuelResultsScreen()),
      ),
    ],
  );
});
