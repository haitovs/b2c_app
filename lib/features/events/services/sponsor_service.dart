import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

class SponsorService {
  final ApiClient _api;

  SponsorService(AuthService authService) : _api = ApiClient(authService);

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
