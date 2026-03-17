import '../../../core/services/api_client.dart';

class SpeakerService {
  final ApiClient _api;

  SpeakerService(this._api);

  Future<List<dynamic>> fetchSpeakers() async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/integration/speakers',
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }
}
