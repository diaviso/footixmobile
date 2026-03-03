import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/api/api_client.dart';
import '../data/api/api_exception.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';
import 'service_providers.dart';

/// Auth state
class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = true,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiClient _apiClient;

  AuthNotifier(this._authService, this._apiClient) : super(const AuthState()) {
    _apiClient.onUnauthorized = _onUnauthorized;
  }

  void _onUnauthorized(String? backendMessage) {
    final isSessionConflict = backendMessage != null &&
        (backendMessage.contains('Session expired') ||
         backendMessage.contains('another device'));
    state = AuthState(
      isAuthenticated: false,
      isLoading: false,
      error: isSessionConflict
          ? 'Vous avez été déconnecté car une connexion a été établie depuis un autre appareil.'
          : 'Session expirée. Veuillez vous reconnecter.',
    );
  }

  /// Load user from stored token on app start
  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _apiClient.getToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(isLoading: false, isAuthenticated: false);
        return;
      }
      final user = await _authService.getProfile();
      state = AuthState(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Auth] loadUser failed: $e');
      await _apiClient.clearToken();
      state = const AuthState(isLoading: false, isAuthenticated: false);
    }
  }

  /// Login with email/password
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(email: email, password: password);
      debugPrint('[Auth] Login success, token: ${result.token.substring(0, 20)}...');
      await _apiClient.setToken(result.token);
      debugPrint('[Auth] Token stored, verifying: ${await _apiClient.getToken() != null}');
      state = AuthState(
        user: result.user,
        isAuthenticated: true,
        isLoading: false,
      );
      debugPrint('[Auth] State updated: isAuthenticated=${state.isAuthenticated}');
    } on ApiException catch (e) {
      debugPrint('[Auth] Login ApiException: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      debugPrint('[Auth] Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Une erreur est survenue lors de la connexion',
      );
      rethrow;
    }
  }

  /// Register
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      state = state.copyWith(isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Une erreur est survenue lors de l'inscription",
      );
      rethrow;
    }
  }

  /// Verify email
  Future<void> verifyEmail({required String email, required String code}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.verifyEmail(email: email, code: code);
      await _apiClient.setToken(result.token);
      state = AuthState(
        user: result.user,
        isAuthenticated: true,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Code de vérification invalide',
      );
      rethrow;
    }
  }

  /// Google Sign-In
  Future<void> googleLogin() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // The Web client ID is required as serverClientId to obtain an idToken.
      // Without it, idToken is always null on Android and Flutter Web.
      const webClientId = '121518459102-9pbgbivnatkg7j5jn8klh3hg4t7cl13r.apps.googleusercontent.com';
      const iosClientId = '121518459102-c1rlbkti9l0j54s8rgdmso11rmhmg99j.apps.googleusercontent.com';
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: kIsWeb ? null : webClientId,
        clientId: kIsWeb ? webClientId : iosClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        debugPrint('[Auth] Google idToken is null — check serverClientId config');
        state = state.copyWith(
          isLoading: false,
          error: 'Impossible de récupérer le token Google',
        );
        return;
      }
      final result = await _authService.googleLogin(idToken);
      await _apiClient.setToken(result.token);
      state = AuthState(
        user: result.user,
        isAuthenticated: true,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      debugPrint('Google login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la connexion Google',
      );
    }
  }

  /// Forgot password
  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.forgotPassword(email: email);
      state = state.copyWith(isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Update profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.updateProfile(data);
      state = state.copyWith(user: user, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Upload avatar
  Future<void> uploadAvatar(String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.uploadAvatar(filePath);
      state = state.copyWith(user: user, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  /// Update leaderboard visibility
  Future<void> updateLeaderboardVisibility(bool show) async {
    try {
      final user = await _authService.updateLeaderboardVisibility(show);
      state = state.copyWith(user: user);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {
      // Silently fail
    }
  }

  /// Update user locally (e.g. after earning stars)
  void updateUserLocally(UserModel user) {
    state = state.copyWith(user: user);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Delete account permanently
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    await _apiClient.clearToken();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  /// Logout
  Future<void> logout() async {
    await _apiClient.clearToken();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(authService, apiClient);
});

/// Convenience selectors
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

