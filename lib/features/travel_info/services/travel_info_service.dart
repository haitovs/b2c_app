import '../../../core/services/api_client.dart';

/// Service for handling travel information API operations.
class TravelInfoService {
  final ApiClient _api;

  TravelInfoService(this._api);

  /// Fetch team members with their travel info status for the given event.
  Future<List<Map<String, dynamic>>> getTeamMembersWithStatus(
      int eventId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/travel-info/team-members',
      queryParams: {'event_id': eventId.toString()},
    );
    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    }
    throw result.error ?? Exception('Failed to load team members');
  }

  /// Fetch travel info for a specific member and event.
  Future<Map<String, dynamic>> getTravelInfo(
      String memberId, int eventId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/travel-info/$memberId',
      queryParams: {'event_id': eventId.toString()},
    );
    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to load travel info');
  }

  /// Save (update) travel info for a specific member and event.
  Future<Map<String, dynamic>> saveTravelInfo(
      String memberId, int eventId, Map<String, dynamic> data) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/travel-info/$memberId',
      queryParams: {'event_id': eventId.toString()},
      body: data,
    );
    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to save travel info');
  }

  /// Fetch the list of available airports.
  Future<List<Map<String, dynamic>>> getAirports() async {
    final result =
        await _api.get<List<dynamic>>('/api/v1/travel-info/airports');
    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    }
    throw result.error ?? Exception('Failed to load airports');
  }

  /// Fetch the list of available hotels.
  Future<List<Map<String, dynamic>>> getHotels() async {
    final result = await _api.get<List<dynamic>>('/api/v1/hotels/');
    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    }
    throw result.error ?? Exception('Failed to load hotels');
  }
}
