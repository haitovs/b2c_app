import 'dart:convert';

import 'package:http/http.dart' as http;

class EventService {
  final String baseUrl = 'http://localhost:8000/api/v1';

  Future<List<dynamic>> getEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching events: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getEvent(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$id'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Error fetching event $id: $e");
      return null;
    }
  }
}
