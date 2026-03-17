import '../../../core/services/api_client.dart';

class SponsorService {
  final ApiClient _api;

  SponsorService(this._api);

  Future<List<dynamic>> fetchSponsors() async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/integration/sponsors',
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    return [];
  }
}
