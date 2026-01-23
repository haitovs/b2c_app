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

  /// Get or create visa application for participant
  /// Returns visa data including status, validation info, etc.
  Future<Map<String, dynamic>> getMyVisa(String participantId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/my-visa?participant_id=$participantId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to load visa application');
  }

  /// Update visa application with form data
  /// Can only be updated in FILL_OUT or DECLINED status
  Future<Map<String, dynamic>> updateMyVisa({
    required String participantId,
    required Map<String, dynamic> data,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$_baseUrl/my-visa?participant_id=$participantId'),
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
    throw Exception(error['detail'] ?? 'Failed to update visa application');
  }

  /// Submit visa application for review
  /// Validates completeness and changes status to PENDING
  Future<Map<String, dynamic>> submitMyVisa(String participantId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/my-visa/submit?participant_id=$participantId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to submit visa application');
  }

  /// Validate visa application without submitting
  /// Returns validation result with missing fields and warnings
  Future<Map<String, dynamic>> validateMyVisa(String participantId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/my-visa/validate?participant_id=$participantId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to validate visa application');
  }

  /// Upload visa photo to server
  /// Returns photo URL on success
  Future<String> uploadPhoto({
    required String participantId,
    required dynamic photoData, // File for mobile, Uint8List for web
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/files/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = 'visa-photos';

    // Handle both File (mobile) and Uint8List (web)
    if (kIsWeb && photoData is Uint8List) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          photoData,
          filename: 'photo_$participantId.jpg',
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
