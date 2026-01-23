import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

/// Service for fetching events from the B2C backend
class EventService {
  final ApiClient _api;

  EventService(AuthService authService) : _api = ApiClient(authService);

  /// Fetch all events, optionally filtered by site ID
  Future<List<dynamic>> fetchEvents({int? siteId}) async {
    final queryParams = <String, String>{};
    if (siteId != null) {
      queryParams['tourism_site_id'] = siteId.toString();
    }

    final result = await _api.get<List<dynamic>>(
      '/api/v1/events/',
      auth: false,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to load events');
    }
  }

  /// Fetch a single event by ID
  Future<Map<String, dynamic>?> fetchEvent(int id) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/events/$id',
      auth: false,
    );

    if (result.isSuccess) {
      return result.data;
    } else if (result.error?.isNotFound ?? false) {
      return null;
    } else {
      throw result.error ?? Exception('Failed to load event');
    }
  }

  /// Fetch events where the current user can add participants
  /// Returns events where user has purchased packages and has available slots
  Future<List<dynamic>> getEligibleEventsForParticipants() async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/events/eligible-for-participants',
      auth: true, // Requires authentication
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to load eligible events');
    }
  }
}
