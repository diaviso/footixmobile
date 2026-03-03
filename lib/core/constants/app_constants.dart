class AppConstants {
  AppConstants._();

  static const String appName = 'Footix';
  static const String appTagline = 'Quiz Football - Testez vos connaissances';

  // Quiz
  static const int maxBaseAttempts = 3;
  static const int extraAttemptCost = 10;
  static const int countdownSeconds = 15;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
}
