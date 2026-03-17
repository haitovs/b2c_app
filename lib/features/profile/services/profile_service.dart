import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/token_provider.dart';

/// Service for profile-related API operations (photo upload, password change).
///
/// Profile read/update is handled by [AuthNotifier.updateProfile] since it
/// also updates the cached auth state. This service covers operations that
/// are not part of the core auth flow.
class ProfileService {
  final ApiClient _api;
  final TokenProvider _tokenProvider;

  ProfileService(this._api, this._tokenProvider);

  /// Upload a profile photo.
  ///
  /// Returns the uploaded photo URL on success, or throws on failure.
  Future<String> uploadProfilePhoto(Uint8List imageBytes) async {
    final token = await _tokenProvider.getToken();
    if (token == null) throw Exception('Not authenticated');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/files/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename:
            'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final url = data['url'] ?? data['file_url'];
      if (url is String) return url;
      throw Exception('Upload succeeded but no URL returned');
    }

    // Safe error parsing
    String errorMsg = 'Photo upload failed (${response.statusCode})';
    try {
      if (responseBody.isNotEmpty) {
        final error = jsonDecode(responseBody);
        if (error is Map<String, dynamic>) {
          errorMsg = (error['message'] ?? error['detail'] ?? errorMsg) as String;
        }
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }

  /// Change the current user's password.
  ///
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _api.patch<Map<String, dynamic>>(
      '/api/v1/users/me/password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    if (result.isSuccess) return null;

    // Extract a user-friendly message from the error
    final msg = result.error?.message;
    if (msg != null && msg.isNotEmpty) return msg;
    return 'Failed to change password';
  }
}
