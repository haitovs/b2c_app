import '../../../core/services/api_client.dart';

class SponsorService {
  final ApiClient _api;

  SponsorService(this._api);

  Future<List<dynamic>> fetchSponsors({int? eventId}) async {
    final queryParams = <String, String>{};
    if (eventId != null) {
      queryParams['event_id'] = eventId.toString();
    }

    final result = await _api.get<List<dynamic>>(
      '/api/v1/sponsors/',
      auth: false,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }
}
