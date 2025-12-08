import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class EventService {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1';
  final AuthService authService;

  EventService(this.authService);

  Future<List<dynamic>> fetchEvents({int? siteId}) async {
    try {
      String query = '';
      if (siteId != null) {
        query = '?tourism_site_id=$siteId';
      }
      final response = await http.get(
        Uri.parse('$baseUrl/events/$query'),
        // headers: {'Authorization': 'Bearer ${authService.token}'}, // If protected
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  /// Fetch single event by ID
  Future<Map<String, dynamic>?> fetchEvent(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$id'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load event');
      }
    } catch (e) {
      throw Exception('Error fetching event: $e');
    }
  }
}
