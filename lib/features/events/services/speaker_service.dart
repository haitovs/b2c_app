import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

class SpeakerService {
  final ApiClient _api;

  SpeakerService(AuthService authService) : _api = ApiClient(authService);

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
