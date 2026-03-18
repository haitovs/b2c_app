import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/token_provider.dart';
import '../models/auth_state.dart';

const _secureStorage = FlutterSecureStorage();

/// Riverpod notifier for authentication state.
/// Implements TokenProvider so it can be used by ApiClient.
class AuthNotifier extends Notifier<AuthState> implements TokenProvider {
  late final ApiClient _api;
  late final SharedPreferences _prefs;
  bool _isRefreshing = false;

  @override
  AuthState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    // Create ApiClient with self as TokenProvider
    _api = ApiClient(this);
    // Start auto-login (deferred so build() returns initial state first)
    Future.microtask(() => _tryAutoLogin());
    return const AuthState();
  }

  @override
  Future<String?> getToken() async {
    final token = state.token ?? await _secureStorage.read(key: 'auth_token');
    if (token == null) return null;

    // Proactive refresh: if token expires within 2 minutes, refresh early.
    // Skip if a refresh is already in flight to avoid cascading calls.
    if (_isTokenExpiringSoon(token) && !_isRefreshing) {
      final newToken = await refreshAccessToken();
      if (newToken != null) return newToken;
      // Refresh failed — don't return the expired token
      return null;
    }
    return token;
  }

  /// Decode JWT exp claim and check if token expires within [bufferSeconds].
  bool _isTokenExpiringSoon(String token, {int bufferSeconds = 120}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'] as int?;
      if (exp == null) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(
        expiresAt.subtract(Duration(seconds: bufferSeconds)),
      );
    } catch (_) {
      return false;
    }
  }

  /// Returns the stored refresh token.
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  /// Attempt to refresh the access token using the stored refresh token.
  /// Returns the new access token on success, or null on failure.
  @override
  Future<String?> refreshAccessToken() async {
    // Prevent concurrent refresh attempts
    if (_isRefreshing) return null;
    _isRefreshing = true;

    try {
      final rt = await _secureStorage.read(key: 'refresh_token');
      if (rt == null) return null;

      final result = await _api.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        body: {'refresh_token': rt},
        auth: false,
      );

      if (result.isSuccess && result.data != null) {
        final newToken = result.data!['access_token'] as String;
        final newRefresh = result.data!['refresh_token'] as String;
        await _secureStorage.write(key: 'auth_token', value: newToken);
        await _secureStorage.write(key: 'refresh_token', value: newRefresh);
        state = state.copyWith(token: newToken);
        return newToken;
      }

      // Refresh failed — force logout
      await logout();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// The ApiClient instance for this auth session.
  ApiClient get apiClient => _api;

  Future<void> _tryAutoLogin() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token != null) {
      state = state.copyWith(token: token);
      await _fetchCurrentUser();
      if (state.currentUser == null) {
        await logout();
        return;
      }
    }
    state = state.copyWith(isInitialized: true);
  }

  Future<void> _fetchCurrentUser() async {
    if (state.token == null) return;

    final result = await _api.get<Map<String, dynamic>>('/api/v1/users/me');

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(currentUser: result.data);
    }
  }

  /// Login user. Returns null on success, or error message on failure.
  Future<String?> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _api.postForm<Map<String, dynamic>>(
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      final token = result.data!['access_token'] as String;
      final refresh = result.data!['refresh_token'] as String?;
      await _secureStorage.write(key: 'auth_token', value: token);
      if (refresh != null) {
        await _secureStorage.write(key: 'refresh_token', value: refresh);
      }
      await _prefs.setBool('remember_me', rememberMe);

      state = state.copyWith(token: token, isLoading: false);
      await _fetchCurrentUser();
      return null;
    } else {
      final error = result.error!;
      if (error.code == 'EMAIL_NOT_VERIFIED' ||
          error.message == 'EMAIL_NOT_VERIFIED') {
        state = state.copyWith(isLoading: false);
        return 'EMAIL_NOT_VERIFIED';
      }
      final msg = _getUserFriendlyError(error.message);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    // Clear state and storage first to stop any further API calls
    final rt = await _secureStorage.read(key: 'refresh_token');
    final token = state.token;
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
    state = const AuthState(isInitialized: true);

    // Revoke refresh token on server (best-effort, auth: false to avoid loop)
    if (rt != null && token != null) {
      await _api.post(
        '/api/v1/auth/logout',
        body: {'refresh_token': rt},
        auth: false,
      );
    }
  }

  /// Register a new user. Returns null on success, or error message.
  Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? mobile,
    String? companyName,
    String? website,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    };

    if (mobile != null && mobile.isNotEmpty) body['mobile'] = mobile;
    if (companyName != null && companyName.isNotEmpty) {
      body['company_name'] = companyName;
    }
    if (website != null && website.isNotEmpty) body['website'] = website;

    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/signup',
      body: body,
      auth: false,
    );

    state = state.copyWith(isLoading: false);

    if (result.isSuccess) {
      return null;
    } else {
      return _getUserFriendlyError(result.error!.message);
    }
  }

  /// Update user profile. Returns null on success, or error message.
  Future<String?> updateProfile(Map<String, dynamic> updates) async {
    if (state.token == null) return 'Not authenticated';

    final result = await _api.patch<Map<String, dynamic>>(
      '/api/v1/users/me',
      body: updates,
    );

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(currentUser: result.data);
      return null;
    } else {
      return _getUserFriendlyError(result.error!.message);
    }
  }

  /// Resend verification email.
  Future<String?> resendVerificationEmail(String email) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/resend-verification?email=$email',
      auth: false,
    );

    if (result.isSuccess) return null;
    return _getUserFriendlyError(
      result.error?.message ?? 'Failed to resend verification email',
    );
  }

  /// Verify email with verification code.
  Future<String?> verifyCode(String email, String code) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/verify-code',
      body: {'email': email, 'code': code},
      auth: false,
    );

    if (result.isSuccess) return null;
    return _getUserFriendlyError(
      result.error?.message ?? 'Invalid verification code',
    );
  }

  /// Resend verification code.
  Future<String?> resendCode(String email) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/resend-code',
      body: {'email': email},
      auth: false,
    );

    if (result.isSuccess) return null;
    return _getUserFriendlyError(
      result.error?.message ?? 'Failed to resend verification code',
    );
  }

  /// Send forgot password recovery code.
  Future<String?> forgotPassword(String email) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/forgot-password',
      body: {'email': email},
      auth: false,
    );

    if (result.isSuccess) return null;
    return _getUserFriendlyError(
      result.error?.message ?? 'Failed to send recovery email',
    );
  }

  /// Verify password reset code.
  Future<String?> verifyResetCode(String email, String code) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/verify-reset-code',
      body: {'email': email, 'code': code},
      auth: false,
    );

    if (result.isSuccess) return null;
    return _getUserFriendlyError(
      result.error?.message ?? 'Invalid verification code',
    );
  }

  /// Reset password with code.
  Future<String?> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/reset-password',
      body: {'email': email, 'code': code, 'new_password': newPassword},
      auth: false,
    );

    if (result.isSuccess) return null;
    return _getUserFriendlyError(
      result.error?.message ?? 'Failed to reset password',
    );
  }

  /// Create password for a team member invitation token.
  /// On success, auto-logs in the user and returns null.
  /// Returns error message on failure.
  Future<String?> createPassword(String token, String password) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/team-members/create-password',
      body: {'token': token, 'password': password},
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      final accessToken = result.data!['access_token'] as String?;
      if (accessToken != null) {
        await _secureStorage.write(key: 'auth_token', value: accessToken);
        state = state.copyWith(token: accessToken);
        await _fetchCurrentUser();
      }
      return null;
    }
    return _getUserFriendlyError(
      result.error?.message ?? 'Failed to create password',
    );
  }

  /// Verify email with token (legacy).
  Future<String?> verifyEmail(String token) async {
    final result = await _api.get<dynamic>(
      '/api/v1/auth/verify-email',
      queryParams: {'token': token},
      auth: false,
    );

    if (result.isSuccess) {
      return null;
    }
    final msg = result.error?.message ?? '';
    if (msg.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Verification failed. Please request a new verification email.';
  }

  String _getUserFriendlyError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('email already exists') ||
        lowerError.contains('user with this email')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    }
    if (lowerError.contains('mobile') &&
        (lowerError.contains('already exists') ||
            lowerError.contains('number already exists'))) {
      return 'This mobile number is already registered. Please use a different number.';
    }
    if (lowerError.contains('incorrect email') ||
        lowerError.contains('incorrect password') ||
        lowerError.contains('incorrect') && lowerError.contains('password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lowerError.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (lowerError.contains('password') && lowerError.contains('short')) {
      return 'Password is too short. Please use at least 8 characters.';
    }
    if (lowerError.contains('inactive user')) {
      return 'Your account has been deactivated. Please contact support.';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return errorMessage;
  }
}

/// The main auth notifier provider.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Convenience provider: whether the user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Convenience provider: the current user data.
final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authNotifierProvider).currentUser;
});

/// Convenience provider: whether auth has been initialized.
final isAuthInitializedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isInitialized;
});

/// Provider for the ApiClient, using AuthNotifier as the TokenProvider.
final authApiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(authNotifierProvider.notifier).apiClient;
});
