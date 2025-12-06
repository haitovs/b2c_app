import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';

class EventService {
  final String baseUrl = 'http://localhost:8000/api/v1';
  final AuthService authService;

  EventService(this.authService);

  Future<List<dynamic>> fetchEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/'),
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
}
