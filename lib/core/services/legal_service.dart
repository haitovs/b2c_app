import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Service for fetching legal documents (Terms, Privacy, Refund) from the API.
class LegalService {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1';

  /// Fetch a legal document by type.
  /// [docType] should be one of: TERMS, PRIVACY, REFUND
  Future<LegalDocument?> getDocument(String docType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/legal/${docType.toUpperCase()}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LegalDocument.fromJson(data);
      } else if (response.statusCode == 404) {
        // Document not found - admin needs to create it
        return null;
      }
    } catch (e) {
      // Error fetching legal document - silently fail
    }
    return null;
  }
}

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

/// Global instance for easy access
final legalService = LegalService();
