import 'package:flutter/foundation.dart';

import '../../features/auth/services/auth_service.dart';
import '../services/api_client.dart';

/// Service to manage registration data with B2C backend
class RegistrationDataService {
  final ApiClient _api;

  RegistrationDataService(AuthService authService)
    : _api = ApiClient(authService);

  // ============== FETCH METHODS ==============

  /// Fetch delegate packages for a specific event
  Future<List<Map<String, dynamic>>> fetchDelegatePackages(int eventId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/registrations/packages',
      queryParams: {'event_id': eventId.toString()},
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetch expo products for a specific event
  Future<List<Map<String, dynamic>>> fetchExpoProducts(int eventId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/registrations/products',
      queryParams: {'event_id': eventId.toString()},
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get existing registration for current user and event
  Future<Map<String, dynamic>?> getMyRegistration(int eventId) async {
    final result = await _api.get<List<dynamic>>('/api/v1/registrations/me');

    if (result.isSuccess && result.data != null) {
      for (var reg in result.data!) {
        if (reg['event_id'] == eventId) {
          return reg as Map<String, dynamic>;
        }
      }
    }
    return null;
  }

  // ============== CREATE & SAVE METHODS ==============

  /// Create a new registration for an event
  Future<Map<String, dynamic>?> createRegistration(int eventId) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/registrations/',
      body: {'event_id': eventId},
    );

    if (result.isSuccess && result.data != null) {
      return result.data;
    } else if (result.error?.statusCode == 400) {
      // Already have a registration - try to get it
      return await getMyRegistration(eventId);
    }
    return null;
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
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/registrations/$registrationId/contact',
      body: {
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
      },
    );

    if (result.isSuccess) {
      debugPrint('Phase 1 saved successfully');
      return true;
    }
    debugPrint('Failed to save phase 1: ${result.error?.message}');
    return false;
  }

  /// Save Phase 2 - Package selections
  Future<bool> savePhase2Packages({
    required String registrationId,
    required List<Map<String, dynamic>> packages,
  }) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/registrations/$registrationId/packages',
      body: {
        'packages': packages
            .map(
              (p) => {'package_id': p['package_id'], 'quantity': p['quantity']},
            )
            .toList(),
      },
    );

    if (result.isSuccess) {
      debugPrint('Phase 2 packages saved successfully');
      return true;
    }
    debugPrint('Failed to save phase 2 packages: ${result.error?.message}');
    return false;
  }

  /// Save Phase 2 - Delegates
  Future<bool> savePhase2Delegates({
    required String registrationId,
    required List<Map<String, dynamic>> delegates,
  }) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/registrations/$registrationId/delegates',
      body: {
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
      },
    );

    if (result.isSuccess) {
      debugPrint('Phase 2 delegates saved successfully');
      return true;
    }
    debugPrint('Failed to save delegates: ${result.error?.message}');
    return false;
  }

  /// Save Phase 3 - Expo products
  Future<bool> savePhase3Products({
    required String registrationId,
    required List<Map<String, dynamic>> products,
  }) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/registrations/$registrationId/products',
      body: {
        'products': products
            .map(
              (p) => {'product_id': p['product_id'], 'quantity': p['quantity']},
            )
            .toList(),
      },
    );

    if (result.isSuccess) {
      debugPrint('Phase 3 products saved successfully');
      return true;
    }
    debugPrint('Failed to save phase 3 products: ${result.error?.message}');
    return false;
  }

  /// Submit registration for approval
  Future<bool> submitRegistration(String registrationId) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/registrations/$registrationId/submit',
    );

    if (result.isSuccess) {
      debugPrint('Registration submitted successfully');
      return true;
    }
    debugPrint('Failed to submit registration: ${result.error?.message}');
    return false;
  }
}
