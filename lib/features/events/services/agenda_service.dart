import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';

class AgendaService {
  final String baseUrl = 'http://localhost:8000/api/v1/integration';
  final AuthService authService;

  AgendaService(this.authService);

  Future<List<dynamic>> fetchAgenda() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/agenda'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load agenda');
      }
    } catch (e) {
      throw Exception('Error fetching agenda: $e');
    }
  }
}
