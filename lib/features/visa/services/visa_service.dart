import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

/// Service for handling visa application API operations
class VisaService {
  final AuthService authService;

  VisaService(this.authService);

  String get _baseUrl => '${AppConfig.b2cApiBaseUrl}/api/v1/visas';

  Future<String?> _getToken() async {
    final token = await authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return token;
  }

  /// Build query parameters from optional participantId and eventId
  String _buildQueryParams({String? participantId, int? eventId}) {
    final params = <String, String>{};
    if (participantId != null) params['participant_id'] = participantId;
    if (eventId != null) params['event_id'] = eventId.toString();
    if (params.isEmpty) return '';
    return '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  /// List all visa applications for the current user and event.
  Future<List<Map<String, dynamic>>> listMyVisas({int? eventId}) async {
    final token = await _getToken();
    final query = _buildQueryParams(eventId: eventId);

    final response = await http.get(
      Uri.parse('$_baseUrl/my-visas$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to list visa applications');
  }

  /// Create a new blank visa application.
  Future<Map<String, dynamic>> createMyVisa({int? eventId}) async {
    final token = await _getToken();
    final query = _buildQueryParams(eventId: eventId);

    final response = await http.post(
      Uri.parse('$_baseUrl/my-visa/create$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to create visa application');
  }

  /// Get a specific visa application by ID.
  Future<Map<String, dynamic>> getMyVisaById(String visaId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/my-visa/$visaId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to load visa application');
  }

  /// Get or create visa application for the current user (backward compat).
  Future<Map<String, dynamic>> getMyVisa({
    String? participantId,
    int? eventId,
  }) async {
    final token = await _getToken();
    final query = _buildQueryParams(participantId: participantId, eventId: eventId);

    final response = await http.get(
      Uri.parse('$_baseUrl/my-visa$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to load visa application');
  }

  /// Update a specific visa application by ID.
  Future<Map<String, dynamic>> updateMyVisaById({
    required String visaId,
    required Map<String, dynamic> data,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$_baseUrl/my-visa/$visaId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to update visa application');
  }

  /// Update visa application with form data (backward compat).
  Future<Map<String, dynamic>> updateMyVisa({
    String? participantId,
    int? eventId,
    required Map<String, dynamic> data,
  }) async {
    final token = await _getToken();
    final query = _buildQueryParams(participantId: participantId, eventId: eventId);

    final response = await http.put(
      Uri.parse('$_baseUrl/my-visa$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to update visa application');
  }

  /// Submit a specific visa application by ID for review.
  Future<Map<String, dynamic>> submitMyVisaById(String visaId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/my-visa/$visaId/submit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to submit visa application');
  }

  /// Submit visa application for review (backward compat).
  Future<Map<String, dynamic>> submitMyVisa({
    String? participantId,
    int? eventId,
  }) async {
    final token = await _getToken();
    final query = _buildQueryParams(participantId: participantId, eventId: eventId);

    final response = await http.post(
      Uri.parse('$_baseUrl/my-visa/submit$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to submit visa application');
  }

  /// Validate visa application without submitting
  Future<Map<String, dynamic>> validateMyVisa({
    String? participantId,
    int? eventId,
  }) async {
    final token = await _getToken();
    final query = _buildQueryParams(participantId: participantId, eventId: eventId);

    final response = await http.get(
      Uri.parse('$_baseUrl/my-visa/validate$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? error['detail'] ?? 'Failed to validate visa application');
  }

  /// Upload visa photo to server
  Future<String> uploadPhoto({
    String? participantId,
    required dynamic photoData, // File for mobile, Uint8List for web
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/files/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = 'visa-photos';

    final filename = participantId != null
        ? 'photo_$participantId.jpg'
        : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Handle both File (mobile) and Uint8List (web)
    if (kIsWeb && photoData is Uint8List) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          photoData,
          filename: filename,
        ),
      );
    } else if (photoData is File) {
      request.files.add(
        await http.MultipartFile.fromPath('file', photoData.path),
      );
    } else {
      throw Exception('Invalid photo data type');
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData) as Map<String, dynamic>;
      return data['url'] as String;
    }

    throw Exception('Failed to upload photo: $responseData');
  }
}
