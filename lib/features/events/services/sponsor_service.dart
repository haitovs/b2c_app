import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class SponsorService {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1/integration';
  final AuthService authService;

  SponsorService(this.authService);

  Future<List<dynamic>> fetchSponsors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sponsors'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load sponsors');
      }
    } catch (e) {
      throw Exception('Error fetching sponsors: $e');
    }
  }
}
