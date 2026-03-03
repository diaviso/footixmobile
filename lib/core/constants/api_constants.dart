import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (kDebugMode) {
      // Local backend for development
      // Web → localhost:3000 | Android emulator → 10.0.2.2:3000
      if (kIsWeb) {
        return 'http://localhost:3000';
      }
      return 'http://10.0.2.2:3000';
    }
    return 'https://footixbackend.up.railway.app';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String profile = '/auth/profile';
  static const String uploadAvatar = '/auth/profile/avatar';
  static const String googleMobileLogin = '/auth/google/mobile';
  static const String leaderboardVisibility = '/auth/leaderboard-visibility';
  static const String resendVerification = '/auth/resend-verification';
  static const String checkSession = '/auth/check-session';
  static const String deleteAccount = '/auth/account';

  // Themes
  static const String themes = '/themes';

  // Quizzes
  static const String quizzes = '/quizzes';
  static const String quizzesWithStatus = '/quizzes/with-status';
  static const String quizAttempts = '/quizzes/attempts';
  static const String submitQuiz = '/quizzes/submit';
  static const String purchaseAttempt = '/quizzes/purchase-attempt';

  // Leaderboard
  static const String leaderboard = '/leaderboard';
  static const String leaderboardMe = '/leaderboard/me';

  // Dashboard
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardUserStats = '/dashboard/user-stats';
  static const String dashboardActivity = '/dashboard/activity';
  static const String dashboardProgress = '/dashboard/progress';

}
