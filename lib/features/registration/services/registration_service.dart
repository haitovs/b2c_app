import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

/// Registration status enum matching backend
enum RegistrationStatus { submitted, approved, rejected }

/// Service for managing user registrations
class RegistrationService {
  final ApiClient _api;

  RegistrationService(AuthService authService) : _api = ApiClient(authService);

  /// Get current user's registrations
  Future<List<Map<String, dynamic>>> getMyRegistrations() async {
    final result = await _api.get<List<dynamic>>('/api/v1/registrations/me');

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Check if user has an approved registration for an event
  Future<bool> hasApprovedRegistration(int eventId) async {
    try {
      final registrations = await getMyRegistrations();
      return registrations.any(
        (reg) =>
            reg['event_id'] == eventId &&
            reg['status']?.toString().toLowerCase() == 'approved',
      );
    } catch (e) {
      return false;
    }
  }

  /// Get registration status for an event
  Future<RegistrationStatus?> getRegistrationStatus(int eventId) async {
    try {
      final registrations = await getMyRegistrations();
      final reg = registrations.firstWhere(
        (r) => r['event_id'] == eventId,
        orElse: () => {},
      );

      if (reg.isEmpty) return null;

      final statusStr = reg['status']?.toString().toLowerCase() ?? '';
      return RegistrationStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => RegistrationStatus.submitted,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a new registration
  Future<Map<String, dynamic>?> createRegistration(int eventId) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/registrations/',
      body: {'event_id': eventId},
    );

    if (result.isSuccess) {
      return result.data;
    }
    return null;
  }
}
