import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

class AgendaService {
  final ApiClient _api;

  AgendaService(AuthService authService) : _api = ApiClient(authService);

  /// Fetch agenda days from tourism backend
  Future<List<dynamic>> fetchAgendaDays({int? siteId}) async {
    final queryParams = <String, String>{};
    if (siteId != null) {
      queryParams['site_id'] = siteId.toString();
    }

    // Note: Tourism API uses different base URL
    final result = await _api.get<List<dynamic>>(
      '/agenda/days',
      auth: false,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }

  /// Fetch episodes for a specific day from tourism backend
  Future<List<dynamic>> fetchEpisodesForDay(int dayId, {int? siteId}) async {
    final queryParams = <String, String>{};
    if (siteId != null) {
      queryParams['site_id'] = siteId.toString();
    }

    final result = await _api.get<List<dynamic>>(
      '/agenda/day/$dayId/episodes',
      auth: false,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }
}
