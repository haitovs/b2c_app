import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/token_provider.dart';

/// Service for handling visa application API operations
class VisaService {
  final ApiClient _api;
  final TokenProvider _tokenProvider;

  VisaService(this._api, this._tokenProvider);

  /// Build query parameters from optional participantId and eventId
  Map<String, String>? _buildQueryParams({String? participantId, int? eventId}) {
    final params = <String, String>{};
    if (participantId != null) params['participant_id'] = participantId;
    if (eventId != null) params['event_id'] = eventId.toString();
    return params.isNotEmpty ? params : null;
  }

  /// List all visa applications for the current user and event.
  Future<List<Map<String, dynamic>>> listMyVisas({int? eventId}) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/visas/my-visas',
      queryParams: _buildQueryParams(eventId: eventId),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    }
    throw result.error ?? Exception('Failed to list visa applications');
  }

  /// Create a new blank visa application.
  Future<Map<String, dynamic>> createMyVisa({int? eventId}) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/visas/my-visa/create',
      queryParams: _buildQueryParams(eventId: eventId),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to create visa application');
  }

  /// Get a specific visa application by ID.
  Future<Map<String, dynamic>> getMyVisaById(String visaId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/visas/my-visa/$visaId',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to load visa application');
  }

  /// Update a specific visa application by ID.
  Future<Map<String, dynamic>> updateMyVisaById({
    required String visaId,
    required Map<String, dynamic> data,
  }) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/visas/my-visa/$visaId',
      body: data,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to update visa application');
  }

  /// Submit a specific visa application by ID for review.
  Future<Map<String, dynamic>> submitMyVisaById(String visaId) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/visas/my-visa/$visaId/submit',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to submit visa application');
  }

  /// Delete a specific visa application by ID.
  Future<void> deleteMyVisaById(String visaId) async {
    final result = await _api.delete<Map<String, dynamic>>(
      '/api/v1/visas/my-visa/$visaId',
    );

    if (!result.isSuccess) {
      throw result.error ?? Exception('Failed to delete visa application');
    }
  }

  /// Get or create visa application for the current user (backward compat).
  Future<Map<String, dynamic>> getMyVisa({
    String? participantId,
    int? eventId,
  }) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/visas/my-visa',
      queryParams: _buildQueryParams(participantId: participantId, eventId: eventId),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to load visa application');
  }

  /// Update visa application with form data
  Future<Map<String, dynamic>> updateMyVisa({
    String? participantId,
    int? eventId,
    required Map<String, dynamic> data,
  }) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/visas/my-visa',
      queryParams: _buildQueryParams(participantId: participantId, eventId: eventId),
      body: data,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to update visa application');
  }

  /// Submit visa application for review
  Future<Map<String, dynamic>> submitMyVisa({
    String? participantId,
    int? eventId,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/visas/my-visa/submit',
      queryParams: _buildQueryParams(participantId: participantId, eventId: eventId),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to submit visa application');
  }

  /// Validate visa application without submitting
  Future<Map<String, dynamic>> validateMyVisa({
    String? participantId,
    int? eventId,
  }) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/visas/my-visa/validate',
      queryParams: _buildQueryParams(participantId: participantId, eventId: eventId),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to validate visa application');
  }

  /// Upload visa photo to server
  /// Returns photo URL on success
  Future<String> uploadPhoto({
    String? participantId,
    required dynamic photoData, // File for mobile, Uint8List for web
  }) async {
    final token = await _tokenProvider.getToken();
    if (token == null) throw Exception('Not authenticated');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/files/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = 'visa-photos';

    final filename = participantId != null
        ? 'photo_$participantId.jpg'
        : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb && photoData is Uint8List) {
      request.files.add(
        http.MultipartFile.fromBytes('file', photoData, filename: filename),
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
