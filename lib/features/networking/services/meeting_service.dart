import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class MeetingService {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1/meetings';
  final AuthService authService;

  MeetingService(this.authService);

  Future<List<dynamic>> fetchMyMeetings() async {
    final token = await authService.getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load meetings');
    }
  }

  Future<void> createMeeting(Map<String, dynamic> data) async {
    final token = await authService.getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create meeting: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchParticipants() async {
    final token = await authService.getToken();
    final response = await http.get(
      Uri.parse(
        '${AppConfig.b2cApiBaseUrl}/api/v1/integration/participants',
      ), // Proxy to Tourism
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participants');
    }
  }

  Future<List<dynamic>> fetchGovEntities() async {
    final token = await authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/gov-entities'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load gov entities');
    }
  }
}
