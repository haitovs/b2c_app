import '../../../core/services/api_client.dart';

class AgendaService {
  final ApiClient _api;

  AgendaService(this._api);

  /// Fetch agenda days for an event from B2C backend
  Future<List<dynamic>> fetchAgendaDays({required int eventId}) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/agenda/days',
      auth: false,
      queryParams: {'event_id': eventId.toString()},
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }

  /// Fetch episodes for a specific day from B2C backend
  Future<List<dynamic>> fetchEpisodesForDay(int dayId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/agenda/day/$dayId/episodes',
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }
}
