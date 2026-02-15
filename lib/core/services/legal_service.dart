import '../../features/auth/services/auth_service.dart';
import '../services/api_client.dart';

/// Legal document model
class LegalDocument {
  final int id;
  final String type;
  final String title;
  final String content;

  LegalDocument({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      content: json['content'],
    );
  }
}

/// Service for fetching legal documents (Terms, Privacy, Refund, Cookies) from the API.
class LegalService {
  final ApiClient _api;

  LegalService(AuthService authService) : _api = ApiClient(authService);

  /// Fetch a legal document by type.
  /// [docType] should be one of: TERMS, PRIVACY, REFUND, COOKIES
  Future<LegalDocument?> getDocument(String docType) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/legal/${docType.toUpperCase()}',
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      return LegalDocument.fromJson(result.data!);
    }
    return null;
  }
}
