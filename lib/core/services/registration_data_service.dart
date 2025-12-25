import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/services/auth_service.dart';
import '../config/app_config.dart';

/// Service to manage registration data with B2C backend
class RegistrationDataService {
  final String _baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1';
  final AuthService _authService;

  RegistrationDataService(this._authService);

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ============== FETCH METHODS ==============

  /// Fetch delegate packages for a specific event
  Future<List<Map<String, dynamic>>> fetchDelegatePackages(int eventId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/registrations/packages?event_id=$eventId'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to fetch packages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching packages: $e');
      return [];
    }
  }

  /// Fetch expo products for a specific event
  Future<List<Map<String, dynamic>>> fetchExpoProducts(int eventId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/registrations/products?event_id=$eventId'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to fetch products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  /// Get existing registration for current user and event
  Future<Map<String, dynamic>?> getMyRegistration(int eventId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/registrations/me'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Find registration for this event
        for (var reg in data) {
          if (reg['event_id'] == eventId) {
            return reg as Map<String, dynamic>;
          }
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting registration: $e');
      return null;
    }
  }

  // ============== CREATE & SAVE METHODS ==============

  /// Create a new registration for an event
  /// Returns registration data Map or null on error
  Future<Map<String, dynamic>?> createRegistration(int eventId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/registrations/'),
        headers: _headers(token),
        body: jsonEncode({'event_id': eventId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        // Already have a registration - try to get it
        return await getMyRegistration(eventId);
      } else {
        debugPrint(
          'Failed to create registration: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error creating registration: $e');
      return null;
    }
  }

  /// Save Phase 1 - Contact information
  Future<bool> savePhase1Contact({
    required String registrationId,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String country,
    required String city,
    required String companyName,
    String? companyWebsite,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/registrations/$registrationId/contact'),
        headers: _headers(token),
        body: jsonEncode({
          'contact': {
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'mobile': mobile,
            'country': country,
            'city': city,
            'company_name': companyName,
            'company_website': companyWebsite,
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Phase 1 saved successfully');
        return true;
      } else {
        debugPrint(
          'Failed to save phase 1: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error saving phase 1: $e');
      return false;
    }
  }

  /// Save Phase 2 - Package selections
  /// packages: List of {package_id, quantity}
  Future<bool> savePhase2Packages({
    required String registrationId,
    required List<Map<String, dynamic>> packages,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/registrations/$registrationId/packages'),
        headers: _headers(token),
        body: jsonEncode({
          'packages': packages
              .map(
                (p) => {
                  'package_id': p['package_id'],
                  'quantity': p['quantity'],
                },
              )
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Phase 2 packages saved successfully');
        return true;
      } else {
        debugPrint(
          'Failed to save phase 2 packages: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error saving phase 2 packages: $e');
      return false;
    }
  }

  /// Save Phase 2 - Delegates
  /// delegates: List of delegate data maps
  Future<bool> savePhase2Delegates({
    required String registrationId,
    required List<Map<String, dynamic>> delegates,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/registrations/$registrationId/delegates'),
        headers: _headers(token),
        body: jsonEncode({
          'delegates': delegates
              .map(
                (d) => {
                  'package_selection_id': d['package_selection_id'],
                  'delegate_number': d['delegate_number'],
                  'first_name': d['first_name'],
                  'last_name': d['last_name'],
                  'email': d['email'],
                  'mobile': d['mobile'],
                  'country': d['country'],
                  'city': d['city'],
                  'company_name': d['company_name'],
                  'company_website': d['company_website'],
                  'is_self_registration': d['is_self_registration'] ?? false,
                },
              )
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Phase 2 delegates saved successfully');
        return true;
      } else {
        debugPrint(
          'Failed to save delegates: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error saving delegates: $e');
      return false;
    }
  }

  /// Save Phase 3 - Expo products
  /// products: List of {product_id, quantity}
  Future<bool> savePhase3Products({
    required String registrationId,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/registrations/$registrationId/products'),
        headers: _headers(token),
        body: jsonEncode({
          'products': products
              .map(
                (p) => {
                  'product_id': p['product_id'],
                  'quantity': p['quantity'],
                },
              )
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Phase 3 products saved successfully');
        return true;
      } else {
        debugPrint(
          'Failed to save phase 3 products: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error saving phase 3 products: $e');
      return false;
    }
  }

  /// Submit registration for approval
  Future<bool> submitRegistration(String registrationId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/registrations/$registrationId/submit'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        debugPrint('Registration submitted successfully');
        return true;
      } else {
        debugPrint(
          'Failed to submit registration: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting registration: $e');
      return false;
    }
  }
}
