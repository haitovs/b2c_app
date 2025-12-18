import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

/// Meeting types matching the B2C backend enum
enum MeetingType { b2b, b2g }

/// Meeting status matching the B2C backend enum
enum MeetingStatus { pending, confirmed, declined, cancelled }

/// Service for managing meetings via the B2C backend
class MeetingService {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1/meetings';
  final AuthService authService;

  MeetingService(this.authService);

  /// Get all meetings for the current user
  Future<List<Map<String, dynamic>>> fetchMyMeetings() async {
    final token = await authService.getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load meetings: ${response.body}');
    }
  }

  /// Get a single meeting by ID
  Future<Map<String, dynamic>> fetchMeeting(String meetingId) async {
    final token = await authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$meetingId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load meeting: ${response.body}');
    }
  }

  /// Create a new meeting request
  Future<Map<String, dynamic>> createMeeting({
    required int eventId,
    required MeetingType type,
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? targetUserId, // B2C User UUID for B2B
    int? targetGovEntityId,
    int? targetSpeakerId,
    String? attendeesText,
  }) async {
    final token = await authService.getToken();

    final body = {
      'event_id': eventId,
      'type': type.name.toUpperCase(),
      'subject': subject,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (location != null) 'location': location,
      if (targetUserId != null) 'target_user_id': targetUserId,
      if (targetGovEntityId != null) 'target_gov_entity_id': targetGovEntityId,
      if (targetSpeakerId != null) 'target_speaker_id': targetSpeakerId,
      if (attendeesText != null) 'attendees_text': attendeesText,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create meeting: ${response.body}');
    }
  }

  /// Update an existing meeting
  Future<Map<String, dynamic>> updateMeeting({
    required String meetingId,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? attendeesText,
  }) async {
    final token = await authService.getToken();

    final body = <String, dynamic>{};
    if (subject != null) body['subject'] = subject;
    if (startTime != null) body['start_time'] = startTime.toIso8601String();
    if (endTime != null) body['end_time'] = endTime.toIso8601String();
    if (location != null) body['location'] = location;
    if (attendeesText != null) body['attendees_text'] = attendeesText;

    final response = await http.put(
      Uri.parse('$baseUrl/$meetingId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update meeting: ${response.body}');
    }
  }

  /// Update meeting status (confirm, decline, cancel)
  Future<Map<String, dynamic>> updateMeetingStatus({
    required String meetingId,
    required MeetingStatus status,
  }) async {
    final token = await authService.getToken();

    final response = await http.patch(
      Uri.parse(
        '$baseUrl/$meetingId/status?status_in=${status.name.toUpperCase()}',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update status: ${response.body}');
    }
  }

  /// Get government entities list (for B2G meetings)
  Future<List<Map<String, dynamic>>> fetchGovEntities() async {
    final token = await authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/gov-entities'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load gov entities: ${response.body}');
    }
  }

  /// Fetch participants from Tourism backend (for B2B target selection)
  Future<List<Map<String, dynamic>>> fetchParticipants({int? siteId}) async {
    final token = await authService.getToken();
    var url = '${AppConfig.b2cApiBaseUrl}/api/v1/integration/participants';
    if (siteId != null) {
      url += '?site_id=$siteId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load participants: ${response.body}');
    }
  }

  /// Check if user is registered
  Future<bool> checkRegistrationStatus() async {
    try {
      final token = await authService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/registrations/my-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ACCEPTED';
      }
      return false;
    } catch (e) {
      // API endpoint not available or error - assume not registered
      return false;
    }
  }
}
