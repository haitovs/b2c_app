import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class FAQItem {
  final int id;
  final int? eventId;
  final String question;
  final String answer; // Markdown format
  final String? category;
  final int order;

  FAQItem({
    required this.id,
    this.eventId,
    required this.question,
    required this.answer,
    this.category,
    required this.order,
  });

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'],
      eventId: json['event_id'],
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'],
      order: json['order'] ?? 0,
    );
  }
}

class FAQService {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1';

  Future<List<FAQItem>> getFAQs({int? eventId, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (eventId != null) {
        queryParams['event_id'] = eventId.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$baseUrl/faq/',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FAQItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
