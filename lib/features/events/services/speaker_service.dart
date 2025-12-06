import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';

class SpeakerService {
  final String baseUrl = 'http://localhost:8000/api/v1/integration';
  final AuthService authService;

  SpeakerService(this.authService);

  Future<List<dynamic>> fetchSpeakers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/speakers'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load speakers');
      }
    } catch (e) {
      throw Exception('Error fetching speakers: $e');
    }
  }
}
