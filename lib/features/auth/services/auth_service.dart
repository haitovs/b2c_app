import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';

class AuthService extends ChangeNotifier {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1';

  Map<String, dynamic>? _currentUser;
  String? _token;
  bool _isInitialized = false; // Tracks if auth check has completed

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;
  bool get hasAgreedTerms => _currentUser?['has_agreed_terms'] ?? false;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Returns null on success, or an error message string on failure.
  /// Note: Token is always persisted to SharedPreferences for web compatibility.
  /// The rememberMe parameter is reserved for future use (e.g., extended token expiry).
  Future<String?> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];

        // Always persist token to SharedPreferences for session restoration
        // This is essential for Flutter Web where page refresh loses in-memory state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        // Store rememberMe preference for potential future use
        await prefs.setBool('remember_me', rememberMe);

        // Fetch user details
        await _fetchCurrentUser();

        notifyListeners();
        return null; // Success
      } else if (response.statusCode == 403) {
        // Check if it's an email verification error
        try {
          final data = jsonDecode(response.body);
          if (data['detail'] == 'EMAIL_NOT_VERIFIED') {
            return 'EMAIL_NOT_VERIFIED'; // Special error code for frontend
          }
        } catch (_) {}
        return _parseError(response.body);
      } else {
        return _parseError(response.body);
      }
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        _currentUser = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      // Failed to fetch user - token may be expired
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('auth_token')) {
      _token = prefs.getString('auth_token');
      await _fetchCurrentUser();
      // If fetch fails (token expired), _currentUser might remain null or we should handle it
      if (_currentUser != null) {
        notifyListeners();
      } else {
        // Token might be invalid, clear it
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

  /// Returns null on success, or an error message string on failure.
  Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? mobile,
    String? companyName,
    String? website,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'mobile': mobile,
          'company_name': companyName,
          'website': website,
        }),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return _parseError(response.body);
      }
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> updateProfile(Map<String, dynamic> updates) async {
    if (_token == null) return "Not authenticated";

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        // Update local user data with the response
        _currentUser = jsonDecode(response.body);
        notifyListeners();
        return null;
      } else {
        return _parseError(response.body);
      }
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  String _parseError(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return data['detail'].toString();
      }
    } catch (_) {
      // fallback
    }
    return "Operation failed. Please try again.";
  }

  /// Resend verification email to the user
  /// Returns null on success, or an error message string on failure.
  Future<String?> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification?email=$email'),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return _parseError(response.body);
      }
    } catch (e) {
      return "Failed to resend verification email: $e";
    }
  }
}
