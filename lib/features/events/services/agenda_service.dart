import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class AgendaService {
  final AuthService authService;

  AgendaService(this.authService);

  /// Fetch agenda days from tourism backend
  Future<List<dynamic>> fetchAgendaDays({int? siteId}) async {
    try {
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/agenda/days?site_id=$siteId',
            )
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/agenda/days');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load agenda days');
      }
    } catch (e) {
      throw Exception('Error fetching agenda days: $e');
    }
  }

  /// Fetch episodes for a specific day from tourism backend
  Future<List<dynamic>> fetchEpisodesForDay(int dayId, {int? siteId}) async {
    try {
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/agenda/day/$dayId/episodes?site_id=$siteId',
            )
          : Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/agenda/day/$dayId/episodes',
            );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load episodes');
      }
    } catch (e) {
      throw Exception('Error fetching episodes: $e');
    }
  }
}
