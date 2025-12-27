import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/faq_item.dart';

/// Service for fetching FAQs from the B2C backend
class FAQService {
  final ApiClient _api;

  FAQService(AuthService authService) : _api = ApiClient(authService);

  /// Get FAQs, optionally filtered by event ID and search query
  Future<List<FAQItem>> getFAQs({int? eventId, String? search}) async {
    final queryParams = <String, String>{};
    if (eventId != null) {
      queryParams['event_id'] = eventId.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final result = await _api.get<List<dynamic>>(
      '/api/v1/faq/',
      auth: false,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.map((json) => FAQItem.fromJson(json)).toList();
    }
    return [];
  }
}
