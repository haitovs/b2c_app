import '../../../core/services/api_client.dart';

class SpeakerService {
  final ApiClient _api;

  SpeakerService(this._api);

  Future<List<dynamic>> fetchSpeakers({int? eventId}) async {
    final queryParams = <String, String>{};
    if (eventId != null) {
      queryParams['event_id'] = eventId.toString();
    }

    final result = await _api.get<List<dynamic>>(
      '/api/v1/speakers',
      auth: false,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }
}
