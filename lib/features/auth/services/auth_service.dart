import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

/// Authentication service handling login, registration, and user state.
/// This is a ChangeNotifier so it can be used with Provider.
class AuthService extends ChangeNotifier {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1';

  Map<String, dynamic>? _currentUser;
  String? _token;
  bool _isInitialized = false;

  // Lazy-initialized API client (can't be created in constructor due to circular dependency)
  ApiClient? _apiClient;
  ApiClient get apiClient => _apiClient ??= ApiClient(this);

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;
  bool get hasAgreedTerms => _currentUser?['has_agreed_terms'] ?? false;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Login user and return null on success, or error message on failure.
  Future<String?> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    final result = await apiClient.postForm<Map<String, dynamic>>(
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      _token = result.data!['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setBool('remember_me', rememberMe);

      await _fetchCurrentUser();
      notifyListeners();
      return null; // Success
    } else {
      final error = result.error!;
      if (error.code == 'EMAIL_NOT_VERIFIED') {
        return 'EMAIL_NOT_VERIFIED';
      }
      return error.message;
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_token == null) return;

    final result = await apiClient.get<Map<String, dynamic>>(
      '/api/v1/users/me',
    );

    if (result.isSuccess && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('auth_token')) {
      _token = prefs.getString('auth_token');
      await _fetchCurrentUser();
      if (_currentUser == null) {
        await logout();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
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
    final result = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/signup',
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'mobile': mobile,
        'company_name': companyName,
        'website': website,
      },
      auth: false,
    );

    if (result.isSuccess) {
      return null;
    } else {
      return result.error!.message;
    }
  }

  /// Update user profile. Returns null on success, or error message.
  Future<String?> updateProfile(Map<String, dynamic> updates) async {
    if (_token == null) return "Not authenticated";

    final result = await apiClient.patch<Map<String, dynamic>>(
      '/api/v1/users/me',
      body: updates,
    );

    if (result.isSuccess && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
      return null;
    } else {
      return result.error!.message;
    }
  }

  /// Resend verification email. Returns null on success, or error message.
  Future<String?> resendVerificationEmail(String email) async {
    final result = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/resend-verification?email=$email',
      auth: false,
    );

    if (result.isSuccess) {
      return null;
    } else {
      return result.error?.message ?? 'Failed to resend verification email';
    }
  }

  /// Verify email with token. Returns null on success, or error message.
  Future<String?> verifyEmail(String token) async {
    final result = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/verify-email?token=$token',
      auth: false,
    );

    if (result.isSuccess) {
      return null;
    } else {
      return result.error?.message ?? 'Failed to verify email';
    }
  }
}
