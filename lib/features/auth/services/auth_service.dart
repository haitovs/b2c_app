import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  /// Parse and make error messages user-friendly
  String _getUserFriendlyError(String errorMessage) {
    // Convert backend error messages to user-friendly ones
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

    // Return the original error message if no match found
    return errorMessage;
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
      return _getUserFriendlyError(error.message);
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
    // Build request body, only including non-empty values
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    };

    // Only add optional fields if they have values
    if (mobile != null && mobile.isNotEmpty) {
      body['mobile'] = mobile;
    }
    if (companyName != null && companyName.isNotEmpty) {
      body['company_name'] = companyName;
    }
    if (website != null && website.isNotEmpty) {
      body['website'] = website;
    }

    final result = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/signup',
      body: body,
      auth: false,
    );

    if (result.isSuccess) {
      return null;
    } else {
      return _getUserFriendlyError(result.error!.message);
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
      return _getUserFriendlyError(result.error!.message);
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
      return _getUserFriendlyError(
        result.error?.message ?? 'Failed to resend verification email',
      );
    }
  }

  /// Verify email with token. Returns null on success, or error message.
  /// Note: Backend returns HTML on success, not JSON, so we check status code directly.
  Future<String?> verifyEmail(String token) async {
    try {
      final uri = Uri.parse(
        '${apiClient.baseUrl}/api/v1/auth/verify-email?token=$token',
      );
      final response = await http.get(uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null; // Success
      } else {
        return 'Verification failed. Please request a new verification email.';
      }
    } catch (e) {
      return 'Network error. Please check your connection and try again.';
    }
  }
}
