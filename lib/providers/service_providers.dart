import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/api_client.dart';
import '../data/services/services.dart';

/// Single ApiClient instance shared across the app
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Service providers — each depends on the shared ApiClient
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

final themesServiceProvider = Provider<ThemesService>((ref) {
  return ThemesService(ref.watch(apiClientProvider));
});

final quizzesServiceProvider = Provider<QuizzesService>((ref) {
  return QuizzesService(ref.watch(apiClientProvider));
});

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(ref.watch(apiClientProvider));
});

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(apiClientProvider));
});

final duelServiceProvider = Provider<DuelService>((ref) {
  return DuelService(ref.watch(apiClientProvider));
});
