import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

/// Service for handling contact form submissions
class ContactService {
  final ApiClient _api;

  ContactService(AuthService authService) : _api = ApiClient(authService);

  /// Submit a contact message
  Future<bool> sendMessage({
    required int eventId,
    required String name,
    required String surname,
    required String email,
    required String message,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/contact/',
      body: {
        'event_id': eventId,
        'name': name,
        'surname': surname,
        'email': email,
        'message': message,
      },
      auth: false,
    );

    return result.isSuccess;
  }
}
